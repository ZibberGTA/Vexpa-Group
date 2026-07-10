import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/components/drinkspot_button.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../auth/services/auth_service.dart';
import '../../../venue_management/widgets/page/venue_dashboard_page_widgets.dart';
import '../../../venue_management/widgets/venue_dashboard_layout.dart';
import '../../data/admin_dashboard_repository.dart';
import '../../models/admin_dashboard_models.dart';
import '../../models/admin_user_crm.dart';
import '../shared/admin_crm_sortable_header.dart';
import '../../permissions/admin_permission_constants.dart';
import '../../permissions/permission_service.dart';

/// Admin Users CRM — table, filters, profile modal, and user management actions.
class AdminUsersCrmPage extends StatefulWidget {
  const AdminUsersCrmPage({
    super.key,
    required this.repository,
    required this.permissions,
  });

  final AdminDashboardRepository repository;
  final PermissionService permissions;

  @override
  State<AdminUsersCrmPage> createState() => _AdminUsersCrmPageState();
}

class _AdminUsersCrmPageState extends State<AdminUsersCrmPage> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  String _statusFilter = 'All';
  String _roleFilter = 'All';
  String _cityFilter = 'All';
  String _accountTypeFilter = 'All';
  String _sortColumn = AdminUserTableSortColumn.defaultColumn;
  bool _sortAscending = AdminUserTableSortColumn.defaultAscending;
  int _pageIndex = 0;
  final Set<String> _selectedUserIds = {};
  AdminDocumentRow? _profileModalUser;
  bool _actionLoading = false;
  List<AdminDocumentRow>? _cachedRows;
  OverlayEntry? _profileOverlayEntry;
  static const _pageSize = 20;

  AdminUserCrmPermissions get _crmPermissions =>
      AdminUserCrmPermissions(widget.permissions);

  /// Fills the admin main-panel viewport below the page header so modal overlays
  /// are not clipped by short table/card content.
  double _usersCrmPageBodyHeight(BuildContext context) {
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
      _statusFilter != 'All' ||
      _roleFilter != 'All' ||
      _cityFilter != 'All' ||
      _accountTypeFilter != 'All';

  void _clearFilters() {
    setState(() {
      _search = '';
      _searchController.clear();
      _statusFilter = 'All';
      _roleFilter = 'All';
      _cityFilter = 'All';
      _accountTypeFilter = 'All';
      _pageIndex = 0;
    });
  }

  void _toggleUserSelection(String userId, bool selected) {
    setState(() {
      if (selected) {
        _selectedUserIds.add(userId);
      } else {
        _selectedUserIds.remove(userId);
      }
    });
  }

  void _toggleSelectAllVisible(List<AdminUserCrmView> visibleUsers) {
    final visibleIds = visibleUsers.map((user) => user.uid).toSet();
    final allSelected =
        visibleIds.isNotEmpty && visibleIds.every(_selectedUserIds.contains);

    setState(() {
      if (allSelected) {
        _selectedUserIds.removeAll(visibleIds);
      } else {
        _selectedUserIds.addAll(visibleIds);
      }
    });
  }

  List<String> get selectedUserIds => _selectedUserIds.toList(growable: false);

  String get _sortPresetLabel => adminUserSortPresetLabel(
    sortColumn: _sortColumn,
    sortAscending: _sortAscending,
  );

  void _handleUserColumnSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
    });
  }

  void _applyUserSortPreset(String preset) {
    setState(() {
      applyAdminUserSortPreset(preset, (column, ascending) {
        _sortColumn = column;
        _sortAscending = ascending;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _removeProfileOverlay();
    super.dispose();
  }

  void _removeProfileOverlay() {
    _profileOverlayEntry?.remove();
    _profileOverlayEntry?.dispose();
    _profileOverlayEntry = null;
  }

  AdminDocumentRow? _currentModalUserRow() {
    if (_profileModalUser == null) return null;
    final cached = _cachedRows;
    if (cached != null) {
      for (final row in cached) {
        if (row.id == _profileModalUser!.id) return row;
      }
    }
    return _profileModalUser;
  }

  void _showProfileOverlay({required AdminUserCrmPermissions permissions}) {
    _removeProfileOverlay();
    if (!mounted || _profileModalUser == null) return;

    _profileOverlayEntry = OverlayEntry(
      builder: (overlayContext) {
        final user = _currentModalUserRow();
        if (user == null) return const SizedBox.shrink();

        return _UsersCrmProfileModalOverlay(
          key: ValueKey(user.id),
          user: user,
          repository: widget.repository,
          permissions: permissions,
          actionLoading: _actionLoading,
          onClose: _closeProfileModal,
          onEdit: () => _openEditDialog(user),
          onSuspendToggle: () => _toggleSuspend(user),
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(_profileOverlayEntry!);
  }

  void _refreshProfileOverlay({required AdminUserCrmPermissions permissions}) {
    if (_profileModalUser == null) {
      _removeProfileOverlay();
      return;
    }
    if (_profileOverlayEntry == null) {
      _showProfileOverlay(permissions: permissions);
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
      height: _usersCrmPageBodyHeight(context),
      width: double.infinity,
      child: SingleChildScrollView(
        physics: modalOpen
            ? const NeverScrollableScrollPhysics()
            : const ClampingScrollPhysics(),
        child: body,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_crmPermissions.canViewProfile()) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<AdminDocumentRow>>(
      stream: widget.repository.watchCollection('users', limit: 250),
      builder: (context, snapshot) {
        if (snapshot.hasError && !snapshot.hasData) {
          return _buildPageStack(
            context,
            modalOpen: _profileModalUser != null,
            body: _UsersCrmErrorCard(
              collectionPath: 'users',
              error: snapshot.error,
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData &&
            _cachedRows == null) {
          return _buildPageStack(
            context,
            modalOpen: _profileModalUser != null,
            body: const _UsersCrmLoadingPanel(),
          );
        }

        if (snapshot.hasData) {
          _cachedRows = snapshot.data;
        }

        final sourceRows = snapshot.data ?? _cachedRows ?? const [];
        final users = filterAndSortUsers(
          rows: sourceRows,
          search: _search,
          statusFilter: _statusFilter,
          roleFilter: _roleFilter,
          cityFilter: _cityFilter,
          accountTypeFilter: _accountTypeFilter,
          sortColumn: _sortColumn,
          sortAscending: _sortAscending,
        );

        final totalPages = users.isEmpty
            ? 1
            : ((users.length - 1) ~/ _pageSize) + 1;
        final pageIndex = _pageIndex.clamp(0, totalPages - 1);
        final visibleUsers = users
            .skip(pageIndex * _pageSize)
            .take(_pageSize)
            .toList();

        final roleOptions = [
          'All',
          ...collectUserRoles(sourceRows).toList()..sort(),
        ];
        final cityOptions = [
          'All',
          ...collectUserCities(sourceRows).toList()..sort(),
        ];
        final accountTypeOptions = [
          'All',
          ...collectUserAccountTypes(sourceRows).toList()..sort(),
        ];

        final visibleIds = visibleUsers.map((user) => user.uid).toSet();
        final allVisibleSelected =
            visibleIds.isNotEmpty &&
            visibleIds.every(_selectedUserIds.contains);
        final someVisibleSelected =
            visibleIds.any(_selectedUserIds.contains) && !allVisibleSelected;

        final tableSection = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _UsersCrmToolbar(
              searchController: _searchController,
              statusFilter: _statusFilter,
              roleFilter: _roleFilter,
              cityFilter: _cityFilter,
              accountTypeFilter: _accountTypeFilter,
              sortPreset: _sortPresetLabel,
              roleOptions: roleOptions,
              cityOptions: cityOptions,
              accountTypeOptions: accountTypeOptions,
              hasActiveFilters: _hasActiveFilters,
              onSearchChanged: (value) => setState(() {
                _search = value;
                _pageIndex = 0;
              }),
              onStatusChanged: (value) => setState(() {
                _statusFilter = value;
                _pageIndex = 0;
              }),
              onRoleChanged: (value) => setState(() {
                _roleFilter = value;
                _pageIndex = 0;
              }),
              onCityChanged: (value) => setState(() {
                _cityFilter = value;
                _pageIndex = 0;
              }),
              onAccountTypeChanged: (value) => setState(() {
                _accountTypeFilter = value;
                _pageIndex = 0;
              }),
              onSortPresetChanged: _applyUserSortPreset,
              onClearFilters: _clearFilters,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_selectedUserIds.isNotEmpty) ...[
              _UsersCrmSelectionBanner(
                count: _selectedUserIds.length,
                onClear: () => setState(_selectedUserIds.clear),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (snapshot.hasError && snapshot.hasData)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _UsersCrmInlineErrorBanner(error: snapshot.error),
              ),
            _UsersCrmTable(
              users: visibleUsers,
              totalFilteredCount: users.length,
              selectedIds: _selectedUserIds,
              allVisibleSelected: allVisibleSelected,
              someVisibleSelected: someVisibleSelected,
              sortColumn: _sortColumn,
              sortAscending: _sortAscending,
              permissions: _crmPermissions,
              onColumnSort: _handleUserColumnSort,
              onSelectedChanged: _toggleUserSelection,
              onToggleSelectAllVisible: () =>
                  _toggleSelectAllVisible(visibleUsers),
              onAction: _handleAction,
            ),
            const SizedBox(height: AppSpacing.lg),
            _UsersCrmPaginationBar(
              pageIndex: pageIndex,
              totalPages: totalPages,
              visibleCount: visibleUsers.length,
              totalCount: users.length,
              onPrevious: pageIndex == 0
                  ? null
                  : () => setState(() => _pageIndex = pageIndex - 1),
              onNext: pageIndex >= totalPages - 1
                  ? null
                  : () => setState(() => _pageIndex = pageIndex + 1),
            ),
          ],
        );

        final modalOpen = _profileModalUser != null;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _refreshProfileOverlay(permissions: _crmPermissions);
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
    AdminUserCrmAction action,
  ) async {
    setState(() => _selectedUserIds.add(row.id));

    switch (action) {
      case AdminUserCrmAction.viewProfile:
        _openProfileModal(row);
        return;
      case AdminUserCrmAction.editUser:
        await _openEditDialog(row);
      case AdminUserCrmAction.suspend:
      case AdminUserCrmAction.unsuspend:
        await _toggleSuspend(row);
      case AdminUserCrmAction.restoreAccount:
        await _restoreAccount(row);
      case AdminUserCrmAction.emailUser:
        await _emailUser(row);
      case AdminUserCrmAction.deleteUser:
        await _deleteUser(row);
      case AdminUserCrmAction.sendVerificationEmail:
      case AdminUserCrmAction.forcePasswordReset:
      case AdminUserCrmAction.gdprExport:
      case AdminUserCrmAction.requestAccountDeletion:
        return;
    }
  }

  Future<void> _openEditDialog(AdminDocumentRow row) async {
    if (!_crmPermissions.canEditUser()) return;

    final result = await showDialog<_UserEditDraft>(
      context: context,
      builder: (context) => _UserEditDialog(user: AdminUserCrmView(row: row)),
    );
    if (result == null || !mounted) return;

    setState(() => _actionLoading = true);
    try {
      final updates = <String, dynamic>{
        'displayName': result.displayName,
        'name': result.displayName,
        'phone': result.phone,
        'city': result.city,
        'status': result.status,
        if (result.internalNotes.isNotEmpty)
          'internalNotes': result.internalNotes,
      };

      await widget.repository.updateDocument(
        path: 'users/${row.id}',
        updates: updates,
      );
      if (!mounted) return;
      _showSnack(context, 'User profile updated.');
    } on FirebaseException catch (error) {
      if (!mounted) return;
      _showSnack(
        context,
        'Could not save user: ${error.message ?? error.code}',
      );
    } on Object catch (error) {
      if (!mounted) return;
      _showSnack(context, 'Could not save user: $error');
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _toggleSuspend(AdminDocumentRow row) async {
    if (!_crmPermissions.canSuspend()) return;

    final user = AdminUserCrmView(row: row);
    final suspending = !user.isSuspended;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text(suspending ? 'Suspend user?' : 'Unsuspend user?'),
        content: Text(
          suspending
              ? 'This will set ${user.displayName} to suspended. They will not be deleted.'
              : 'This will restore ${user.displayName} to active status.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          DrinkSpotButton(
            label: suspending ? 'Suspend' : 'Unsuspend',
            compact: true,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final actorUid = AuthService.currentUser?.uid ?? 'unknown';
    setState(() => _actionLoading = true);
    try {
      if (suspending) {
        await widget.repository.suspendUser(uid: row.id, suspendedBy: actorUid);
      } else {
        await widget.repository.unsuspendUser(
          uid: row.id,
          unsuspendedBy: actorUid,
        );
      }
      if (!mounted) return;
      _showSnack(context, suspending ? 'User suspended.' : 'User unsuspended.');
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

  Future<void> _restoreAccount(AdminDocumentRow row) async {
    if (!_crmPermissions.canEditUser()) return;

    final user = AdminUserCrmView(row: row);
    if (!user.needsRestore) {
      _showSnack(context, 'This account is already active.');
      return;
    }

    setState(() => _actionLoading = true);
    try {
      final actorUid = AuthService.currentUser?.uid ?? 'unknown';
      await widget.repository.restoreUserAccount(
        uid: row.id,
        restoredBy: actorUid,
      );
      if (!mounted) return;
      _showSnack(context, '${user.displayName} account restored.');
    } on FirebaseException catch (error) {
      if (!mounted) return;
      _showSnack(
        context,
        'Could not restore account: ${error.message ?? error.code}',
      );
    } on Object catch (error) {
      if (!mounted) return;
      _showSnack(context, 'Could not restore account: $error');
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _emailUser(AdminDocumentRow row) async {
    if (!_crmPermissions.canEditUser()) return;

    final user = AdminUserCrmView(row: row);
    if (!user.hasEmail) return;

    final uri = Uri(scheme: 'mailto', path: user.email.trim());
    try {
      final opened = await launchUrl(uri);
      if (!mounted) return;
      if (!opened) {
        _showSnack(context, 'Could not open email client.');
      }
    } on Object catch (error) {
      if (!mounted) return;
      _showSnack(context, 'Could not open email client: $error');
    }
  }

  Future<void> _deleteUser(AdminDocumentRow row) async {
    if (!_crmPermissions.canDeleteActions()) return;

    final currentUid = AuthService.currentUser?.uid;
    if (currentUid != null && row.id == currentUid) {
      _showSnack(context, 'You cannot delete your own account.');
      return;
    }

    final user = AdminUserCrmView(row: row);
    if (user.isStaffAdminRole) {
      final adminCount = countActiveStaffAdminUsers(_cachedRows ?? const []);
      if (adminCount <= 1) {
        _showSnack(context, 'Cannot delete the last remaining admin account.');
        return;
      }
    }

    final result = await showDialog<({bool confirmed, String? reason})>(
      context: context,
      builder: (dialogContext) => _UserDeleteDialog(
        displayName: user.displayName,
        email: user.hasEmail ? user.email : null,
      ),
    );
    if (result == null || !result.confirmed || !mounted) return;

    final actorUid = AuthService.currentUser?.uid ?? 'unknown';
    setState(() => _actionLoading = true);
    try {
      await widget.repository.archiveAndRemoveUser(
        uid: row.id,
        deletedBy: actorUid,
        deleteReason: result.reason,
      );
      if (!mounted) return;
      setState(() {
        _selectedUserIds.remove(row.id);
        if (_profileModalUser?.id == row.id) {
          _profileModalUser = null;
        }
      });
      _removeProfileOverlay();
      _showSnack(
        context,
        '${user.displayName} archived and removed from active users.',
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      _showSnack(
        context,
        'Could not delete user: ${error.message ?? error.code}',
      );
    } on Object catch (error) {
      if (!mounted) return;
      _showSnack(context, 'Could not delete user: $error');
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  void _openProfileModal(AdminDocumentRow row) {
    setState(() {
      _selectedUserIds.add(row.id);
      _profileModalUser = row;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _profileModalUser == null) return;
      _showProfileOverlay(permissions: _crmPermissions);
    });
  }

  void _closeProfileModal() {
    _removeProfileOverlay();
    if (mounted) {
      setState(() => _profileModalUser = null);
    }
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _UsersCrmToolbar extends StatelessWidget {
  const _UsersCrmToolbar({
    required this.searchController,
    required this.statusFilter,
    required this.roleFilter,
    required this.cityFilter,
    required this.accountTypeFilter,
    required this.sortPreset,
    required this.roleOptions,
    required this.cityOptions,
    required this.accountTypeOptions,
    required this.hasActiveFilters,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onRoleChanged,
    required this.onCityChanged,
    required this.onAccountTypeChanged,
    required this.onSortPresetChanged,
    required this.onClearFilters,
  });

  final TextEditingController searchController;
  final String statusFilter;
  final String roleFilter;
  final String cityFilter;
  final String accountTypeFilter;
  final String sortPreset;
  final List<String> roleOptions;
  final List<String> cityOptions;
  final List<String> accountTypeOptions;
  final bool hasActiveFilters;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<String> onCityChanged;
  final ValueChanged<String> onAccountTypeChanged;
  final ValueChanged<String> onSortPresetChanged;
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

          const filterCount = 5;
          final fieldsPerRow = available >= 1100
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
              height: _UsersCrmToolbarMetrics.controlHeight,
              child: child,
            );
          }

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                height: _UsersCrmToolbarMetrics.controlHeight,
                width: searchWidth,
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  style: _UsersCrmToolbarMetrics.fieldTextStyle,
                  strutStyle: const StrutStyle(
                    fontSize: 13,
                    height: 1.15,
                    forceStrutHeight: true,
                  ),
                  decoration: _UsersCrmToolbarMetrics.searchDecoration(),
                ),
              ),
              filterField(
                _UsersCrmDropdown(
                  label: 'Role',
                  compact: true,
                  value: roleFilter,
                  values: roleOptions,
                  onChanged: onRoleChanged,
                ),
              ),
              filterField(
                _UsersCrmDropdown(
                  label: 'Status',
                  compact: true,
                  value: statusFilter,
                  values: const [
                    'All',
                    'active',
                    'suspended',
                    'pending',
                    'guest',
                    'deletion requested',
                  ],
                  onChanged: onStatusChanged,
                ),
              ),
              filterField(
                _UsersCrmDropdown(
                  label: 'Location',
                  compact: true,
                  value: cityFilter,
                  values: cityOptions,
                  onChanged: onCityChanged,
                ),
              ),
              if (accountTypeOptions.length > 1)
                filterField(
                  _UsersCrmDropdown(
                    label: 'Account type',
                    compact: true,
                    value: accountTypeFilter,
                    values: accountTypeOptions,
                    onChanged: onAccountTypeChanged,
                  ),
                ),
              filterField(
                _UsersCrmDropdown(
                  label: 'Sort',
                  compact: true,
                  value: sortPreset,
                  values: const ['Newest', 'Oldest', 'Name', 'Last active'],
                  onChanged: onSortPresetChanged,
                ),
              ),
              if (hasActiveFilters)
                SizedBox(
                  height: _UsersCrmToolbarMetrics.controlHeight,
                  child: DrinkSpotButton(
                    label: 'Clear filters',
                    compact: true,
                    variant: DrinkSpotButtonVariant.ghost,
                    onPressed: onClearFilters,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

abstract final class _UsersCrmToolbarMetrics {
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
      hintText: 'Search name, email, city or role',
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

class _UsersCrmTable extends StatelessWidget {
  const _UsersCrmTable({
    required this.users,
    required this.totalFilteredCount,
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

  final List<AdminUserCrmView> users;
  final int totalFilteredCount;
  final Set<String> selectedIds;
  final bool allVisibleSelected;
  final bool someVisibleSelected;
  final String sortColumn;
  final bool sortAscending;
  final AdminUserCrmPermissions permissions;
  final ValueChanged<String> onColumnSort;
  final void Function(String userId, bool selected) onSelectedChanged;
  final VoidCallback onToggleSelectAllVisible;
  final void Function(AdminDocumentRow row, AdminUserCrmAction action) onAction;

  DataColumn _sortableColumn(String label, String columnKey) {
    return adminCrmSortableDataColumn(
      label: label,
      columnKey: columnKey,
      activeColumnKey: sortColumn,
      ascending: sortAscending,
      onSort: onColumnSort,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const VenuePageSection(
        title: 'No users found',
        child: Text(
          'No user records match the current search and filters.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return VenuePageSection(
      title: 'User Management',
      trailing: Text(
        '$totalFilteredCount total · ${users.length} on this page',
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
            _sortableColumn('Name', AdminUserTableSortColumn.name),
            _sortableColumn('Email', AdminUserTableSortColumn.email),
            _sortableColumn('Role', AdminUserTableSortColumn.role),
            _sortableColumn('Status', AdminUserTableSortColumn.status),
            _sortableColumn('Location', AdminUserTableSortColumn.city),
            _sortableColumn('Created', AdminUserTableSortColumn.created),
            _sortableColumn('Last Login', AdminUserTableSortColumn.lastLogin),
            _sortableColumn(
              'Saved Venues',
              AdminUserTableSortColumn.savedVenues,
            ),
            const DataColumn(label: Text('Actions')),
          ],
          rows: users.map((user) {
            final isSelected = selectedIds.contains(user.uid);
            return DataRow(
              selected: isSelected,
              cells: [
                DataCell(
                  Checkbox(
                    value: isSelected,
                    onChanged: (selected) {
                      onSelectedChanged(user.uid, selected == true);
                    },
                    visualDensity: VisualDensity.compact,
                    activeColor: AppColors.primaryPurple,
                    side: BorderSide(
                      color: AppColors.primaryPurple.withValues(alpha: 0.45),
                    ),
                  ),
                ),
                DataCell(Text(user.displayName)),
                DataCell(Text(user.email)),
                DataCell(Text(user.role)),
                DataCell(_UsersCrmStatusChip(label: user.statusLabel)),
                DataCell(Text(user.city)),
                DataCell(Text(user.createdAt)),
                DataCell(_UsersCrmLastLoginCell(label: user.lastLoginLabel)),
                DataCell(Text(user.savedVenuesCountLabel ?? '—')),
                DataCell(
                  _UsersCrmInlineActions(
                    user: user,
                    permissions: permissions,
                    onAction: (action) => onAction(user.row, action),
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

class _UsersCrmLastLoginCell extends StatelessWidget {
  const _UsersCrmLastLoginCell({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isMissing = label == 'Never' || label == 'Not recorded';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isMissing ? Icons.schedule_outlined : Icons.login_rounded,
          size: 15,
          color: AppColors.textSecondary.withValues(alpha: 0.9),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: isMissing
                ? AppColors.textSecondary.withValues(alpha: 0.92)
                : AppColors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _UsersCrmSelectionBanner extends StatelessWidget {
  const _UsersCrmSelectionBanner({required this.count, required this.onClear});

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
              '$count user${count == 1 ? '' : 's'} selected',
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

class _UsersCrmInlineActions extends StatelessWidget {
  const _UsersCrmInlineActions({
    required this.user,
    required this.permissions,
    required this.onAction,
  });

  final AdminUserCrmView user;
  final AdminUserCrmPermissions permissions;
  final ValueChanged<AdminUserCrmAction> onAction;

  @override
  Widget build(BuildContext context) {
    final actions =
        <
          ({
            AdminUserCrmAction action,
            IconData icon,
            String label,
            bool backendTodo,
            bool enabled,
            String? tooltipOverride,
          })
        >[
          (
            action: AdminUserCrmAction.viewProfile,
            icon: Icons.badge_outlined,
            label: 'View User Profile',
            backendTodo: false,
            enabled: true,
            tooltipOverride: null,
          ),
          (
            action: AdminUserCrmAction.editUser,
            icon: Icons.edit_rounded,
            label: 'Edit User',
            backendTodo: false,
            enabled: true,
            tooltipOverride: null,
          ),
          (
            action: user.isSuspended
                ? AdminUserCrmAction.unsuspend
                : AdminUserCrmAction.suspend,
            icon: user.isSuspended
                ? Icons.lock_open_rounded
                : Icons.block_rounded,
            label: user.isSuspended ? 'Unsuspend' : 'Suspend',
            backendTodo: false,
            enabled: true,
            tooltipOverride: null,
          ),
          (
            action: AdminUserCrmAction.restoreAccount,
            icon: Icons.restore_rounded,
            label: 'Restore Account',
            backendTodo: false,
            enabled: user.needsRestore,
            tooltipOverride: null,
          ),
          (
            action: AdminUserCrmAction.emailUser,
            icon: Icons.mail_outline_rounded,
            label: 'Email User',
            backendTodo: false,
            enabled: user.hasEmail,
            tooltipOverride: user.hasEmail ? null : 'No email available',
          ),
          (
            action: AdminUserCrmAction.deleteUser,
            icon: Icons.delete_forever_rounded,
            label: 'Delete User',
            backendTodo: false,
            enabled: true,
            tooltipOverride: null,
          ),
        ];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              _UsersCrmInlineActionIcon(
                action: actions[i].action,
                icon: actions[i].icon,
                label: actions[i].label,
                backendTodo: actions[i].backendTodo,
                actionEnabled: actions[i].enabled,
                tooltipOverride: actions[i].tooltipOverride,
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

class _UsersCrmInlineActionIcon extends StatelessWidget {
  const _UsersCrmInlineActionIcon({
    required this.action,
    required this.icon,
    required this.label,
    required this.backendTodo,
    required this.actionEnabled,
    required this.permissions,
    required this.onPressed,
    this.tooltipOverride,
  });

  final AdminUserCrmAction action;
  final IconData icon;
  final String label;
  final bool backendTodo;
  final bool actionEnabled;
  final String? tooltipOverride;
  final AdminUserCrmPermissions permissions;
  final VoidCallback onPressed;

  String get _tooltip {
    if (tooltipOverride != null) return tooltipOverride!;
    if (backendTodo) return kAdminUserBackendRequiredTooltip;
    final denied = permissions.menuSubtitleFor(action, backendTodo: false);
    if (denied != null) return denied;
    return permissions.tooltipFor(action, isBackendTodo: false);
  }

  @override
  Widget build(BuildContext context) {
    final allowed = permissions.isActionAllowed(action);
    final enabled = allowed && !backendTodo && actionEnabled;

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
              ? AppColors.primaryPink.withValues(alpha: 0.9)
              : AppColors.textSecondary.withValues(alpha: 0.42),
          backgroundColor: enabled
              ? AppColors.primaryPurple.withValues(alpha: 0.12)
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            side: BorderSide(
              color: enabled
                  ? AppColors.primaryPurple.withValues(alpha: 0.22)
                  : AppColors.textSecondary.withValues(alpha: 0.12),
            ),
          ),
        ),
        onPressed: enabled ? onPressed : null,
      ),
    );
  }
}

class _UsersCrmProfileModalOverlay extends StatelessWidget {
  const _UsersCrmProfileModalOverlay({
    super.key,
    required this.user,
    required this.repository,
    required this.permissions,
    required this.actionLoading,
    required this.onClose,
    required this.onEdit,
    required this.onSuspendToggle,
  });

  final AdminDocumentRow user;
  final AdminDashboardRepository repository;
  final AdminUserCrmPermissions permissions;
  final bool actionLoading;
  final VoidCallback onClose;
  final VoidCallback onEdit;
  final VoidCallback onSuspendToggle;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final modalWidth = (screenSize.width - 48).clamp(320.0, 1050.0);
    final modalMaxHeight = screenSize.height * 0.85;

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): _CloseUsersCrmModalIntent(),
      },
      child: Actions(
        actions: {
          _CloseUsersCrmModalIntent: CallbackAction<_CloseUsersCrmModalIntent>(
            onInvoke: (_) {
              onClose();
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
                  onTap: onClose,
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
                          child: _UsersCrmProfileModalBody(
                            user: user,
                            repository: repository,
                            permissions: permissions,
                            actionLoading: actionLoading,
                            onClose: onClose,
                            onEdit: onEdit,
                            onSuspendToggle: onSuspendToggle,
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

class _CloseUsersCrmModalIntent extends Intent {
  const _CloseUsersCrmModalIntent();
}

class _UsersCrmProfileModalBody extends StatefulWidget {
  const _UsersCrmProfileModalBody({
    required this.user,
    required this.repository,
    required this.permissions,
    required this.actionLoading,
    required this.onClose,
    required this.onEdit,
    required this.onSuspendToggle,
  });

  final AdminDocumentRow user;
  final AdminDashboardRepository repository;
  final AdminUserCrmPermissions permissions;
  final bool actionLoading;
  final VoidCallback onClose;
  final VoidCallback onEdit;
  final VoidCallback onSuspendToggle;

  @override
  State<_UsersCrmProfileModalBody> createState() =>
      _UsersCrmProfileModalBodyState();
}

class _UsersCrmProfileModalBodyState extends State<_UsersCrmProfileModalBody> {
  static final Map<String, AdminUserSupplementaryData> _supplementaryCache = {};
  static final Map<String, Future<AdminUserSupplementaryData>> _inFlightLoads =
      {};

  AdminUserSupplementaryData? _supplementary;
  bool _loadingSupplementary = false;
  String? _activeUid;

  @override
  void initState() {
    super.initState();
    _syncUser(widget.user.id, notify: false);
  }

  @override
  void didUpdateWidget(covariant _UsersCrmProfileModalBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.id != widget.user.id) {
      _syncUser(widget.user.id);
    }
  }

  void _syncUser(String uid, {bool notify = true}) {
    _activeUid = uid;

    final cached = _supplementaryCache[uid];
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
    _loadSupplementary(uid);
  }

  Future<void> _loadSupplementary(String uid) async {
    final future = _inFlightLoads.putIfAbsent(
      uid,
      () => _fetchSupplementary(uid),
    );
    try {
      final data = await future;
      _supplementaryCache[uid] = data;
      if (!mounted || _activeUid != uid) return;
      setState(() {
        _supplementary = data;
        _loadingSupplementary = false;
      });
    } finally {
      _inFlightLoads.remove(uid);
    }
  }

  Future<AdminUserSupplementaryData> _fetchSupplementary(String uid) async {
    final profile = AdminUserCrmView(row: widget.user);
    final favouritesResult = await widget.repository.fetchUserFavouritesResult(
      uid,
    );
    final deletionRequest = await widget.repository.fetchAccountDeletionRequest(
      uid,
    );
    final reports = await widget.repository.fetchReportsForUser(uid);

    AdminUserVenueOwnerContext? venueOwner;
    AdminUserArtistContext? artist;
    if (profile.shouldLoadVenueOwnerContext) {
      venueOwner = await widget.repository.fetchUserVenueOwnerContext(
        uid,
        userData: widget.user.data,
      );
    }
    if (profile.shouldLoadArtistContext) {
      artist = await widget.repository.fetchUserArtistProfileContext(uid);
    }

    return AdminUserSupplementaryData(
      favouritesResult: favouritesResult,
      deletionRequest: deletionRequest,
      reports: reports,
      venueOwner: venueOwner,
      artist: artist,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = AdminUserCrmView(row: widget.user);
    final supplementary = _supplementary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _UsersCrmProfileModalHeader(profile: profile, onClose: widget.onClose),
        if (widget.actionLoading) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildOverviewContextSection(profile, supplementary),
                const SizedBox(height: AppSpacing.lg),
                _UsersCrmSection(
                  title: 'Account Management',
                  child: _UsersCrmAccountActions(
                    user: profile,
                    permissions: widget.permissions,
                    onEdit: widget.onEdit,
                    onSuspendToggle: widget.onSuspendToggle,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _UsersCrmSection(
                  title: 'Saved Content',
                  child: _buildSavedContent(profile, supplementary),
                ),
                const SizedBox(height: AppSpacing.lg),
                _UsersCrmSection(
                  title: 'Activity',
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent searches — TODO',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        'Recently viewed venues — TODO',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        'Trail progress — TODO',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        'Event attendance — TODO',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _UsersCrmSection(
                  title: 'Notifications',
                  child: _buildNotifications(profile),
                ),
                const SizedBox(height: AppSpacing.lg),
                _UsersCrmSection(
                  title: 'Support & Moderation',
                  child: _buildSupportSection(profile, supplementary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewContextSection(
    AdminUserCrmView profile,
    AdminUserSupplementaryData? supplementary,
  ) {
    final overview = _UsersCrmSection(
      title: 'Overview',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _UsersCrmContextLine(
            label: 'Display name',
            value: profile.displayName,
          ),
          _UsersCrmContextLine(label: 'Email', value: profile.email),
          _UsersCrmContextLine(label: 'Phone', value: profile.phone),
          _UsersCrmContextLine(label: 'City', value: profile.city),
          _UsersCrmContextLine(label: 'Role', value: profile.role),
          _UsersCrmContextLine(label: 'Status', value: profile.statusLabel),
          _UsersCrmContextLine(label: 'Created', value: profile.createdAt),
          _UsersCrmContextLine(
            label: 'Last login',
            value: profile.lastLoginLabel,
          ),
          _UsersCrmContextLine(label: 'UID', value: profile.uid),
        ],
      ),
    );

    final contextCard = _UsersCrmContextCard(
      profile: profile,
      supplementary: supplementary,
      loading: _loadingSupplementary && supplementary == null,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide = constraints.maxWidth >= 760;
        if (!sideBySide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              overview,
              const SizedBox(height: AppSpacing.lg),
              contextCard,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: overview),
            const SizedBox(width: AppSpacing.lg),
            Expanded(child: contextCard),
          ],
        );
      },
    );
  }

  Widget _buildSavedContent(
    AdminUserCrmView profile,
    AdminUserSupplementaryData? supplementary,
  ) {
    if (_loadingSupplementary && supplementary == null) {
      return const Text(
        'Loading saved content…',
        style: TextStyle(color: AppColors.textSecondary),
      );
    }

    if (supplementary?.favouritesUnavailable == true) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saved content unavailable',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Admin access to this user\'s favourites has not yet been enabled.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.45),
          ),
        ],
      );
    }

    final favouritesCount =
        supplementary?.favourites.length ?? profile.savedVenuesCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _UsersCrmContextLine(
          label: 'Saved venues',
          value: favouritesCount?.toString() ?? '—',
        ),
        if (supplementary != null && supplementary.favourites.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          for (final favourite in supplementary.favourites.take(5))
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                bottom: AppSpacing.xs,
              ),
              child: Text(
                '• ${favourite.readString(['venueName', 'name'])}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                ),
              ),
            ),
        ],
        const SizedBox(height: AppSpacing.sm),
        const _UsersCrmContextLine(
          label: 'Favourite drinks',
          value: 'Not tracked yet.',
        ),
        const _UsersCrmContextLine(
          label: 'Favourite deals',
          value: 'Not tracked yet.',
        ),
        const _UsersCrmContextLine(
          label: 'Favourite events',
          value: 'Not tracked yet.',
        ),
        const _UsersCrmContextLine(
          label: 'Favourite trails',
          value: 'Not tracked yet.',
        ),
      ],
    );
  }

  Widget _buildNotifications(AdminUserCrmView profile) {
    final prefs = profile.notificationPreferences;
    if (prefs == null || prefs.isEmpty) {
      return const Text(
        'Notification preferences not available yet.',
        style: TextStyle(color: AppColors.textSecondary, height: 1.45),
      );
    }

    final pushEnabled =
        prefs['pushDeals'] == true || prefs['pushEvents'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _UsersCrmContextLine(
          label: 'Push enabled',
          value: pushEnabled ? 'Enabled' : 'Disabled',
        ),
        _UsersCrmContextLine(
          label: 'Email enabled',
          value: prefs['emailUpdates'] == true ? 'Enabled' : 'Disabled',
        ),
        _UsersCrmContextLine(
          label: 'Marketing opt-in',
          value: prefs['marketingOptIn'] == true ? 'Enabled' : 'Disabled',
        ),
        _UsersCrmContextLine(
          label: 'Last notification sent',
          value: profile.readDate(['lastNotificationSentAt']),
        ),
      ],
    );
  }

  Widget _buildSupportSection(
    AdminUserCrmView profile,
    AdminUserSupplementaryData? supplementary,
  ) {
    final deletion = supplementary?.deletionRequest;
    final reports = supplementary?.reports ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (reports.isNotEmpty) ...[
          Text(
            'Reports (${reports.length})',
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final report in reports.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                '• ${report.readString(['reason', 'type', 'status'])}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
        ] else
          const _UsersCrmContextLine(
            label: 'Reports',
            value: 'No linked reports found.',
          ),
        const SizedBox(height: AppSpacing.md),
        if (deletion != null) ...[
          _UsersCrmContextLine(
            label: 'Deletion request',
            value: deletion['status']?.toString() ?? 'pending',
          ),
          const SizedBox(height: AppSpacing.sm),
          Tooltip(
            message: widget.permissions.canDeleteActions()
                ? 'View deletion request'
                : kAdminPermissionDeniedTooltip,
            child: DrinkSpotButton(
              label: 'View Request',
              icon: Icons.delete_outline_rounded,
              compact: true,
              variant: DrinkSpotButtonVariant.secondary,
              onPressed: widget.permissions.canDeleteActions() ? () {} : null,
            ),
          ),
        ] else if (profile.deletionRequested)
          const _UsersCrmContextLine(
            label: 'Deletion request',
            value: 'Requested on user profile.',
          )
        else
          const _UsersCrmContextLine(
            label: 'Deletion request',
            value: 'No account deletion request on file.',
          ),
        const SizedBox(height: AppSpacing.md),
        _UsersCrmContextLine(
          label: 'Internal notes',
          value: profile.internalNotes,
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Warnings — TODO',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Support history — TODO',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _UsersCrmProfileModalHeader extends StatelessWidget {
  const _UsersCrmProfileModalHeader({
    required this.profile,
    required this.onClose,
  });

  final AdminUserCrmView profile;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
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
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.brandGradient,
            ),
            child: Center(
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
                  profile.displayName,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  profile.email,
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
                    _UsersCrmStatusChip(label: profile.statusLabel),
                    _UsersCrmRoleChip(label: profile.role),
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

class _UsersCrmRoleChip extends StatelessWidget {
  const _UsersCrmRoleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: AppColors.primaryPurple.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primaryPurple,
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
        ),
      ),
    );
  }
}

class _UsersCrmContextCard extends StatelessWidget {
  const _UsersCrmContextCard({
    required this.profile,
    required this.supplementary,
    required this.loading,
  });

  final AdminUserCrmView profile;
  final AdminUserSupplementaryData? supplementary;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const _UsersCrmSection(
        title: 'Profile Context',
        child: Text(
          'Loading profile context…',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final contextType = profile.resolveContextType(supplementary);
    return switch (contextType) {
      AdminUserCrmContextType.venueOwner => _UsersCrmVenueOwnerCard(
        profile: profile,
        ownerContext: supplementary?.venueOwner,
      ),
      AdminUserCrmContextType.artist => _UsersCrmArtistCard(
        profile: profile,
        artistContext: supplementary?.artist,
      ),
      AdminUserCrmContextType.customer => _UsersCrmCustomerCard(
        profile: profile,
        supplementary: supplementary,
      ),
    };
  }
}

class _UsersCrmVenueOwnerCard extends StatelessWidget {
  const _UsersCrmVenueOwnerCard({
    required this.profile,
    required this.ownerContext,
  });

  final AdminUserCrmView profile;
  final AdminUserVenueOwnerContext? ownerContext;

  @override
  Widget build(BuildContext context) {
    final owner = ownerContext;
    if (owner?.unavailable == true) {
      return const _UsersCrmSection(
        title: 'Venue Owner',
        child: Text(
          'Venue data unavailable for admin access yet.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.45),
        ),
      );
    }

    if (owner == null || owner.ownedVenuesCount == 0) {
      return const _UsersCrmSection(
        title: 'Venue Owner',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Venue owner profile detected.',
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Venue details are not loaded yet. TODO: connect venue lookup.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.45),
            ),
          ],
        ),
      );
    }

    return _UsersCrmSection(
      title: 'Venue Owner',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _UsersCrmContextLine(
            label: 'Owned venues',
            value: owner.ownedVenuesCount.toString(),
          ),
          _UsersCrmContextLine(
            label: 'Primary venue',
            value: owner.primaryVenueName,
          ),
          _UsersCrmContextLine(
            label: 'Venue status',
            value: owner.primaryVenueStatus,
          ),
          _UsersCrmContextLine(
            label: 'Claimed / verified',
            value: owner.claimedVerifiedLabel,
          ),
          _UsersCrmContextLine(
            label: 'Subscription tier',
            value: owner.subscriptionTier,
          ),
          _UsersCrmContextLine(
            label: 'Subscription status',
            value: owner.subscriptionStatus,
          ),
          _UsersCrmContextLine(
            label: 'Drinks',
            value: owner.drinksCount?.toString() ?? '—',
          ),
          _UsersCrmContextLine(
            label: 'Deals',
            value: owner.dealsCount?.toString() ?? '—',
          ),
          _UsersCrmContextLine(
            label: 'Events',
            value: owner.eventsCount?.toString() ?? '—',
          ),
          _UsersCrmContextLine(
            label: 'Last venue update',
            value: owner.lastVenueUpdate,
          ),
          const SizedBox(height: AppSpacing.md),
          _UsersCrmContextQuickActions(
            actions: const [
              _UsersCrmQuickAction(
                label: 'Open Venue',
                icon: Icons.storefront_outlined,
              ),
              _UsersCrmQuickAction(
                label: 'Open Public Venue',
                icon: Icons.public_outlined,
              ),
              _UsersCrmQuickAction(
                label: 'View Subscription',
                icon: Icons.workspace_premium_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UsersCrmArtistCard extends StatelessWidget {
  const _UsersCrmArtistCard({
    required this.profile,
    required this.artistContext,
  });

  final AdminUserCrmView profile;
  final AdminUserArtistContext? artistContext;

  @override
  Widget build(BuildContext context) {
    final artist = artistContext;
    if (artist?.unavailable == true) {
      return const _UsersCrmSection(
        title: 'Artist Profile',
        child: Text(
          'Artist data unavailable for admin access yet.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.45),
        ),
      );
    }

    if (artist == null || !artist.hasProfile) {
      return _UsersCrmSection(
        title: 'Artist Profile',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              profile.isArtistRole
                  ? 'Artist role assigned.'
                  : 'No artist profile linked.',
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Not available yet.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.45),
            ),
          ],
        ),
      );
    }

    return _UsersCrmSection(
      title: 'Artist Profile',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _UsersCrmContextLine(label: 'Artist name', value: artist.artistName),
          _UsersCrmContextLine(label: 'Genre', value: artist.genre),
          _UsersCrmContextLine(
            label: 'Profile status',
            value: artist.profileStatus,
          ),
          _UsersCrmContextLine(
            label: 'Verification',
            value: artist.verificationStatus,
          ),
          _UsersCrmContextLine(
            label: 'Linked venues/events',
            value: artist.linkedCountLabel,
          ),
          _UsersCrmContextLine(
            label: 'Contact email',
            value: artist.contactEmail,
          ),
          _UsersCrmContextLine(
            label: 'Website / social',
            value: artist.websiteOrSocial,
          ),
          _UsersCrmContextLine(
            label: 'Last updated',
            value: artist.lastUpdated,
          ),
          const SizedBox(height: AppSpacing.md),
          _UsersCrmContextQuickActions(
            actions: const [
              _UsersCrmQuickAction(
                label: 'Open Artist Profile',
                icon: Icons.person_outline_rounded,
              ),
              _UsersCrmQuickAction(
                label: 'View Events',
                icon: Icons.event_outlined,
              ),
              _UsersCrmQuickAction(
                label: 'Verify Artist',
                icon: Icons.verified_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UsersCrmCustomerCard extends StatelessWidget {
  const _UsersCrmCustomerCard({
    required this.profile,
    required this.supplementary,
  });

  final AdminUserCrmView profile;
  final AdminUserSupplementaryData? supplementary;

  @override
  Widget build(BuildContext context) {
    final favouritesUnavailable = supplementary?.favouritesUnavailable ?? false;
    final savedCount =
        supplementary?.favourites.length ?? profile.savedVenuesCount;

    final favouriteStatus = favouritesUnavailable
        ? 'Saved content unavailable'
        : savedCount == null
        ? 'Not available yet'
        : '$savedCount saved venue${savedCount == 1 ? '' : 's'}';

    final pushEnabled =
        profile.notificationPreferences?['pushDeals'] == true ||
        profile.notificationPreferences?['pushEvents'] == true;
    final emailEnabled =
        profile.notificationPreferences?['emailUpdates'] == true;
    final marketingOptIn =
        profile.notificationPreferences?['marketingOptIn'] == true;

    final notificationSummary =
        profile.notificationPreferences == null ||
            profile.notificationPreferences!.isEmpty
        ? 'Not available yet'
        : 'Push ${pushEnabled ? 'on' : 'off'} · '
              'Email ${emailEnabled ? 'on' : 'off'} · '
              'Marketing ${marketingOptIn ? 'on' : 'off'}';

    return _UsersCrmSection(
      title: 'Customer Profile',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _UsersCrmContextLine(
            label: 'Saved venues',
            value: savedCount?.toString() ?? '—',
          ),
          _UsersCrmContextLine(
            label: 'Favourite content',
            value: favouriteStatus,
          ),
          if (favouritesUnavailable) ...[
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Admin access to favourites has not yet been enabled.',
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.45,
                fontSize: 12.5,
              ),
            ),
          ],
          _UsersCrmContextLine(
            label: 'Notifications',
            value: notificationSummary,
          ),
          _UsersCrmContextLine(label: 'Account age', value: profile.createdAt),
          _UsersCrmContextLine(label: 'Last active', value: profile.lastActive),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Recent activity — TODO',
            style: TextStyle(color: AppColors.textSecondary, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _UsersCrmQuickAction {
  const _UsersCrmQuickAction({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _UsersCrmContextQuickActions extends StatelessWidget {
  const _UsersCrmContextQuickActions({required this.actions});

  final List<_UsersCrmQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: actions
          .map(
            (action) => Tooltip(
              message: kAdminUserBackendRequiredTooltip,
              child: DrinkSpotButton(
                label: action.label,
                icon: action.icon,
                compact: true,
                variant: DrinkSpotButtonVariant.ghost,
                onPressed: null,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _UsersCrmAccountActions extends StatelessWidget {
  const _UsersCrmAccountActions({
    required this.user,
    required this.permissions,
    required this.onEdit,
    required this.onSuspendToggle,
  });

  final AdminUserCrmView user;
  final AdminUserCrmPermissions permissions;
  final VoidCallback? onEdit;
  final VoidCallback? onSuspendToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _actionButton(
          label: 'Edit User',
          icon: Icons.edit_rounded,
          action: AdminUserCrmAction.editUser,
          backendTodo: false,
          onPressed: permissions.canEditUser() ? onEdit : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        _actionButton(
          label: user.isSuspended ? 'Unsuspend' : 'Suspend',
          icon: user.isSuspended
              ? Icons.lock_open_rounded
              : Icons.block_rounded,
          action: user.isSuspended
              ? AdminUserCrmAction.unsuspend
              : AdminUserCrmAction.suspend,
          backendTodo: false,
          onPressed: permissions.canSuspend() ? onSuspendToggle : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        _actionButton(
          label: 'Force Password Reset',
          icon: Icons.password_rounded,
          action: AdminUserCrmAction.forcePasswordReset,
          backendTodo: true,
          onPressed: null,
        ),
        const SizedBox(height: AppSpacing.sm),
        _actionButton(
          label: 'Send Verification Email',
          icon: Icons.mark_email_unread_rounded,
          action: AdminUserCrmAction.sendVerificationEmail,
          backendTodo: true,
          onPressed: null,
        ),
        const SizedBox(height: AppSpacing.sm),
        _actionButton(
          label: 'GDPR Export',
          icon: Icons.download_rounded,
          action: AdminUserCrmAction.gdprExport,
          backendTodo: true,
          onPressed: null,
        ),
        const SizedBox(height: AppSpacing.sm),
        _actionButton(
          label: 'Request Deletion',
          icon: Icons.delete_forever_rounded,
          action: AdminUserCrmAction.requestAccountDeletion,
          backendTodo: true,
          onPressed: null,
        ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required AdminUserCrmAction action,
    required bool backendTodo,
    required VoidCallback? onPressed,
  }) {
    final allowed = permissions.isActionAllowed(action);
    final enabled = allowed && !backendTodo && onPressed != null;
    final subtitle = permissions.menuSubtitleFor(
      action,
      backendTodo: backendTodo,
    );

    if (enabled) {
      return DrinkSpotButton(
        label: label,
        icon: icon,
        compact: true,
        variant: DrinkSpotButtonVariant.secondary,
        onPressed: onPressed,
      );
    }

    return _UsersCrmDisabledActionTile(
      label: label,
      icon: icon,
      subtitle: subtitle ?? kAdminPermissionDeniedTooltip,
      isBackendTodo: backendTodo,
    );
  }
}

class _UsersCrmDisabledActionTile extends StatelessWidget {
  const _UsersCrmDisabledActionTile({
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

class _UserEditDraft {
  const _UserEditDraft({
    required this.displayName,
    required this.phone,
    required this.city,
    required this.status,
    required this.internalNotes,
  });

  final String displayName;
  final String phone;
  final String city;
  final String status;
  final String internalNotes;
}

class _UserEditDialog extends StatefulWidget {
  const _UserEditDialog({required this.user});

  final AdminUserCrmView user;

  @override
  State<_UserEditDialog> createState() => _UserEditDialogState();
}

class _UserEditDialogState extends State<_UserEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cityController;
  late final TextEditingController _notesController;
  late String _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _nameController = TextEditingController(text: user.displayName);
    _phoneController = TextEditingController(
      text: user.phone == '—' ? '' : user.phone,
    );
    _cityController = TextEditingController(
      text: user.city == '—' ? '' : user.city,
    );
    _notesController = TextEditingController(
      text: user.internalNotes == '—' ? '' : user.internalNotes,
    );
    _status = user.status == '—' ? 'active' : user.status;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: GlassContainer(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Edit User',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.user.email,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              _UsersCrmTextField(
                controller: _nameController,
                label: 'Display name',
              ),
              const SizedBox(height: AppSpacing.md),
              _UsersCrmTextField(controller: _phoneController, label: 'Phone'),
              const SizedBox(height: AppSpacing.md),
              _UsersCrmTextField(controller: _cityController, label: 'City'),
              const SizedBox(height: AppSpacing.md),
              _UsersCrmDropdown(
                label: 'Status',
                value: _status,
                values: const ['active', 'suspended', 'pending', 'disabled'],
                onChanged: (value) => setState(() => _status = value),
              ),
              const SizedBox(height: AppSpacing.md),
              _UsersCrmTextField(
                controller: _notesController,
                label: 'Internal notes',
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'UID, auth email, created date and staff roles cannot be edited here.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: DrinkSpotButton(
                      label: 'Cancel',
                      variant: DrinkSpotButtonVariant.ghost,
                      onPressed: _saving ? null : () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: DrinkSpotButton(
                      label: _saving ? 'Saving…' : 'Save',
                      onPressed: _saving ? null : _save,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);
    Navigator.pop(
      context,
      _UserEditDraft(
        displayName: name,
        phone: _phoneController.text.trim(),
        city: _cityController.text.trim(),
        status: _status,
        internalNotes: _notesController.text.trim(),
      ),
    );
  }
}

class _UsersCrmSection extends StatelessWidget {
  const _UsersCrmSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return VenuePageSection(title: title, child: child);
  }
}

class _UsersCrmContextLine extends StatelessWidget {
  const _UsersCrmContextLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UsersCrmStatusChip extends StatelessWidget {
  const _UsersCrmStatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final lower = label.toLowerCase();
    final color = switch (lower) {
      'active' || 'verified' => AppColors.trailGold,
      'suspended' || 'disabled' || 'banned' => AppColors.primaryPink,
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

class _UsersCrmDropdown extends StatelessWidget {
  const _UsersCrmDropdown({
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
        ? _UsersCrmToolbarMetrics.fieldTextStyle
        : const TextStyle(
            color: AppColors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          );

    String displayLabel(String item) => compact ? '$label: $item' : item;

    final field = DropdownButtonFormField<String>(
      isExpanded: true,
      isDense: true,
      iconSize: compact ? 18 : 24,
      menuMaxHeight: 320,
      initialValue: selected,
      dropdownColor: AppColors.surfaceElevated,
      style: textStyle,
      decoration: compact
          ? _UsersCrmToolbarMetrics.dropdownDecoration(label: label)
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

class _UsersCrmTextField extends StatelessWidget {
  const _UsersCrmTextField({
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

class _UsersCrmPaginationBar extends StatelessWidget {
  const _UsersCrmPaginationBar({
    required this.pageIndex,
    required this.totalPages,
    required this.visibleCount,
    required this.totalCount,
    required this.onPrevious,
    required this.onNext,
  });

  final int pageIndex;
  final int totalPages;
  final int visibleCount;
  final int totalCount;
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

class _UsersCrmLoadingPanel extends StatelessWidget {
  const _UsersCrmLoadingPanel();

  @override
  Widget build(BuildContext context) {
    return VenuePageSection(
      title: 'Loading users',
      child: Column(
        children: [
          const LinearProgressIndicator(),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Reading users collection…',
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _UsersCrmErrorCard extends StatelessWidget {
  const _UsersCrmErrorCard({required this.collectionPath, required this.error});

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
      title: 'Could not load users',
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

class _UsersCrmInlineErrorBanner extends StatelessWidget {
  const _UsersCrmInlineErrorBanner({required this.error});

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
              'Live refresh failed — showing last loaded users. $message',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserDeleteDialog extends StatefulWidget {
  const _UserDeleteDialog({required this.displayName, this.email});

  final String displayName;
  final String? email;

  @override
  State<_UserDeleteDialog> createState() => _UserDeleteDialogState();
}

class _UserDeleteDialogState extends State<_UserDeleteDialog> {
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emailLine = widget.email != null && widget.email!.trim().isNotEmpty
        ? '\n${widget.email!.trim()}'
        : '';

    return AlertDialog(
      backgroundColor: AppColors.surfaceElevated,
      title: const Text('Delete user'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'You are about to remove "${widget.displayName}"$emailLine from the active users list.',
              style: const TextStyle(color: AppColors.white),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'The user will be archived to deleted_users before they disappear from the admin list. This is not an immediate hard delete.',
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        DrinkSpotButton(
          label: 'Delete user',
          compact: true,
          variant: DrinkSpotButtonVariant.secondary,
          onPressed: () {
            final reason = _reasonController.text.trim();
            Navigator.pop(context, (
              confirmed: true,
              reason: reason.isEmpty ? null : reason,
            ));
          },
        ),
      ],
    );
  }
}
