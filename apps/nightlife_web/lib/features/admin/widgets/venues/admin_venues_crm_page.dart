import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/breakpoints.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/components/drinkspot_button.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../auth/services/auth_service.dart';
import '../../../venue_management/widgets/page/venue_dashboard_page_widgets.dart';
import '../../../venue_management/widgets/venue_dashboard_layout.dart';
import '../../data/admin_dashboard_repository.dart';
import '../../models/admin_dashboard_models.dart';
import '../../models/admin_venue_crm.dart';
import '../shared/admin_crm_sortable_header.dart';
import '../../permissions/admin_permission_constants.dart';
import '../../permissions/permission_service.dart';

/// Admin Venues CRM — table, filters, profile modal, and venue management actions.
class AdminVenuesCrmPage extends StatefulWidget {
  const AdminVenuesCrmPage({
    super.key,
    required this.repository,
    required this.permissions,
    this.onNavigateToAdminMap,
    this.onNavigateToUsers,
    this.onNavigateToSubscriptions,
  });

  final AdminDashboardRepository repository;
  final PermissionService permissions;
  final void Function(String venueId)? onNavigateToAdminMap;
  final VoidCallback? onNavigateToUsers;
  final VoidCallback? onNavigateToSubscriptions;

  @override
  State<AdminVenuesCrmPage> createState() => _AdminVenuesCrmPageState();
}

class _AdminVenuesCrmPageState extends State<AdminVenuesCrmPage> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  String _claimFilter = 'All';
  String _categoryFilter = 'All';
  String _cityFilter = 'All';
  String _subscriptionFilter = 'All';
  String _sortColumn = AdminVenueTableSortColumn.defaultColumn;
  bool _sortAscending = AdminVenueTableSortColumn.defaultAscending;
  int _pageIndex = 0;
  int _pageSize = kAdminVenuesCrmPageSizeOptions.first;
  final Set<String> _selectedVenueIds = {};
  AdminDocumentRow? _profileModalVenue;
  bool _actionLoading = false;
  bool _isEditVenueDialogOpen = false;
  bool _isConfirmDialogOpen = false;
  List<AdminDocumentRow>? _cachedRows;
  OverlayEntry? _profileOverlayEntry;
  OverlayEntry? _dialogOverlayEntry;

  AdminVenueCrmPermissions get _crmPermissions =>
      AdminVenueCrmPermissions(widget.permissions);

  double _venuesCrmPageBodyHeight(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final viewPadding = MediaQuery.paddingOf(context);
    final scrollPadding =
        (Breakpoints.isDesktop(context) ? AppSpacing.xl : AppSpacing.lg) * 2;
    const pageHeaderBlock = 100.0 + AppSpacing.xl;

    return (media.height -
            VenueDashboardLayout.topBarHeight -
            scrollPadding -
            viewPadding.vertical -
            pageHeaderBlock)
        .clamp(420.0, media.height);
  }

  bool get _hasActiveFilters =>
      _search.trim().isNotEmpty ||
      _claimFilter != 'All' ||
      _categoryFilter != 'All' ||
      _cityFilter != 'All' ||
      _subscriptionFilter != 'All';

  void _clearFilters() {
    setState(() {
      _search = '';
      _searchController.clear();
      _claimFilter = 'All';
      _categoryFilter = 'All';
      _cityFilter = 'All';
      _subscriptionFilter = 'All';
      _pageIndex = 0;
    });
  }

  void _toggleVenueSelection(String venueId, bool selected) {
    setState(() {
      if (selected) {
        _selectedVenueIds.add(venueId);
      } else {
        _selectedVenueIds.remove(venueId);
      }
    });
  }

  void _toggleSelectAllVisible(List<AdminVenueCrmView> visibleVenues) {
    final visibleIds = visibleVenues.map((venue) => venue.venueId).toSet();
    final allSelected =
        visibleIds.isNotEmpty && visibleIds.every(_selectedVenueIds.contains);

    setState(() {
      if (allSelected) {
        _selectedVenueIds.removeAll(visibleIds);
      } else {
        _selectedVenueIds.addAll(visibleIds);
      }
    });
  }

  List<String> get selectedVenueIds =>
      _selectedVenueIds.toList(growable: false);

  void _handleVenueColumnSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _removeDialogOverlay();
    _removeProfileOverlay();
    super.dispose();
  }

  void _removeDialogOverlay() {
    _dialogOverlayEntry?.remove();
    _dialogOverlayEntry?.dispose();
    _dialogOverlayEntry = null;
  }

  /// Shows a dialog above the profile modal overlay (not behind it).
  Future<T?> _showAboveProfileOverlay<T>({
    required Widget Function(
      BuildContext context,
      void Function([T? result]) finish,
    )
    builder,
    bool barrierDismissible = true,
  }) async {
    _removeDialogOverlay();

    final overlayState = Overlay.of(context, rootOverlay: true);
    final completer = Completer<T?>();

    void finish([T? result]) {
      if (!completer.isCompleted) {
        completer.complete(result);
      }
      _removeDialogOverlay();
    }

    _dialogOverlayEntry = OverlayEntry(
      builder: (dialogContext) {
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: barrierDismissible ? () => finish() : null,
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.58)),
              ),
              Center(child: builder(dialogContext, finish)),
            ],
          ),
        );
      },
    );

    overlayState.insert(_dialogOverlayEntry!);

    try {
      return await completer.future;
    } finally {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
      _removeDialogOverlay();
    }
  }

  void _removeProfileOverlay() {
    _profileOverlayEntry?.remove();
    _profileOverlayEntry?.dispose();
    _profileOverlayEntry = null;
  }

  AdminDocumentRow? _currentModalVenueRow() {
    if (_profileModalVenue == null) return null;
    final cached = _cachedRows;
    if (cached != null) {
      for (final row in cached) {
        if (row.id == _profileModalVenue!.id) return row;
      }
    }
    return _profileModalVenue;
  }

  void _showProfileOverlay() {
    _removeProfileOverlay();
    if (!mounted || _profileModalVenue == null) return;

    _profileOverlayEntry = OverlayEntry(
      builder: (overlayContext) {
        final venue = _currentModalVenueRow();
        if (venue == null) return const SizedBox.shrink();

        return _VenuesCrmProfileModalOverlay(
          key: ValueKey(venue.id),
          venue: venue,
          repository: widget.repository,
          permissions: _crmPermissions,
          actionLoading: _actionLoading,
          editDialogOpen: _isEditVenueDialogOpen,
          confirmDialogOpen: _isConfirmDialogOpen,
          onClose: _closeProfileModal,
          onEdit: () => _openEditDialog(venue),
          onVisibilityToggle: () => _toggleVenueVisibility(venue),
          onVerifyToggle: () => _toggleVerify(venue),
          onDelete: () => _deleteVenue(venue),
          onOpenPublic: () => _openPublicVenue(venue),
          onOpenMap: () => _openOnMap(venue),
          onOpenOwnerProfile: (uid, email) =>
              _openOwnerProfile(uid: uid, ownerEmail: email),
          onViewSubscription: _viewSubscription,
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(_profileOverlayEntry!);
  }

  void _refreshProfileOverlay() {
    if (_profileModalVenue == null) {
      _removeProfileOverlay();
      return;
    }
    if (_profileOverlayEntry == null) {
      _showProfileOverlay();
      return;
    }
    _profileOverlayEntry!.markNeedsBuild();
  }

  Widget _buildPageStack(
    BuildContext context, {
    required Widget body,
    required bool modalOpen,
  }) {
    return SizedBox(
      height: _venuesCrmPageBodyHeight(context),
      width: double.infinity,
      child: SingleChildScrollView(
        physics: modalOpen
            ? const NeverScrollableScrollPhysics()
            : const ClampingScrollPhysics(),
        child: body,
      ),
    );
  }

  Map<String, AdminVenueHealth> _buildHealthMap(
    List<AdminVenueCrmView> venues,
  ) {
    return {
      for (final venue in venues) venue.venueId: estimateTableHealth(venue),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (!_crmPermissions.canViewProfile()) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<AdminDocumentRow>>(
      stream: widget.repository.watchCollection('venues', limit: 250),
      builder: (context, snapshot) {
        if (snapshot.hasError && !snapshot.hasData) {
          return _buildPageStack(
            context,
            modalOpen: _profileModalVenue != null,
            body: _VenuesCrmErrorCard(
              collectionPath: 'venues',
              error: snapshot.error,
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData &&
            _cachedRows == null) {
          return _buildPageStack(
            context,
            modalOpen: _profileModalVenue != null,
            body: const _VenuesCrmLoadingPanel(),
          );
        }

        if (snapshot.hasData) {
          _cachedRows = snapshot.data;
        }

        final sourceRows = snapshot.data ?? _cachedRows ?? const [];
        final healthByVenueId = _buildHealthMap(
          sourceRows.map((row) => AdminVenueCrmView(row: row)).toList(),
        );

        final venues = filterAndSortVenues(
          rows: sourceRows,
          search: _search,
          claimFilter: _claimFilter,
          categoryFilter: _categoryFilter,
          cityFilter: _cityFilter,
          subscriptionFilter: _subscriptionFilter,
          sortColumn: _sortColumn,
          sortAscending: _sortAscending,
          healthByVenueId: healthByVenueId,
        );

        final totalPages = venues.isEmpty
            ? 1
            : ((venues.length - 1) ~/ _pageSize) + 1;
        final pageIndex = _pageIndex.clamp(0, totalPages - 1);
        final visibleVenues = venues
            .skip(pageIndex * _pageSize)
            .take(_pageSize)
            .toList();

        final categoryOptions = [
          'All',
          ...collectVenueCategories(sourceRows).toList()..sort(),
        ];
        final cityOptions = [
          'All',
          ...collectVenueCities(sourceRows).toList()..sort(),
        ];
        final subscriptionOptions = [
          'All',
          ...collectVenueSubscriptionPlans(sourceRows).toList()..sort(),
        ];

        final visibleIds = visibleVenues.map((venue) => venue.venueId).toSet();
        final allVisibleSelected =
            visibleIds.isNotEmpty &&
            visibleIds.every(_selectedVenueIds.contains);
        final someVisibleSelected =
            visibleIds.any(_selectedVenueIds.contains) && !allVisibleSelected;

        final tableSection = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _VenuesCrmToolbar(
              searchController: _searchController,
              claimFilter: _claimFilter,
              categoryFilter: _categoryFilter,
              cityFilter: _cityFilter,
              subscriptionFilter: _subscriptionFilter,
              categoryOptions: categoryOptions,
              cityOptions: cityOptions,
              subscriptionOptions: subscriptionOptions,
              hasActiveFilters: _hasActiveFilters,
              onSearchChanged: (value) => setState(() {
                _search = value;
                _pageIndex = 0;
              }),
              onClaimChanged: (value) => setState(() {
                _claimFilter = value;
                _pageIndex = 0;
              }),
              onCategoryChanged: (value) => setState(() {
                _categoryFilter = value;
                _pageIndex = 0;
              }),
              onCityChanged: (value) => setState(() {
                _cityFilter = value;
                _pageIndex = 0;
              }),
              onSubscriptionChanged: (value) => setState(() {
                _subscriptionFilter = value;
                _pageIndex = 0;
              }),
              onClearFilters: _clearFilters,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_selectedVenueIds.isNotEmpty) ...[
              _VenuesCrmSelectionBanner(
                count: _selectedVenueIds.length,
                onClear: () => setState(_selectedVenueIds.clear),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (snapshot.hasError && snapshot.hasData)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _VenuesCrmInlineErrorBanner(error: snapshot.error),
              ),
            _VenuesCrmTable(
              venues: visibleVenues,
              totalFilteredCount: venues.length,
              healthByVenueId: healthByVenueId,
              selectedIds: _selectedVenueIds,
              allVisibleSelected: allVisibleSelected,
              someVisibleSelected: someVisibleSelected,
              sortColumn: _sortColumn,
              sortAscending: _sortAscending,
              permissions: _crmPermissions,
              onColumnSort: _handleVenueColumnSort,
              onSelectedChanged: _toggleVenueSelection,
              onToggleSelectAllVisible: () =>
                  _toggleSelectAllVisible(visibleVenues),
              onAction: _handleAction,
            ),
            const SizedBox(height: AppSpacing.lg),
            _VenuesCrmPaginationBar(
              pageIndex: pageIndex,
              totalPages: totalPages,
              visibleCount: visibleVenues.length,
              totalCount: venues.length,
              pageSize: _pageSize,
              onPageSizeChanged: (value) => setState(() {
                _pageSize = value;
                _pageIndex = 0;
              }),
              onPrevious: pageIndex == 0
                  ? null
                  : () => setState(() => _pageIndex = pageIndex - 1),
              onNext: pageIndex >= totalPages - 1
                  ? null
                  : () => setState(() => _pageIndex = pageIndex + 1),
            ),
          ],
        );

        final modalOpen = _profileModalVenue != null;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _refreshProfileOverlay();
        });

        return _buildPageStack(
          context,
          modalOpen: modalOpen,
          body: tableSection,
        );
      },
    );
  }

  Future<void> _handleAction(
    AdminDocumentRow row,
    AdminVenueCrmAction action,
  ) async {
    setState(() => _selectedVenueIds.add(row.id));

    switch (action) {
      case AdminVenueCrmAction.viewProfile:
        _openProfileModal(row);
        return;
      case AdminVenueCrmAction.editVenue:
        await _openEditDialog(row);
        return;
      case AdminVenueCrmAction.verify:
      case AdminVenueCrmAction.unverify:
        await _toggleVerify(row);
        return;
      case AdminVenueCrmAction.openPublicVenue:
        _openPublicVenue(row);
        return;
      case AdminVenueCrmAction.openOnMap:
        _openOnMap(row);
        return;
      case AdminVenueCrmAction.hideVenue:
      case AdminVenueCrmAction.showVenue:
        await _toggleVenueVisibility(row);
        return;
      case AdminVenueCrmAction.suspend:
      case AdminVenueCrmAction.unsuspend:
        await _toggleSuspend(row);
        return;
      case AdminVenueCrmAction.deleteVenue:
        await _deleteVenue(row);
        return;
    }
  }

  void _afterVenueMutation(String venueId) {
    _VenuesCrmProfileModalBodyState.invalidateSupplementaryCache(venueId);
    _refreshProfileOverlay();
  }

  Future<void> _openEditDialog(AdminDocumentRow row) async {
    if (!_crmPermissions.canEditVenue()) return;
    if (_isEditVenueDialogOpen || _isConfirmDialogOpen) return;

    setState(() => _isEditVenueDialogOpen = true);
    _refreshProfileOverlay();

    try {
      final saved = await _showAboveProfileOverlay<bool>(
        builder: (dialogContext, finish) => _VenueEditDialog(
          venue: AdminVenueCrmView(row: row),
          repository: widget.repository,
          onFinished: finish,
        ),
      );
      if (saved != true || !mounted) return;

      _afterVenueMutation(row.id);
      _showSnack(context, 'Venue updated.');
    } finally {
      if (mounted) {
        setState(() => _isEditVenueDialogOpen = false);
        _refreshProfileOverlay();
      }
    }
  }

  Future<bool> _confirmVenueAction({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    if (_isConfirmDialogOpen || _isEditVenueDialogOpen) return false;

    setState(() => _isConfirmDialogOpen = true);
    _refreshProfileOverlay();

    try {
      return await _showAboveProfileOverlay<bool>(
            builder: (dialogContext, finish) => AlertDialog(
              backgroundColor: AppColors.surfaceElevated,
              title: Text(title),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => finish(false),
                  child: const Text('Cancel'),
                ),
                DrinkSpotButton(
                  label: confirmLabel,
                  compact: true,
                  onPressed: () => finish(true),
                ),
              ],
            ),
          ) ??
          false;
    } finally {
      if (mounted) {
        setState(() => _isConfirmDialogOpen = false);
        _refreshProfileOverlay();
      }
    }
  }

  Future<void> _toggleSuspend(AdminDocumentRow row) async {
    if (!_crmPermissions.canSuspend()) return;

    final venue = AdminVenueCrmView(row: row);
    final suspending = !venue.isSuspended;

    final confirmed = await _confirmVenueAction(
      title: suspending ? 'Suspend Venue' : 'Unsuspend Venue',
      message: suspending
          ? 'This will suspend ${venue.name} and hide it from public listings.'
          : 'This will restore ${venue.name} to active status.',
      confirmLabel: suspending ? 'Suspend' : 'Unsuspend',
    );
    if (!confirmed || !mounted) return;

    final actorUid = AuthService.currentUser?.uid ?? 'unknown';
    setState(() => _actionLoading = true);
    try {
      if (suspending) {
        await widget.repository.suspendVenue(
          venueId: row.id,
          suspendedBy: actorUid,
        );
      } else {
        await widget.repository.unsuspendVenue(
          venueId: row.id,
          unsuspendedBy: actorUid,
        );
      }
      if (!mounted) return;
      _afterVenueMutation(row.id);
      _showSnack(
        context,
        suspending ? 'Venue suspended.' : 'Venue unsuspended.',
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      _showSnack(context, 'Action failed: ${error.message ?? error.code}');
    } on Object catch (error) {
      if (!mounted) return;
      _showSnack(context, 'Action failed: $error');
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _toggleVerify(AdminDocumentRow row) async {
    if (!_crmPermissions.canVerify()) return;

    final venue = AdminVenueCrmView(row: row);
    final verifying = !venue.isVerified;

    final confirmed = await _confirmVenueAction(
      title: verifying ? 'Verify Venue' : 'Unverify Venue',
      message: verifying
          ? 'Mark ${venue.name} as verified?'
          : 'Remove verified status from ${venue.name}?',
      confirmLabel: verifying ? 'Verify' : 'Unverify',
    );
    if (!confirmed || !mounted) return;

    final actorUid = AuthService.currentUser?.uid ?? 'unknown';
    setState(() => _actionLoading = true);
    try {
      await widget.repository.setVenueVerified(
        venueId: row.id,
        verified: verifying,
        updatedBy: actorUid,
      );
      if (!mounted) return;
      _afterVenueMutation(row.id);
      _showSnack(
        context,
        verifying ? 'Venue verified.' : 'Verification removed.',
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      _showSnack(context, 'Action failed: ${error.message ?? error.code}');
    } on Object catch (error) {
      if (!mounted) return;
      _showSnack(context, 'Action failed: $error');
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _toggleVenueVisibility(AdminDocumentRow row) async {
    if (!_crmPermissions.canHideVenue()) return;

    final venue = AdminVenueCrmView(row: row);
    final hiding = venue.isVisible;

    final confirmed = await _confirmVenueAction(
      title: hiding ? 'Hide Venue' : 'Publish Venue',
      message: hiding
          ? '${venue.name} will be hidden from public listings but remain in the admin venues database.'
          : '${venue.name} will be published and visible to the public again.',
      confirmLabel: hiding ? 'Hide venue' : 'Publish venue',
    );
    if (!confirmed || !mounted) return;

    final actorUid = AuthService.currentUser?.uid ?? 'unknown';
    setState(() => _actionLoading = true);
    try {
      if (hiding) {
        await widget.repository.hideVenueFromPublic(
          venueId: row.id,
          hiddenBy: actorUid,
        );
      } else {
        await widget.repository.publishVenueToPublic(
          venueId: row.id,
          publishedBy: actorUid,
        );
      }
      if (!mounted) return;
      _afterVenueMutation(row.id);
      _showSnack(
        context,
        hiding ? 'Venue hidden from public.' : 'Venue published publicly.',
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      _showSnack(context, 'Action failed: ${error.message ?? error.code}');
    } on Object catch (error) {
      if (!mounted) return;
      _showSnack(context, 'Action failed: $error');
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _deleteVenue(AdminDocumentRow row) async {
    if (!_crmPermissions.canDelete()) return;
    if (_isConfirmDialogOpen || _isEditVenueDialogOpen) return;

    final venue = AdminVenueCrmView(row: row);

    setState(() => _isConfirmDialogOpen = true);
    _refreshProfileOverlay();

    try {
      final result =
          await _showAboveProfileOverlay<({bool confirmed, String? reason})>(
            builder: (dialogContext, finish) =>
                _VenueDeleteDialog(venueName: venue.name, onFinished: finish),
          );

      if (result?.confirmed != true || !mounted) return;

      final actorUid = AuthService.currentUser?.uid ?? 'unknown';
      setState(() => _actionLoading = true);
      try {
        await widget.repository.archiveAndRemoveVenue(
          venueId: row.id,
          deletedBy: actorUid,
          deleteReason: result?.reason,
        );
        if (!mounted) return;

        _selectedVenueIds.remove(row.id);
        if (_profileModalVenue?.id == row.id) {
          _closeProfileModal();
        } else {
          _afterVenueMutation(row.id);
        }
        _showSnack(
          context,
          '${venue.name} archived and removed from active venues.',
        );
      } on FirebaseException catch (error) {
        if (!mounted) return;
        _showSnack(context, 'Delete failed: ${error.message ?? error.code}');
      } on Object catch (error) {
        if (!mounted) return;
        _showSnack(context, 'Delete failed: $error');
      } finally {
        if (mounted) setState(() => _actionLoading = false);
      }
    } finally {
      if (mounted) {
        setState(() => _isConfirmDialogOpen = false);
        _refreshProfileOverlay();
      }
    }
  }

  void _openPublicVenue(AdminDocumentRow row) {
    if (!_crmPermissions.canViewProfile()) return;
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed(AppRouter.venueDetails(row.id));
  }

  void _openOnMap(AdminDocumentRow row) {
    if (!_crmPermissions.canOpenMap()) return;
    _closeProfileModal();
    if (widget.onNavigateToAdminMap != null) {
      widget.onNavigateToAdminMap!(row.id);
      return;
    }
    _showSnack(context, 'Map focus will be added in a later pass.');
  }

  void _openOwnerProfile({required String uid, String? ownerEmail}) {
    if (uid.isEmpty || uid == '—') return;
    _closeProfileModal();
    if (widget.onNavigateToUsers != null) {
      widget.onNavigateToUsers!();
      _showSnack(
        context,
        ownerEmail != null && ownerEmail != '—'
            ? 'Opened Users — find $ownerEmail'
            : 'Opened Users — find owner $uid',
      );
      return;
    }
    // TODO(users-crm): Deep-link to Users CRM profile modal when supported.
    _showSnack(context, 'User profile route not available yet.');
  }

  void _viewSubscription() {
    _closeProfileModal();
    if (widget.onNavigateToSubscriptions != null) {
      widget.onNavigateToSubscriptions!();
      // TODO(subscriptions): Open owner subscription detail when page is wired.
      _showSnack(
        context,
        'Subscription detail view will be added in a later pass.',
      );
      return;
    }
    _showSnack(context, 'Subscription page not available yet.');
  }

  void _openProfileModal(AdminDocumentRow row) {
    setState(() {
      _selectedVenueIds.add(row.id);
      _profileModalVenue = row;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _profileModalVenue == null) return;
      _showProfileOverlay();
    });
  }

  void _closeProfileModal() {
    _removeProfileOverlay();
    if (mounted) {
      setState(() => _profileModalVenue = null);
    }
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _VenuesCrmToolbar extends StatelessWidget {
  const _VenuesCrmToolbar({
    required this.searchController,
    required this.claimFilter,
    required this.categoryFilter,
    required this.cityFilter,
    required this.subscriptionFilter,
    required this.categoryOptions,
    required this.cityOptions,
    required this.subscriptionOptions,
    required this.hasActiveFilters,
    required this.onSearchChanged,
    required this.onClaimChanged,
    required this.onCategoryChanged,
    required this.onCityChanged,
    required this.onSubscriptionChanged,
    required this.onClearFilters,
  });

  final TextEditingController searchController;
  final String claimFilter;
  final String categoryFilter;
  final String cityFilter;
  final String subscriptionFilter;
  final List<String> categoryOptions;
  final List<String> cityOptions;
  final List<String> subscriptionOptions;
  final bool hasActiveFilters;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onClaimChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onCityChanged;
  final ValueChanged<String> onSubscriptionChanged;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return VenuePageSection(
      title: 'Search, Filters & Sort',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          const spacing = AppSpacing.md;
          const minFieldWidth = 148.0;
          const maxFieldWidth = 196.0;

          final filterCount = 4;
          final fieldsPerRow = available >= 960
              ? filterCount + 2
              : available >= 720
              ? 3
              : available >= 480
              ? 2
              : 1;
          final fieldWidth =
              ((available - spacing * (fieldsPerRow - 1)) / fieldsPerRow).clamp(
                minFieldWidth,
                maxFieldWidth,
              );
          final searchWidth = available >= 720
              ? fieldWidth.clamp(220.0, 360.0)
              : available;

          Widget filterField(Widget child) {
            return SizedBox(
              width: fieldWidth,
              height: _VenuesCrmToolbarMetrics.controlHeight,
              child: child,
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: spacing,
                runSpacing: spacing,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    height: _VenuesCrmToolbarMetrics.controlHeight,
                    width: searchWidth,
                    child: TextField(
                      controller: searchController,
                      onChanged: onSearchChanged,
                      style: _VenuesCrmToolbarMetrics.fieldTextStyle,
                      strutStyle: const StrutStyle(
                        fontSize: 13,
                        height: 1.15,
                        forceStrutHeight: true,
                      ),
                      decoration: _VenuesCrmToolbarMetrics.searchDecoration(),
                    ),
                  ),
                  filterField(
                    _VenuesCrmDropdown(
                      label: 'Category',
                      compact: true,
                      value: categoryFilter,
                      values: categoryOptions,
                      onChanged: onCategoryChanged,
                    ),
                  ),
                  filterField(
                    _VenuesCrmDropdown(
                      label: 'City',
                      compact: true,
                      value: cityFilter,
                      values: cityOptions,
                      onChanged: onCityChanged,
                    ),
                  ),
                  filterField(
                    _VenuesCrmDropdown(
                      label: 'Claim Status',
                      compact: true,
                      value: claimFilter,
                      values: const ['All', 'Claimed', 'Unclaimed'],
                      onChanged: onClaimChanged,
                    ),
                  ),
                  filterField(
                    _VenuesCrmDropdown(
                      label: 'Subscription',
                      compact: true,
                      value: subscriptionFilter,
                      values: subscriptionOptions,
                      onChanged: onSubscriptionChanged,
                    ),
                  ),
                  if (hasActiveFilters)
                    SizedBox(
                      height: _VenuesCrmToolbarMetrics.controlHeight,
                      child: DrinkSpotButton(
                        label: 'Clear filters',
                        compact: true,
                        variant: DrinkSpotButtonVariant.ghost,
                        onPressed: onClearFilters,
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

abstract final class _VenuesCrmToolbarMetrics {
  static const controlHeight = 48.0;
  static const borderRadius = AppSpacing.radiusSm;

  static const fieldTextStyle = TextStyle(
    color: AppColors.white,
    fontSize: 13,
    height: 1.15,
    fontWeight: FontWeight.w500,
  );

  static const hintTextStyle = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 13,
    height: 1.15,
    fontWeight: FontWeight.w400,
  );

  static const labelTextStyle = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 11,
    height: 1.1,
    fontWeight: FontWeight.w600,
  );

  static OutlineInputBorder outlineBorder({Color? borderColor}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(
        color: borderColor ?? AppColors.primaryPurple.withValues(alpha: 0.18),
      ),
    );
  }

  static InputDecoration searchDecoration() {
    return InputDecoration(
      isDense: true,
      isCollapsed: false,
      hintText: 'Search name, city, owner or ID',
      hintStyle: hintTextStyle,
      prefixIcon: Icon(
        Icons.search_rounded,
        size: 18,
        color: AppColors.textSecondary.withValues(alpha: 0.9),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      filled: true,
      fillColor: AppColors.surfaceElevated.withValues(alpha: 0.78),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      border: outlineBorder(),
      enabledBorder: outlineBorder(),
      focusedBorder: outlineBorder(
        borderColor: AppColors.primaryPurple.withValues(alpha: 0.42),
      ),
    );
  }

  static InputDecoration dropdownDecoration({required String label}) {
    return InputDecoration(
      labelText: label,
      labelStyle: labelTextStyle,
      floatingLabelStyle: labelTextStyle,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      isDense: true,
      filled: true,
      fillColor: AppColors.surfaceElevated.withValues(alpha: 0.78),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      border: outlineBorder(),
      enabledBorder: outlineBorder(),
      focusedBorder: outlineBorder(
        borderColor: AppColors.primaryPurple.withValues(alpha: 0.42),
      ),
    );
  }
}

class _VenuesCrmTable extends StatelessWidget {
  const _VenuesCrmTable({
    required this.venues,
    required this.totalFilteredCount,
    required this.healthByVenueId,
    required this.selectedIds,
    required this.allVisibleSelected,
    required this.someVisibleSelected,
    required this.sortColumn,
    required this.sortAscending,
    required this.permissions,
    required this.onColumnSort,
    required this.onSelectedChanged,
    required this.onToggleSelectAllVisible,
    required this.onAction,
  });

  final List<AdminVenueCrmView> venues;
  final int totalFilteredCount;
  final Map<String, AdminVenueHealth> healthByVenueId;
  final Set<String> selectedIds;
  final bool allVisibleSelected;
  final bool someVisibleSelected;
  final String sortColumn;
  final bool sortAscending;
  final AdminVenueCrmPermissions permissions;
  final ValueChanged<String> onColumnSort;
  final void Function(String venueId, bool selected) onSelectedChanged;
  final VoidCallback onToggleSelectAllVisible;
  final void Function(AdminDocumentRow row, AdminVenueCrmAction action)
  onAction;

  DataColumn _sortableColumn(String label, String columnKey) {
    return adminCrmSortableDataColumn(
      label: label,
      columnKey: columnKey,
      activeColumnKey: sortColumn,
      ascending: sortAscending,
      onSort: onColumnSort,
    );
  }

  String _ownerLabel(AdminVenueCrmView venue) {
    if (venue.ownerName.isNotEmpty && venue.ownerName != '—') {
      return venue.ownerName;
    }
    if (venue.ownerId.isNotEmpty && venue.ownerId != '—') {
      return venue.ownerId.length > 12
          ? '${venue.ownerId.substring(0, 12)}…'
          : venue.ownerId;
    }
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    if (venues.isEmpty) {
      return const VenuePageSection(
        title: 'No venues found',
        child: Text(
          'No venue records match the current search and filters.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return VenuePageSection(
      title: 'Venue Management',
      trailing: Text(
        '$totalFilteredCount total · ${venues.length} on this page',
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: false,
          headingTextStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
          dataTextStyle: const TextStyle(
            color: AppColors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          headingRowColor: WidgetStateProperty.all(
            AppColors.primaryPurple.withValues(alpha: 0.06),
          ),
          dataRowColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primaryPurple.withValues(alpha: 0.14);
            }
            return null;
          }),
          columns: [
            DataColumn(
              label: SizedBox(
                width: 36,
                child: Checkbox(
                  tristate: true,
                  value: allVisibleSelected
                      ? true
                      : someVisibleSelected
                      ? null
                      : false,
                  onChanged: (_) => onToggleSelectAllVisible(),
                  visualDensity: VisualDensity.compact,
                  activeColor: AppColors.primaryPurple,
                  side: BorderSide(
                    color: AppColors.primaryPurple.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
            _sortableColumn('Venue Name', AdminVenueTableSortColumn.name),
            _sortableColumn('Category', AdminVenueTableSortColumn.category),
            _sortableColumn('City', AdminVenueTableSortColumn.city),
            _sortableColumn('Owner', AdminVenueTableSortColumn.owner),
            _sortableColumn('Photos', AdminVenueTableSortColumn.photos),
            _sortableColumn('Plan', AdminVenueTableSortColumn.plan),
            _sortableColumn(
              'Claim Status',
              AdminVenueTableSortColumn.claimStatus,
            ),
            _sortableColumn('Verified', AdminVenueTableSortColumn.verified),
            _sortableColumn('Visibility', AdminVenueTableSortColumn.visibility),
            _sortableColumn(
              'Health Score',
              AdminVenueTableSortColumn.healthScore,
            ),
            _sortableColumn('Updated', AdminVenueTableSortColumn.updated),
            const DataColumn(label: Text('Actions')),
          ],
          rows: venues.map((venue) {
            final health =
                healthByVenueId[venue.venueId] ?? estimateTableHealth(venue);
            final isSelected = selectedIds.contains(venue.venueId);
            return DataRow(
              selected: isSelected,
              cells: [
                DataCell(
                  Checkbox(
                    value: isSelected,
                    onChanged: (selected) {
                      onSelectedChanged(venue.venueId, selected == true);
                    },
                    visualDensity: VisualDensity.compact,
                    activeColor: AppColors.primaryPurple,
                    side: BorderSide(
                      color: AppColors.primaryPurple.withValues(alpha: 0.45),
                    ),
                  ),
                ),
                DataCell(Text(venue.name)),
                DataCell(Text(venue.category)),
                DataCell(Text(venue.city)),
                DataCell(Text(_ownerLabel(venue))),
                DataCell(_VenuesCrmPhotosCell(label: venue.photosUsedLabel)),
                DataCell(
                  _VenuesCrmSubscriptionChip(
                    label: venue.subscriptionPlanPillLabel,
                    premium: venue.subscriptionPlanIsPremium,
                  ),
                ),
                DataCell(_VenuesCrmClaimChip(label: venue.claimedLabel)),
                DataCell(_VenuesCrmVerifiedChip(verified: venue.isVerified)),
                DataCell(_VenuesCrmVisibilityChip(visible: venue.isVisible)),
                DataCell(_VenuesCrmHealthChip(health: health)),
                DataCell(Text(venue.updatedAt)),
                DataCell(
                  _VenuesCrmInlineActions(
                    venue: venue,
                    permissions: permissions,
                    onAction: (action) => onAction(venue.row, action),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _VenuesCrmPhotosCell extends StatelessWidget {
  const _VenuesCrmPhotosCell({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.photo_library_outlined,
          size: 15,
          color: AppColors.textSecondary.withValues(alpha: 0.9),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _VenuesCrmSelectionBanner extends StatelessWidget {
  const _VenuesCrmSelectionBanner({required this.count, required this.onClear});

  final int count;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      borderRadius: AppSpacing.radiusLg,
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 18,
            color: AppColors.primaryPurple.withValues(alpha: 0.9),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '$count venue${count == 1 ? '' : 's'} selected',
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(onPressed: onClear, child: const Text('Clear selection')),
        ],
      ),
    );
  }
}

class _VenuesCrmInlineActions extends StatelessWidget {
  const _VenuesCrmInlineActions({
    required this.venue,
    required this.permissions,
    required this.onAction,
  });

  final AdminVenueCrmView venue;
  final AdminVenueCrmPermissions permissions;
  final ValueChanged<AdminVenueCrmAction> onAction;

  @override
  Widget build(BuildContext context) {
    final actions =
        <
          ({
            AdminVenueCrmAction action,
            IconData icon,
            String label,
            bool backendTodo,
          })
        >[
          (
            action: AdminVenueCrmAction.viewProfile,
            icon: Icons.storefront_outlined,
            label: 'View / Manage venue',
            backendTodo: false,
          ),
          (
            action: AdminVenueCrmAction.editVenue,
            icon: Icons.edit_rounded,
            label: 'Edit venue',
            backendTodo: false,
          ),
          (
            action: venue.isVerified
                ? AdminVenueCrmAction.unverify
                : AdminVenueCrmAction.verify,
            icon: venue.isVerified
                ? Icons.verified_outlined
                : Icons.verified_rounded,
            label: venue.isVerified ? 'Unverify venue' : 'Verify venue',
            backendTodo: false,
          ),
          (
            action: venue.isVisible
                ? AdminVenueCrmAction.hideVenue
                : AdminVenueCrmAction.showVenue,
            icon: venue.isVisible
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            label: venue.isVisible
                ? 'Hide venue from public'
                : 'Publish venue / Show publicly',
            backendTodo: false,
          ),
          (
            action: AdminVenueCrmAction.openOnMap,
            icon: Icons.map_outlined,
            label: 'View on map',
            backendTodo: false,
          ),
          (
            action: AdminVenueCrmAction.deleteVenue,
            icon: Icons.delete_forever_rounded,
            label: 'Delete venue (archives to deleted_venues)',
            backendTodo: false,
          ),
        ];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              _VenuesCrmInlineActionIcon(
                action: actions[i].action,
                icon: actions[i].icon,
                label: actions[i].label,
                backendTodo: actions[i].backendTodo,
                permissions: permissions,
                onPressed: () => onAction(actions[i].action),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VenuesCrmInlineActionIcon extends StatelessWidget {
  const _VenuesCrmInlineActionIcon({
    required this.action,
    required this.icon,
    required this.label,
    required this.backendTodo,
    required this.permissions,
    required this.onPressed,
  });

  final AdminVenueCrmAction action;
  final IconData icon;
  final String label;
  final bool backendTodo;
  final AdminVenueCrmPermissions permissions;
  final VoidCallback onPressed;

  String get _tooltip {
    if (backendTodo) return kAdminVenueBackendRequiredTooltip;
    if (!permissions.isActionAllowed(action)) {
      return permissions.menuSubtitleFor(action, backendTodo: false) ??
          kAdminPermissionDeniedTooltip;
    }
    return permissions.tooltipFor(action, isBackendTodo: false);
  }

  @override
  Widget build(BuildContext context) {
    final allowed = permissions.isActionAllowed(action);
    final enabled = allowed && !backendTodo;

    return Tooltip(
      message: _tooltip,
      waitDuration: const Duration(milliseconds: 350),
      child: IconButton(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        tooltip: '',
        icon: Icon(
          icon,
          size: 18,
          color: enabled
              ? AppColors.white.withValues(alpha: 0.92)
              : AppColors.textSecondary.withValues(alpha: 0.42),
        ),
        style: IconButton.styleFrom(
          foregroundColor: enabled
              ? (action == AdminVenueCrmAction.deleteVenue
                    ? AppColors.primaryPink.withValues(alpha: 0.95)
                    : AppColors.primaryPink.withValues(alpha: 0.9))
              : AppColors.textSecondary.withValues(alpha: 0.42),
          backgroundColor: enabled
              ? (action == AdminVenueCrmAction.deleteVenue
                    ? AppColors.primaryPink.withValues(alpha: 0.14)
                    : AppColors.primaryPurple.withValues(alpha: 0.12))
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            side: BorderSide(
              color: enabled
                  ? AppColors.primaryPurple.withValues(alpha: 0.22)
                  : AppColors.border.withValues(alpha: 0.18),
            ),
          ),
        ),
        onPressed: enabled ? onPressed : null,
      ),
    );
  }
}

class _VenuesCrmProfileModalOverlay extends StatelessWidget {
  const _VenuesCrmProfileModalOverlay({
    super.key,
    required this.venue,
    required this.repository,
    required this.permissions,
    required this.actionLoading,
    required this.editDialogOpen,
    required this.confirmDialogOpen,
    required this.onClose,
    required this.onEdit,
    required this.onVisibilityToggle,
    required this.onVerifyToggle,
    required this.onDelete,
    required this.onOpenPublic,
    required this.onOpenMap,
    required this.onOpenOwnerProfile,
    required this.onViewSubscription,
  });

  final AdminDocumentRow venue;
  final AdminDashboardRepository repository;
  final AdminVenueCrmPermissions permissions;
  final bool actionLoading;
  final bool editDialogOpen;
  final bool confirmDialogOpen;
  final VoidCallback onClose;
  final VoidCallback onEdit;
  final VoidCallback onVisibilityToggle;
  final VoidCallback onVerifyToggle;
  final VoidCallback onDelete;
  final VoidCallback onOpenPublic;
  final VoidCallback onOpenMap;
  final void Function(String uid, String? email) onOpenOwnerProfile;
  final VoidCallback onViewSubscription;

  bool get _childDialogOpen => editDialogOpen || confirmDialogOpen;

  void _handleClose() {
    if (_childDialogOpen) return;
    onClose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final modalWidth = (screenSize.width - 48).clamp(
      screenSize.width >= 1048 ? 1000.0 : 320.0,
      1200.0,
    );
    final modalMaxHeight = screenSize.height * 0.85;

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape):
            _CloseVenuesCrmModalIntent(),
      },
      child: Actions(
        actions: {
          _CloseVenuesCrmModalIntent:
              CallbackAction<_CloseVenuesCrmModalIntent>(
                onInvoke: (_) {
                  _handleClose();
                  return null;
                },
              ),
        },
        child: Focus(
          autofocus: true,
          child: Material(
            color: Colors.transparent,
            child: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _handleClose,
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.64),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: modalWidth,
                        maxHeight: modalMaxHeight,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: GlassContainer(
                          padding: EdgeInsets.zero,
                          borderRadius: AppSpacing.radiusLg,
                          blur: 22,
                          opacity: 0.82,
                          elevation: GlassElevation.medium,
                          innerHighlight: true,
                          child: _VenuesCrmProfileModalBody(
                            venue: venue,
                            repository: repository,
                            permissions: permissions,
                            actionLoading: actionLoading,
                            editDialogOpen: editDialogOpen,
                            confirmDialogOpen: confirmDialogOpen,
                            onClose: _handleClose,
                            onEdit: onEdit,
                            onVisibilityToggle: onVisibilityToggle,
                            onVerifyToggle: onVerifyToggle,
                            onDelete: onDelete,
                            onOpenPublic: onOpenPublic,
                            onOpenMap: onOpenMap,
                            onOpenOwnerProfile: onOpenOwnerProfile,
                            onViewSubscription: onViewSubscription,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseVenuesCrmModalIntent extends Intent {
  const _CloseVenuesCrmModalIntent();
}

class _VenuesCrmProfileModalBody extends StatefulWidget {
  const _VenuesCrmProfileModalBody({
    required this.venue,
    required this.repository,
    required this.permissions,
    required this.actionLoading,
    required this.editDialogOpen,
    required this.confirmDialogOpen,
    required this.onClose,
    required this.onEdit,
    required this.onVisibilityToggle,
    required this.onVerifyToggle,
    required this.onDelete,
    required this.onOpenPublic,
    required this.onOpenMap,
    required this.onOpenOwnerProfile,
    required this.onViewSubscription,
  });

  final AdminDocumentRow venue;
  final AdminDashboardRepository repository;
  final AdminVenueCrmPermissions permissions;
  final bool actionLoading;
  final bool editDialogOpen;
  final bool confirmDialogOpen;
  final VoidCallback onClose;
  final VoidCallback onEdit;
  final VoidCallback onVisibilityToggle;
  final VoidCallback onVerifyToggle;
  final VoidCallback onDelete;
  final VoidCallback onOpenPublic;
  final VoidCallback onOpenMap;
  final void Function(String uid, String? email) onOpenOwnerProfile;
  final VoidCallback onViewSubscription;

  @override
  State<_VenuesCrmProfileModalBody> createState() =>
      _VenuesCrmProfileModalBodyState();
}

class _VenuesCrmProfileModalBodyState
    extends State<_VenuesCrmProfileModalBody> {
  static final Map<String, AdminVenueSupplementaryData> _supplementaryCache =
      {};
  static final Map<String, Future<AdminVenueSupplementaryData>> _inFlightLoads =
      {};

  static void invalidateSupplementaryCache(String venueId) {
    _supplementaryCache.remove(venueId);
    _inFlightLoads.remove(venueId);
  }

  AdminVenueSupplementaryData? _supplementary;
  bool _loadingSupplementary = false;
  String? _activeVenueId;

  @override
  void initState() {
    super.initState();
    _syncVenue(widget.venue.id, notify: false);
  }

  @override
  void didUpdateWidget(covariant _VenuesCrmProfileModalBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.venue.id != widget.venue.id) {
      _syncVenue(widget.venue.id);
    } else if (oldWidget.venue.data != widget.venue.data) {
      setState(() {});
      if (!_supplementaryCache.containsKey(widget.venue.id)) {
        _syncVenue(widget.venue.id);
      }
    }
  }

  void _syncVenue(String venueId, {bool notify = true}) {
    _activeVenueId = venueId;

    final cached = _supplementaryCache[venueId];
    if (cached != null) {
      if (notify) {
        setState(() {
          _supplementary = cached;
          _loadingSupplementary = false;
        });
      } else {
        _supplementary = cached;
        _loadingSupplementary = false;
      }
      return;
    }

    if (notify) {
      setState(() {
        _supplementary = null;
        _loadingSupplementary = true;
      });
    } else {
      _supplementary = null;
      _loadingSupplementary = true;
    }
    _loadSupplementary(venueId);
  }

  Future<void> _loadSupplementary(String venueId) async {
    final future = _inFlightLoads.putIfAbsent(
      venueId,
      () => _fetchSupplementary(venueId),
    );
    try {
      final data = await future;
      _supplementaryCache[venueId] = data;
      if (!mounted || _activeVenueId != venueId) return;
      setState(() {
        _supplementary = data;
        _loadingSupplementary = false;
      });
    } finally {
      _inFlightLoads.remove(venueId);
    }
  }

  Future<AdminVenueSupplementaryData> _fetchSupplementary(
    String venueId,
  ) async {
    final profile = AdminVenueCrmView(row: widget.venue);
    final content = await widget.repository.fetchVenueContentSummary(venueId);

    AdminVenueOwnerContext? owner;
    if (profile.ownerId.isNotEmpty && profile.ownerId != '—') {
      owner = await widget.repository.fetchVenueOwnerContext(
        profile.ownerId,
        venueData: widget.venue.data,
      );
    }

    final claim = await widget.repository.fetchVenueClaimInfo(
      venueId,
      venueData: widget.venue.data,
    );
    final reports = await widget.repository.fetchReportsForVenue(venueId);

    return AdminVenueSupplementaryData(
      content: content,
      owner: owner,
      claim: claim,
      reports: reports,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = AdminVenueCrmView(row: widget.venue);
    final supplementary = _supplementary;
    final content = supplementary?.content;
    final health = profile.calculateHealth(
      drinksCount: content?.drinksCount ?? 0,
      dealsCount: content?.dealsCount ?? 0,
      eventsCount: content?.eventsCount ?? 0,
      galleryImagesCount: profile.galleryImagesCount,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _VenuesCrmProfileModalHeader(profile: profile, onClose: widget.onClose),
        if (widget.actionLoading) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: _buildModalMasonryLayout(
              profile: profile,
              supplementary: supplementary,
              content: content,
              health: health,
            ),
          ),
        ),
      ],
    );
  }

  static const _modalSectionGap = AppSpacing.xl;

  Widget _buildModalMasonryLayout({
    required AdminVenueCrmView profile,
    required AdminVenueSupplementaryData? supplementary,
    required AdminVenueContentSummary? content,
    required AdminVenueHealth health,
  }) {
    final loadingSupplementary = _loadingSupplementary && supplementary == null;

    final overview = _VenuesCrmSection(
      title: 'Overview',
      compact: true,
      child: _VenuesCrmContextGrid(
        items: [
          (label: 'Venue name', value: profile.name),
          (label: 'Category', value: profile.category),
          (label: 'Description', value: profile.description),
          (label: 'Address', value: profile.address),
          (label: 'City', value: profile.city),
          (label: 'Postcode', value: profile.postcode),
          (label: 'Phone', value: profile.phone),
          (label: 'Website', value: profile.website),
          (label: 'Owner ID', value: profile.ownerId),
          (label: 'Status', value: profile.statusLabel),
          (label: 'Visibility', value: profile.visibilityLabel),
          (label: 'Claimed', value: profile.claimedLabel),
          (label: 'Verified', value: profile.verifiedLabel),
          (label: 'Created', value: profile.createdAt),
          (label: 'Updated', value: profile.updatedAt),
          (label: 'Venue ID', value: profile.venueId),
        ],
      ),
    );

    final leftColumn = [
      overview,
      _VenuesCrmSection(
        title: 'Account Management',
        compact: true,
        child: _VenuesCrmAccountActions(
          venue: profile,
          permissions: widget.permissions,
          editDialogOpen: widget.editDialogOpen,
          confirmDialogOpen: widget.confirmDialogOpen,
          onEdit: widget.onEdit,
          onVisibilityToggle: widget.onVisibilityToggle,
          onVerifyToggle: widget.onVerifyToggle,
          onDelete: widget.onDelete,
          onOpenPublic: widget.onOpenPublic,
          onOpenMap: widget.onOpenMap,
        ),
      ),
      _VenuesCrmSection(
        title: 'Claim History',
        compact: true,
        child: _buildClaimHistory(profile, supplementary?.claim),
      ),
      _VenuesCrmSection(
        title: 'Reports & Moderation',
        compact: true,
        child: _buildReportsSection(supplementary),
      ),
    ];

    final rightColumn = [
      _VenuesCrmHealthCard(
        health: health,
        loading: loadingSupplementary,
        compact: true,
      ),
      _VenuesCrmOwnerContextCard(
        profile: profile,
        owner: supplementary?.owner,
        loading: loadingSupplementary,
        compact: true,
        onOpenOwnerProfile: widget.onOpenOwnerProfile,
        onViewSubscription: widget.onViewSubscription,
      ),
      _VenuesCrmSection(
        title: 'Content Summary',
        compact: true,
        child: _buildContentSummary(content, profile),
      ),
      _VenuesCrmSection(
        title: 'Analytics Snapshot',
        compact: true,
        child: _buildAnalyticsSnapshot(),
      ),
      _VenuesCrmSection(
        title: 'Internal Notes & Audit',
        compact: true,
        child: _buildInternalNotesSection(),
      ),
    ];

    return _VenuesCrmModalMasonryColumns(
      left: leftColumn,
      right: rightColumn,
      sectionGap: _modalSectionGap,
    );
  }

  Widget _buildContentSummary(
    AdminVenueContentSummary? content,
    AdminVenueCrmView profile,
  ) {
    if (_loadingSupplementary && content == null) {
      return const Text(
        'Loading content summary…',
        style: TextStyle(color: AppColors.textSecondary),
      );
    }

    if (content?.unavailable == true) {
      return const Text(
        'Content counts unavailable for admin access yet.',
        style: TextStyle(color: AppColors.textSecondary, height: 1.45),
      );
    }

    return _VenuesCrmStatGrid(
      tiles: [
        _VenuesCrmStatTile(
          label: 'Drinks',
          value: content?.drinksCount?.toString() ?? '—',
          icon: Icons.local_bar_outlined,
        ),
        _VenuesCrmStatTile(
          label: 'Deals',
          value: content?.dealsCount?.toString() ?? '—',
          icon: Icons.local_offer_outlined,
        ),
        _VenuesCrmStatTile(
          label: 'Events',
          value: content?.eventsCount?.toString() ?? '—',
          icon: Icons.event_outlined,
        ),
        _VenuesCrmStatTile(
          label: 'Live deals',
          value: content?.liveDealsCount?.toString() ?? '—',
          icon: Icons.flash_on_outlined,
        ),
        _VenuesCrmStatTile(
          label: 'Upcoming events',
          value: content?.upcomingEventsCount?.toString() ?? '—',
          icon: Icons.upcoming_outlined,
        ),
        _VenuesCrmStatTile(
          label: 'Gallery images',
          value:
              content?.galleryImagesCount?.toString() ??
              profile.galleryImagesCount.toString(),
          icon: Icons.photo_library_outlined,
        ),
      ],
    );
  }

  Widget _buildAnalyticsSnapshot() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _VenuesCrmStatGrid(
          tiles: const [
            _VenuesCrmStatTile(
              label: 'Views',
              value: '—',
              icon: Icons.visibility_outlined,
            ),
            _VenuesCrmStatTile(
              label: 'Searches',
              value: '—',
              icon: Icons.search_outlined,
            ),
            _VenuesCrmStatTile(
              label: 'Saves',
              value: '—',
              icon: Icons.bookmark_outline_rounded,
            ),
            _VenuesCrmStatTile(
              label: 'Direction taps',
              value: '—',
              icon: Icons.directions_outlined,
            ),
            _VenuesCrmStatTile(
              label: 'Phone taps',
              value: '—',
              icon: Icons.phone_outlined,
            ),
            _VenuesCrmStatTile(
              label: 'Trending score',
              value: '—',
              icon: Icons.trending_up_rounded,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Analytics not available yet.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildInternalNotesSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _VenuesCrmContextLine(
          label: 'Internal notes',
          value: '—',
          compact: true,
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          'Audit log — TODO',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          'Moderation history — TODO',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildClaimHistory(
    AdminVenueCrmView profile,
    AdminVenueClaimInfo? claim,
  ) {
    if (_loadingSupplementary && claim == null) {
      return const Text(
        'Loading claim history…',
        style: TextStyle(color: AppColors.textSecondary),
      );
    }

    if (claim?.unavailable == true) {
      return const Text(
        'Claim directory unavailable for admin access yet.',
        style: TextStyle(color: AppColors.textSecondary, height: 1.45),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _VenuesCrmContextGrid(
          items: [
            (
              label: 'Claim status',
              value: claim?.claimStatus ?? profile.claimStatusLabel,
            ),
            (
              label: 'Claimed by',
              value: claim?.claimedByUserId ?? profile.ownerId,
            ),
            (
              label: 'Claimed venue ID',
              value: claim?.claimedVenueId ?? profile.venueId,
            ),
            (label: 'Directory source', value: claim?.directorySource ?? '—'),
            (label: 'Claim created', value: claim?.claimCreatedAt ?? '—'),
            (label: 'Claim updated', value: claim?.claimUpdatedAt ?? '—'),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Evidence review — TODO',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Reviewer assignment — TODO',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildReportsSection(AdminVenueSupplementaryData? supplementary) {
    final reports = supplementary?.reports ?? const [];

    if (_loadingSupplementary && supplementary == null) {
      return const Text(
        'Loading reports…',
        style: TextStyle(color: AppColors.textSecondary),
      );
    }

    if (reports.isEmpty) {
      return const _VenuesCrmContextLine(
        label: 'Reports',
        value: 'No linked reports found.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reports (${reports.length})',
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final report in reports.take(5))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              '• ${report.readString(['reason', 'type', 'status'])}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }
}

class _VenuesCrmProfileModalHeader extends StatelessWidget {
  const _VenuesCrmProfileModalHeader({
    required this.profile,
    required this.onClose,
  });

  final AdminVenueCrmView profile;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final hasLogo = profile.logoUrl.trim().isNotEmpty && profile.logoUrl != '—';

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.glassBorder.withValues(alpha: 0.65),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasLogo ? null : AppColors.brandGradient,
              image: hasLogo
                  ? DecorationImage(
                      image: NetworkImage(profile.logoUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: hasLogo
                ? null
                : Center(
                    child: Text(
                      profile.initials,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  profile.category,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _VenuesCrmStatusChip(label: profile.statusLabel),
                    _VenuesCrmClaimChip(label: profile.claimedLabel),
                    _VenuesCrmVerifiedChip(verified: profile.isVerified),
                  ],
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              hoverColor: AppColors.primaryPink.withValues(alpha: 0.12),
              child: const Padding(
                padding: EdgeInsets.all(AppSpacing.sm),
                child: Icon(
                  Icons.close_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VenuesCrmHealthCard extends StatelessWidget {
  const _VenuesCrmHealthCard({
    required this.health,
    required this.loading,
    this.compact = false,
  });

  final AdminVenueHealth health;
  final bool loading;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _VenuesCrmSection(
      title: 'Venue Health',
      compact: compact,
      child: loading
          ? const Text(
              'Loading health details…',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
            )
          : health.isComplete
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _VenuesCrmHealthDonut(health: health),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Venue profile complete',
                        style: TextStyle(
                          color: AppColors.trailGold.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w800,
                          fontSize: compact ? 13 : 14,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${health.passedCount} / ${health.totalCount} checklist items complete',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _VenuesCrmHealthDonut(health: health),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Missing items',
                        style: TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: health.missingItems
                            .map(
                              (item) => _VenuesCrmHealthTag(
                                label: item.label,
                                missing: true,
                              ),
                            )
                            .toList(),
                      ),
                      if (health.passedItems.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Also complete (${health.passedItems.length})',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: health.passedItems
                              .map(
                                (item) => _VenuesCrmHealthTag(
                                  label: item.label,
                                  missing: false,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _VenuesCrmHealthDonut extends StatelessWidget {
  const _VenuesCrmHealthDonut({required this.health});

  final AdminVenueHealth health;

  Color get _accentColor {
    final score = health.scorePercent;
    if (score >= 75) return AppColors.trailGold;
    if (score >= 45) return AppColors.primaryPurple;
    return AppColors.primaryPink;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108,
      height: 108,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(108, 108),
            painter: _VenuesCrmHealthDonutPainter(
              progress: health.totalCount == 0
                  ? 0
                  : health.passedCount / health.totalCount,
              color: _accentColor,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${health.scorePercent}%',
                style: TextStyle(
                  color: _accentColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${health.passedCount} / ${health.totalCount}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 10.5,
                  height: 1.1,
                ),
              ),
              const Text(
                'complete',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 9.5,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VenuesCrmHealthDonutPainter extends CustomPainter {
  _VenuesCrmHealthDonutPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) * 0.38;
    const strokeWidth = 11.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = AppColors.border.withValues(alpha: 0.55);
    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);

    if (progress <= 0) return;

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0, 1),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _VenuesCrmHealthDonutPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _VenuesCrmHealthTag extends StatelessWidget {
  const _VenuesCrmHealthTag({required this.label, required this.missing});

  final String label;
  final bool missing;

  @override
  Widget build(BuildContext context) {
    final accent = missing ? AppColors.primaryPink : AppColors.primaryPurple;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: missing ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: accent.withValues(alpha: missing ? 0.28 : 0.18),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: missing
              ? AppColors.white.withValues(alpha: 0.92)
              : AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _VenuesCrmOwnerContextCard extends StatelessWidget {
  const _VenuesCrmOwnerContextCard({
    required this.profile,
    required this.owner,
    required this.loading,
    this.compact = false,
    required this.onOpenOwnerProfile,
    required this.onViewSubscription,
  });

  final AdminVenueCrmView profile;
  final AdminVenueOwnerContext? owner;
  final bool loading;
  final bool compact;
  final void Function(String uid, String? email) onOpenOwnerProfile;
  final VoidCallback onViewSubscription;

  @override
  Widget build(BuildContext context) {
    return _VenuesCrmSection(
      title: 'Owner Context',
      compact: compact,
      child: loading
          ? const Text(
              'Loading owner context…',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
            )
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final owner = this.owner;
    if (owner?.unavailable == true) {
      return const Text(
        'Owner data unavailable for admin access yet.',
        style: TextStyle(
          color: AppColors.textSecondary,
          height: 1.35,
          fontSize: 12.5,
        ),
      );
    }

    if (owner == null && (profile.ownerId.isEmpty || profile.ownerId == '—')) {
      return const Text(
        'No owner linked to this venue.',
        style: TextStyle(
          color: AppColors.textSecondary,
          height: 1.35,
          fontSize: 12.5,
        ),
      );
    }

    final ownerUid = owner?.ownerUid ?? profile.ownerId;
    final ownerName = owner?.ownerName ?? profile.ownerName;
    final ownerEmail = owner?.ownerEmail;
    final hasOwner = ownerUid.isNotEmpty && ownerUid != '—';
    final subscriptionTier = formatAdminVenueSubscriptionTier(
      owner?.subscriptionTier ??
          (profile.subscriptionTier == '—' ? null : profile.subscriptionTier),
    );
    final subscriptionStatus = formatAdminVenueSubscriptionStatus(
      owner?.subscriptionStatus ??
          (profile.subscriptionStatus == '—'
              ? null
              : profile.subscriptionStatus),
    );
    final hasSubscription =
        subscriptionTier != '—' || subscriptionStatus != '—';
    final isPremium = isPremiumVenueSubscriptionTier(subscriptionTier);
    final venueLimit = owner?.venueLimit?.toString() ?? '—';
    final ownedVenues = owner?.ownedVenuesCount?.toString() ?? '—';
    final teamMembers = owner?.teamMembersCount?.toString() ?? '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _VenuesCrmContextGrid(
          items: [
            (label: 'Owner name', value: ownerName),
            (label: 'Owner email', value: ownerEmail ?? '—'),
            (label: 'Owner status', value: owner?.ownerStatus ?? '—'),
            (label: 'Owner UID', value: ownerUid),
            (label: 'Owned venues', value: ownedVenues),
          ],
          tapByLabel: hasOwner
              ? {
                  'Owner name': () => onOpenOwnerProfile(ownerUid, ownerEmail),
                  if (ownerEmail != null && ownerEmail != '—')
                    'Owner email': () =>
                        onOpenOwnerProfile(ownerUid, ownerEmail),
                }
              : null,
        ),
        if (hasSubscription) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (subscriptionTier != '—')
                _VenuesCrmSubscriptionChip(
                  label: subscriptionTier,
                  premium: isPremium,
                ),
              if (subscriptionStatus != '—')
                _VenuesCrmSubscriptionStatusChip(label: subscriptionStatus),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        _VenuesCrmContextGrid(
          items: [
            (label: 'Venue limit', value: venueLimit),
            (label: 'Team members', value: teamMembers),
            if (!hasSubscription) (label: 'Subscription tier', value: '—'),
            if (!hasSubscription) (label: 'Subscription status', value: '—'),
          ],
        ),
        if (hasOwner || hasSubscription) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (hasOwner)
                DrinkSpotButton(
                  label: 'Open Owner Profile',
                  icon: Icons.person_outline_rounded,
                  compact: true,
                  variant: DrinkSpotButtonVariant.secondary,
                  onPressed: () => onOpenOwnerProfile(ownerUid, ownerEmail),
                ),
              if (hasSubscription)
                DrinkSpotButton(
                  label: 'View Subscription',
                  icon: Icons.workspace_premium_outlined,
                  compact: true,
                  variant: DrinkSpotButtonVariant.secondary,
                  onPressed: onViewSubscription,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _VenuesCrmSubscriptionChip extends StatelessWidget {
  const _VenuesCrmSubscriptionChip({
    required this.label,
    required this.premium,
  });

  final String label;
  final bool premium;

  @override
  Widget build(BuildContext context) {
    final accent = premium ? AppColors.trailGold : AppColors.primaryPurple;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        gradient: premium
            ? LinearGradient(
                colors: [
                  AppColors.trailGold.withValues(alpha: 0.22),
                  AppColors.primaryPink.withValues(alpha: 0.14),
                ],
              )
            : null,
        color: premium ? null : accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: accent.withValues(alpha: premium ? 0.55 : 0.32),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (premium) ...[
            Icon(
              Icons.workspace_premium_rounded,
              size: 14,
              color: accent.withValues(alpha: 0.95),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: premium ? AppColors.white : accent,
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _VenuesCrmSubscriptionStatusChip extends StatelessWidget {
  const _VenuesCrmSubscriptionStatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final normalized = label.toLowerCase();
    final isActive =
        normalized.contains('active') ||
        normalized.contains('trialing') ||
        normalized == 'paid';
    final color = isActive ? const Color(0xFF44D7A8) : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
        ),
      ),
    );
  }
}

class _VenuesCrmAccountActions extends StatelessWidget {
  const _VenuesCrmAccountActions({
    required this.venue,
    required this.permissions,
    required this.editDialogOpen,
    required this.confirmDialogOpen,
    required this.onEdit,
    required this.onVisibilityToggle,
    required this.onVerifyToggle,
    required this.onDelete,
    required this.onOpenPublic,
    required this.onOpenMap,
  });

  final AdminVenueCrmView venue;
  final AdminVenueCrmPermissions permissions;
  final bool editDialogOpen;
  final bool confirmDialogOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onVisibilityToggle;
  final VoidCallback? onVerifyToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onOpenPublic;
  final VoidCallback? onOpenMap;

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      _actionButton(
        label: 'Edit venue',
        icon: Icons.edit_rounded,
        action: AdminVenueCrmAction.editVenue,
        backendTodo: false,
        onPressed:
            permissions.canEditVenue() && !editDialogOpen && !confirmDialogOpen
            ? onEdit
            : null,
        disabledSubtitle: editDialogOpen ? 'Edit dialog already open' : null,
      ),
      _actionButton(
        label: venue.isVerified ? 'Unverify venue' : 'Verify venue',
        icon: venue.isVerified
            ? Icons.verified_outlined
            : Icons.verified_rounded,
        action: venue.isVerified
            ? AdminVenueCrmAction.unverify
            : AdminVenueCrmAction.verify,
        backendTodo: false,
        onPressed:
            permissions.canVerify() && !confirmDialogOpen && !editDialogOpen
            ? onVerifyToggle
            : null,
        disabledSubtitle: confirmDialogOpen
            ? 'Confirmation dialog already open'
            : null,
      ),
      _actionButton(
        label: venue.isVisible
            ? 'Hide venue from public'
            : 'Publish venue / Show publicly',
        icon: venue.isVisible
            ? Icons.visibility_off_outlined
            : Icons.visibility_outlined,
        action: venue.isVisible
            ? AdminVenueCrmAction.hideVenue
            : AdminVenueCrmAction.showVenue,
        backendTodo: false,
        onPressed:
            permissions.canHideVenue() && !confirmDialogOpen && !editDialogOpen
            ? onVisibilityToggle
            : null,
        disabledSubtitle: confirmDialogOpen
            ? 'Confirmation dialog already open'
            : null,
      ),
      _actionButton(
        label: 'View public venue page',
        icon: Icons.public_outlined,
        action: AdminVenueCrmAction.openPublicVenue,
        backendTodo: false,
        onPressed: permissions.canViewProfile() ? onOpenPublic : null,
      ),
      _actionButton(
        label: 'View on map',
        icon: Icons.map_outlined,
        action: AdminVenueCrmAction.openOnMap,
        backendTodo: false,
        onPressed: permissions.canOpenMap() ? onOpenMap : null,
      ),
      _actionButton(
        label: 'Delete venue',
        icon: Icons.delete_forever_rounded,
        action: AdminVenueCrmAction.deleteVenue,
        backendTodo: false,
        onPressed:
            permissions.canDelete() && !confirmDialogOpen && !editDialogOpen
            ? onDelete
            : null,
        disabledSubtitle: confirmDialogOpen
            ? 'Confirmation dialog already open'
            : null,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumn = constraints.maxWidth >= 340;
        if (!twoColumn) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < buttons.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.sm),
                buttons[i],
              ],
            ],
          );
        }

        final tileWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: buttons
              .map((button) => SizedBox(width: tileWidth, child: button))
              .toList(),
        );
      },
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required AdminVenueCrmAction action,
    required bool backendTodo,
    required VoidCallback? onPressed,
    String? disabledSubtitle,
  }) {
    final allowed = permissions.isActionAllowed(action);
    final enabled = allowed && !backendTodo && onPressed != null;
    final subtitle =
        disabledSubtitle ??
        (backendTodo
            ? kAdminVenueBackendRequiredTooltip
            : (!allowed ? kAdminPermissionDeniedTooltip : null));

    if (enabled) {
      return DrinkSpotButton(
        label: label,
        icon: icon,
        compact: true,
        variant: DrinkSpotButtonVariant.secondary,
        onPressed: onPressed,
      );
    }

    return _VenuesCrmDisabledActionTile(
      label: label,
      icon: icon,
      subtitle: subtitle ?? kAdminPermissionDeniedTooltip,
      isBackendTodo: backendTodo,
    );
  }
}

class _VenueDeleteDialog extends StatefulWidget {
  const _VenueDeleteDialog({required this.venueName, this.onFinished});

  final String venueName;
  final void Function(({bool confirmed, String? reason})? result)? onFinished;

  @override
  State<_VenueDeleteDialog> createState() => _VenueDeleteDialogState();
}

class _VenueDeleteDialogState extends State<_VenueDeleteDialog> {
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _finish({required bool confirmed}) {
    final reason = _reasonController.text.trim();
    widget.onFinished?.call((
      confirmed: confirmed,
      reason: reason.isEmpty ? null : reason,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceElevated,
      title: const Text('Delete venue'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'You are about to remove "${widget.venueName}" from the active venues list.',
              style: const TextStyle(color: AppColors.white),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'The venue will be archived to deleted_venues before it disappears from admin and public listings. This is not an immediate hard delete.',
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.95),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              style: const TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                labelText: 'Reason (optional)',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surfaceElevated.withValues(alpha: 0.78),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _finish(confirmed: false),
          child: const Text('Cancel'),
        ),
        DrinkSpotButton(
          label: 'Delete venue',
          compact: true,
          variant: DrinkSpotButtonVariant.secondary,
          onPressed: () => _finish(confirmed: true),
        ),
      ],
    );
  }
}

class _VenueEditDialog extends StatefulWidget {
  const _VenueEditDialog({
    required this.venue,
    required this.repository,
    this.onFinished,
  });

  final AdminVenueCrmView venue;
  final AdminDashboardRepository repository;
  final void Function([bool? result])? onFinished;

  @override
  State<_VenueEditDialog> createState() => _VenueEditDialogState();
}

class _VenueEditDialogState extends State<_VenueEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _postcodeController;
  late final TextEditingController _phoneController;
  late final TextEditingController _websiteController;
  late bool _publicVisible;
  late bool _verified;
  late String _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final venue = widget.venue;
    _nameController = TextEditingController(text: venue.name);
    _categoryController = TextEditingController(
      text: venue.category == '—' ? '' : venue.category,
    );
    _descriptionController = TextEditingController(
      text: venue.description == '—' ? '' : venue.description,
    );
    _addressController = TextEditingController(
      text: venue.address == '—' ? '' : venue.address,
    );
    _cityController = TextEditingController(
      text: venue.city == '—' ? '' : venue.city,
    );
    _postcodeController = TextEditingController(
      text: venue.postcode == '—' ? '' : venue.postcode,
    );
    _phoneController = TextEditingController(
      text: venue.phone == '—' ? '' : venue.phone,
    );
    _websiteController = TextEditingController(
      text: venue.website == '—' ? '' : venue.website,
    );
    _publicVisible = venue.isVisible;
    _verified = venue.isVerified;
    _status = venue.status;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postcodeController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _closeDialog([bool? result]) {
    if (widget.onFinished != null) {
      widget.onFinished!(result);
    } else {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: GlassContainer(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Edit Venue',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  widget.venue.venueId,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),
                _VenuesCrmTextField(controller: _nameController, label: 'Name'),
                const SizedBox(height: AppSpacing.md),
                _VenuesCrmTextField(
                  controller: _categoryController,
                  label: 'Category',
                ),
                const SizedBox(height: AppSpacing.md),
                _VenuesCrmTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  maxLines: 3,
                ),
                const SizedBox(height: AppSpacing.md),
                _VenuesCrmTextField(
                  controller: _addressController,
                  label: 'Address',
                ),
                const SizedBox(height: AppSpacing.md),
                _VenuesCrmTextField(controller: _cityController, label: 'City'),
                const SizedBox(height: AppSpacing.md),
                _VenuesCrmTextField(
                  controller: _postcodeController,
                  label: 'Postcode',
                ),
                const SizedBox(height: AppSpacing.md),
                _VenuesCrmTextField(
                  controller: _phoneController,
                  label: 'Phone',
                ),
                const SizedBox(height: AppSpacing.md),
                _VenuesCrmTextField(
                  controller: _websiteController,
                  label: 'Website',
                ),
                const SizedBox(height: AppSpacing.md),
                Material(
                  color: Colors.transparent,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Public visible',
                      style: TextStyle(color: AppColors.white),
                    ),
                    value: _publicVisible,
                    onChanged: (value) =>
                        setState(() => _publicVisible = value),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Verified',
                      style: TextStyle(color: AppColors.white),
                    ),
                    value: _verified,
                    onChanged: (value) => setState(() => _verified = value),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _VenuesCrmDropdown(
                  label: 'Status',
                  value: _status,
                  values: const ['active', 'suspended', 'pending', 'hidden'],
                  onChanged: (value) => setState(() => _status = value),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: DrinkSpotButton(
                        label: 'Cancel',
                        variant: DrinkSpotButtonVariant.ghost,
                        onPressed: _saving ? null : () => _closeDialog(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: DrinkSpotButton(
                        label: _saving ? 'Saving…' : 'Save',
                        onPressed: _saving ? null : () => _save(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _saving) return;

    setState(() => _saving = true);
    try {
      await widget.repository.updateDocument(
        path: 'venues/${widget.venue.venueId}',
        updates: {
          'name': name,
          'category': _categoryController.text.trim(),
          'description': _descriptionController.text.trim(),
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'postcode': _postcodeController.text.trim(),
          'phone': _phoneController.text.trim(),
          'website': _websiteController.text.trim(),
          'publicVisible': _publicVisible,
          'isVisible': _publicVisible,
          'isVerified': _verified,
          'verified': _verified,
          'status': _status,
        },
      );
      if (!mounted) return;
      _closeDialog(true);
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save venue: ${error.message ?? error.code}'),
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save venue: $error')));
    }
  }
}

class _VenuesCrmModalMasonryColumns extends StatelessWidget {
  const _VenuesCrmModalMasonryColumns({
    required this.left,
    required this.right,
    required this.sectionGap,
  });

  final List<Widget> left;
  final List<Widget> right;
  final double sectionGap;

  static const _breakpoint = 720.0;

  List<Widget> _stackSections(List<Widget> sections) {
    if (sections.isEmpty) return const [];
    final stacked = <Widget>[sections.first];
    for (var index = 1; index < sections.length; index++) {
      stacked.add(SizedBox(height: sectionGap));
      stacked.add(sections[index]);
    }
    return stacked;
  }

  List<Widget> _interleaveForMobile() {
    final merged = <Widget>[];
    final maxLen = left.length > right.length ? left.length : right.length;
    for (var index = 0; index < maxLen; index++) {
      if (index < left.length) merged.add(left[index]);
      if (index < right.length) merged.add(right[index]);
    }
    return merged;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: _stackSections(_interleaveForMobile()),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: _stackSections(left),
              ),
            ),
            SizedBox(width: sectionGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: _stackSections(right),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _VenuesCrmStatTile extends StatelessWidget {
  const _VenuesCrmStatTile({
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: AppColors.glassBorder.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: AppColors.primaryPurple),
            const SizedBox(height: 4),
          ],
          Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
              fontSize: 17,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _VenuesCrmStatGrid extends StatelessWidget {
  const _VenuesCrmStatGrid({required this.tiles});

  final List<_VenuesCrmStatTile> tiles;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 420 ? 3 : 2;
        final spacing = AppSpacing.sm;
        final tileWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: tiles
              .map((tile) => SizedBox(width: tileWidth, child: tile))
              .toList(),
        );
      },
    );
  }
}

class _VenuesCrmContextGrid extends StatelessWidget {
  const _VenuesCrmContextGrid({required this.items, this.tapByLabel});

  final List<({String label, String value})> items;
  final Map<String, VoidCallback>? tapByLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumn = constraints.maxWidth >= 380;
        if (!twoColumn) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items
                .map(
                  (item) => _VenuesCrmContextLine(
                    label: item.label,
                    value: item.value,
                    compact: true,
                    onTap: tapByLabel?[item.label],
                  ),
                )
                .toList(),
          );
        }

        final tileWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: 0,
          children: items
              .map(
                (item) => SizedBox(
                  width: tileWidth,
                  child: _VenuesCrmContextLine(
                    label: item.label,
                    value: item.value,
                    compact: true,
                    onTap: tapByLabel?[item.label],
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _VenuesCrmSection extends StatelessWidget {
  const _VenuesCrmSection({
    required this.title,
    required this.child,
    this.compact = false,
  });

  final String title;
  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return VenuePageSection(
      title: title,
      padding: compact
          ? const EdgeInsets.all(AppSpacing.md)
          : const EdgeInsets.all(AppSpacing.lg),
      child: child,
    );
  }
}

class _VenuesCrmContextLine extends StatelessWidget {
  const _VenuesCrmContextLine({
    required this.label,
    required this.value,
    this.compact = false,
    this.onTap,
  });

  final String label;
  final String value;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final valueStyle = TextStyle(
      color: onTap != null ? AppColors.primaryPink : AppColors.white,
      fontWeight: FontWeight.w700,
      fontSize: compact ? 11.5 : 12.5,
      decoration: onTap != null ? TextDecoration.underline : null,
      decorationColor: AppColors.primaryPink.withValues(alpha: 0.7),
    );

    final valueWidget = onTap == null
        ? SelectableText(value, style: valueStyle)
        : InkWell(
            onTap: onTap,
            child: Text(value, style: valueStyle),
          );

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? AppSpacing.xs : AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: compact ? 96 : 120,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: compact ? 11.5 : 12.5,
              ),
            ),
          ),
          Expanded(child: valueWidget),
        ],
      ),
    );
  }
}

class _VenuesCrmStatusChip extends StatelessWidget {
  const _VenuesCrmStatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final lower = label.toLowerCase();
    final color = switch (lower) {
      'active' || 'verified' => AppColors.trailGold,
      'suspended' || 'hidden' || 'disabled' => AppColors.primaryPink,
      _ => AppColors.primaryPurple,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
        ),
      ),
    );
  }
}

class _VenuesCrmClaimChip extends StatelessWidget {
  const _VenuesCrmClaimChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final claimed = label.toLowerCase() == 'claimed';
    final color = claimed ? AppColors.trailGold : AppColors.primaryPurple;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
        ),
      ),
    );
  }
}

class _VenuesCrmVerifiedChip extends StatelessWidget {
  const _VenuesCrmVerifiedChip({required this.verified});

  final bool verified;

  @override
  Widget build(BuildContext context) {
    final color = verified ? AppColors.trailGold : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        verified ? 'Verified' : 'Unverified',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
        ),
      ),
    );
  }
}

class _VenuesCrmVisibilityChip extends StatelessWidget {
  const _VenuesCrmVisibilityChip({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    final color = visible ? AppColors.trailGold : AppColors.primaryPink;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        visible ? 'Visible' : 'Hidden',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
        ),
      ),
    );
  }
}

class _VenuesCrmHealthChip extends StatelessWidget {
  const _VenuesCrmHealthChip({required this.health});

  final AdminVenueHealth health;

  @override
  Widget build(BuildContext context) {
    final score = health.scorePercent;
    final color = score >= 75
        ? AppColors.trailGold
        : score >= 45
        ? AppColors.primaryPurple
        : AppColors.primaryPink;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        '$score%',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
        ),
      ),
    );
  }
}

class _VenuesCrmDisabledActionTile extends StatelessWidget {
  const _VenuesCrmDisabledActionTile({
    required this.label,
    required this.icon,
    required this.subtitle,
    required this.isBackendTodo,
  });

  final String label;
  final IconData icon;
  final String subtitle;
  final bool isBackendTodo;

  @override
  Widget build(BuildContext context) {
    final borderColor = isBackendTodo
        ? AppColors.primaryPurple.withValues(alpha: 0.22)
        : AppColors.textSecondary.withValues(alpha: 0.28);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.white.withValues(alpha: 0.72)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.95),
                    fontSize: 11.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VenuesCrmDropdown extends StatelessWidget {
  const _VenuesCrmDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
    this.compact = false,
  });

  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final selected = values.contains(value) ? value : values.first;
    final textStyle = compact
        ? _VenuesCrmToolbarMetrics.fieldTextStyle
        : const TextStyle(
            color: AppColors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          );

    String displayLabel(String item) => '$label: $item';

    final field = DropdownButtonFormField<String>(
      isExpanded: true,
      isDense: true,
      iconSize: compact ? 18 : 24,
      menuMaxHeight: 320,
      initialValue: selected,
      dropdownColor: AppColors.surfaceElevated,
      style: textStyle,
      decoration: compact
          ? _VenuesCrmToolbarMetrics.dropdownDecoration(label: label)
          : InputDecoration(
              labelText: label,
              isDense: true,
              filled: true,
              fillColor: AppColors.surfaceElevated.withValues(alpha: 0.78),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
      items: values
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: textStyle,
              ),
            ),
          )
          .toList(),
      selectedItemBuilder: (context) => values
          .map(
            (item) => Align(
              alignment: Alignment.centerLeft,
              child: Text(
                displayLabel(item),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: textStyle,
              ),
            ),
          )
          .toList(),
      onChanged: (item) {
        if (item != null) onChanged(item);
      },
    );

    if (!compact) return field;

    return Theme(
      data: Theme.of(context).copyWith(visualDensity: VisualDensity.compact),
      child: field,
    );
  }
}

class _VenuesCrmTextField extends StatelessWidget {
  const _VenuesCrmTextField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.white),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surfaceElevated.withValues(alpha: 0.78),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }
}

class _VenuesCrmPaginationBar extends StatelessWidget {
  const _VenuesCrmPaginationBar({
    required this.pageIndex,
    required this.totalPages,
    required this.visibleCount,
    required this.totalCount,
    required this.pageSize,
    required this.onPageSizeChanged,
    required this.onPrevious,
    required this.onNext,
  });

  final int pageIndex;
  final int totalPages;
  final int visibleCount;
  final int totalCount;
  final int pageSize;
  final ValueChanged<int> onPageSizeChanged;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Showing $visibleCount of $totalCount · Page ${pageIndex + 1} of $totalPages',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        SizedBox(
          width: 120,
          height: _VenuesCrmToolbarMetrics.controlHeight,
          child: _VenuesCrmDropdown(
            label: 'Per page',
            compact: true,
            value: pageSize.toString(),
            values: kAdminVenuesCrmPageSizeOptions
                .map((size) => size.toString())
                .toList(),
            onChanged: (value) {
              final parsed = int.tryParse(value);
              if (parsed != null) onPageSizeChanged(parsed);
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        DrinkSpotButton(
          label: 'Previous',
          compact: true,
          variant: DrinkSpotButtonVariant.ghost,
          onPressed: onPrevious,
        ),
        const SizedBox(width: AppSpacing.sm),
        DrinkSpotButton(
          label: 'Next',
          compact: true,
          variant: DrinkSpotButtonVariant.secondary,
          onPressed: onNext,
        ),
      ],
    );
  }
}

class _VenuesCrmLoadingPanel extends StatelessWidget {
  const _VenuesCrmLoadingPanel();

  @override
  Widget build(BuildContext context) {
    return VenuePageSection(
      title: 'Loading venues',
      child: Column(
        children: [
          const LinearProgressIndicator(),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Reading venues collection…',
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _VenuesCrmErrorCard extends StatelessWidget {
  const _VenuesCrmErrorCard({
    required this.collectionPath,
    required this.error,
  });

  final String collectionPath;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final firebaseError = error is FirebaseException
        ? error as FirebaseException
        : null;
    final message = firebaseError != null
        ? '${firebaseError.code}: ${firebaseError.message ?? 'Firestore error'}'
        : error.toString();

    return VenuePageSection(
      title: 'Could not load venues',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.primaryPink,
            size: 34,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Collection: $collectionPath',
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _VenuesCrmInlineErrorBanner extends StatelessWidget {
  const _VenuesCrmInlineErrorBanner({required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    final firebaseError = error is FirebaseException
        ? error as FirebaseException
        : null;
    final message = firebaseError != null
        ? '${firebaseError.code}: ${firebaseError.message ?? 'Firestore error'}'
        : error.toString();

    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppSpacing.radiusMd,
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.primaryPink),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Live refresh failed — showing last loaded venues. $message',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
