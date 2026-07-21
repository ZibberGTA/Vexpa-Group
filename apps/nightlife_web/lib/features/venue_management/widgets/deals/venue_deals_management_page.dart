import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/files/file_download.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../venue/data/models/deal_model.dart';
import '../../../venue/data/venue_deals_repository.dart';
import '../../data/deal_spreadsheet_service.dart';
import '../../data/experience_content_support.dart';
import '../../models/bulk_deal_patch.dart';
import '../../models/deal_status.dart';
import '../../data/venue_management_page_activity_support.dart';
import '../../models/deal_types.dart';
import '../../models/venue_dashboard_tab.dart';
import '../../models/venue_page_quick_action.dart';
import '../drinks/drinks_search_field.dart';
import '../drinks/venue_drinks_management_page.dart';
import '../page/venue_dashboard_page_scaffold.dart';
import '../page/venue_dashboard_page_widgets.dart';
import '../venue_dashboard_controller.dart';
import 'add_deal_dialog.dart';
import 'delete_deal_confirmation_dialog.dart';
import 'bulk_edit_deals_dialog.dart';
import 'deal_row.dart';
import 'deal_selection_action_bar.dart';
import 'deal_table_sort.dart';
import 'deals_status_filter.dart';
import 'edit_deal_dialog.dart';
import 'pause_selected_deals_confirmation_dialog.dart';

/// Venue deals management workspace with Firestore-backed offer list.
class VenueDealsManagementPage extends StatefulWidget {
  const VenueDealsManagementPage({
    super.key,
    this.repository,
    this.testCreatedBy,
    this.testDownloadBytes,
    this.testStartDate,
    this.testEndDate,
  });

  final VenueDealsRepository? repository;
  final String? testCreatedBy;
  final void Function(Uint8List bytes, String filename)? testDownloadBytes;
  final DateTime? testStartDate;
  final DateTime? testEndDate;

  @override
  State<VenueDealsManagementPage> createState() =>
      _VenueDealsManagementPageState();
}

class _VenueDealsManagementPageState extends State<VenueDealsManagementPage> {
  late final VenueDealsRepository _repository =
      widget.repository ?? VenueDealsRepository();

  final _searchController = TextEditingController();
  final Set<String> _selectedDealIds = {};
  String _searchQuery = '';
  final Set<String> _selectedStatuses = {};
  bool _exportingDeals = false;
  bool _pendingCreateDealActionHandled = false;
  DealTableSort _sort = const DealTableSort();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleDealSelection(String dealId, bool selected) {
    setState(() {
      if (selected) {
        _selectedDealIds.add(dealId);
      } else {
        _selectedDealIds.remove(dealId);
      }
    });
  }

  void _clearSelection() {
    if (_selectedDealIds.isEmpty) return;
    setState(_selectedDealIds.clear);
  }

  void _pruneSelection(List<DealModel> deals) {
    final activeIds = deals.map((deal) => deal.id).toSet();
    _selectedDealIds.removeWhere((id) => !activeIds.contains(id));
  }

  List<DealModel> _selectedDeals(List<DealModel> deals) {
    return deals.where((deal) => _selectedDealIds.contains(deal.id)).toList();
  }

  Future<void> _openAddDealDialog(List<DealModel> venueDeals) async {
    final added = await showAddDealDialog(
      context,
      repository: _repository,
      testCreatedBy: widget.testCreatedBy,
      venueDeals: venueDeals,
      testStartDate: widget.testStartDate,
      testEndDate: widget.testEndDate,
    );
    if (!mounted || !added) return;

    await reloadVenueManagementPageActivity(context);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deal created successfully.')),
    );
  }

  void _maybeOpenPendingCreateDealDialog(List<DealModel> deals) {
    if (_pendingCreateDealActionHandled) return;

    final pendingActionKey =
        VenueDashboardController.maybeOf(context)?.takePendingTabActionKey?.call();
    if (pendingActionKey != VenuePageActionKeys.createDeal) return;

    _pendingCreateDealActionHandled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_openAddDealDialog(deals));
    });
  }

  Future<void> _openEditDealDialog(
    DealModel deal,
    List<DealModel> venueDeals,
  ) async {
    final result = await showEditDealDialog(
      context,
      deal: deal,
      repository: _repository,
      testUpdatedBy: widget.testCreatedBy,
      venueDeals: venueDeals,
    );
    if (!mounted || result == null) return;

    if (result == DealEditResult.deleted) {
      _clearSelection();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deal deleted successfully.')),
      );
    }

    await reloadVenueManagementPageActivity(context);
  }

  Future<void> _handleEditSelected(List<DealModel> allDeals) async {
    final selected = _selectedDeals(allDeals);
    if (selected.isEmpty) return;

    if (selected.length == 1) {
      await _openEditDealDialog(selected.first, allDeals);
      return;
    }

    final controller = VenueDashboardController.maybeOf(context);
    final venueName = controller?.contextData.venueName ?? '';

    final applied = await showBulkEditDealsDialog(
      context,
      deals: selected,
      venueDeals: allDeals,
      venueName: venueName,
      repository: _repository,
      testUpdatedBy: widget.testCreatedBy,
    );
    if (!mounted || !applied) return;

    await reloadVenueManagementPageActivity(context);
    if (!mounted) return;

    _clearSelection();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Updated ${selected.length} deals.')),
    );
  }

  String? _resolveUserId() {
    if (widget.testCreatedBy != null) return widget.testCreatedBy;
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleDeleteSelected(List<DealModel> allDeals) async {
    final selected = _selectedDeals(allDeals);
    if (selected.isEmpty) return;

    final confirmed = await BulkDeleteDealsConfirmationDialog.show(
      context,
      dealCount: selected.length,
    );
    if (!confirmed || !mounted) return;

    final userId = _resolveUserId();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to delete deals.')),
      );
      return;
    }

    try {
      await _repository.bulkDeleteDeals(
        deals: selected,
        deletedBy: userId,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete selected deals.')),
      );
      return;
    }

    if (!mounted) return;

    final count = selected.length;
    _clearSelection();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          count == 1
              ? 'Deal deleted successfully.'
              : '$count deals deleted successfully.',
        ),
      ),
    );
  }

  void _showDealSelectionRequiredMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleDuplicateSelected(List<DealModel> allDeals) async {
    final selected = _selectedDeals(allDeals);
    if (selected.isEmpty) {
      _showDealSelectionRequiredMessage('Select a deal to duplicate.');
      return;
    }
    if (selected.length > 1) {
      _showDealSelectionRequiredMessage('Select one deal to duplicate.');
      return;
    }

    final userId = _resolveUserId();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to duplicate deals.')),
      );
      return;
    }

    final controller = VenueDashboardController.maybeOf(context);
    final venueName = controller?.contextData.venueName ?? '';

    try {
      await _repository.duplicateDeal(
        source: selected.first,
        venueName: venueName,
        createdBy: userId,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not duplicate deal. Please try again.')),
      );
      return;
    }

    if (!mounted) return;
    _clearSelection();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deal duplicated successfully.')),
    );
  }

  Future<void> _handlePauseSelected(List<DealModel> allDeals) async {
    final selected = _selectedDeals(allDeals);
    final pausable = selected.where((deal) {
      return WebExperienceContentSupport.availability
          .isDealPausable(computeDealStatus(deal));
    }).toList();

    if (pausable.isEmpty) {
      _showDealSelectionRequiredMessage(
        'Select one or more active or scheduled deals to pause.',
      );
      return;
    }

    final confirmed = await PauseSelectedDealsConfirmationDialog.show(
      context,
      dealCount: pausable.length,
    );
    if (!confirmed || !mounted) return;

    final userId = _resolveUserId();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to pause deals.')),
      );
      return;
    }

    final controller = VenueDashboardController.maybeOf(context);
    final venueName = controller?.contextData.venueName ?? '';

    try {
      for (final deal in pausable) {
        await _repository.patchDeal(
          dealId: deal.id,
          venueId: deal.venueId,
          venueName: venueName,
          title: deal.title,
          description: deal.description,
          dealType: deal.dealType,
          value: deal.value,
          patch: const BulkDealPatch(isActive: false),
          updatedBy: userId,
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not pause selected deals.')),
      );
      return;
    }

    if (!mounted) return;
    _clearSelection();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          pausable.length == 1
              ? 'Deal paused successfully.'
              : '${pausable.length} deals paused successfully.',
        ),
      ),
    );
  }

  void _handleViewDealPerformance() {
    final controller = VenueDashboardController.maybeOf(context);
    if (controller != null) {
      controller.selectTab(VenueDashboardTab.analytics);
      return;
    }
    showVenueStyledComingSoonMessage(
      context,
      'Deal performance analytics is coming soon.',
    );
  }

  void _handleQuickAction(VenuePageQuickAction action, List<DealModel> deals) {
    if (action.actionKey == VenuePageActionKeys.createDeal) {
      _openAddDealDialog(deals);
      return;
    }
    if (action.actionKey == VenuePageActionKeys.duplicateDeal) {
      _handleDuplicateSelected(deals);
      return;
    }
    if (action.actionKey == VenuePageActionKeys.exportDeals) {
      _handleExportDeals(deals);
      return;
    }
    if (action.actionKey == VenuePageActionKeys.viewDealPerformance) {
      _handleViewDealPerformance();
      return;
    }
    if (action.actionKey == VenuePageActionKeys.pauseSelectedDeals) {
      _handlePauseSelected(deals);
      return;
    }
    showVenuePagePlaceholderAction(context, action.label);
  }

  Future<void> _handleExportDeals(List<DealModel> deals) async {
    if (_exportingDeals) return;

    final controller = VenueDashboardController.maybeOf(context);
    final venueName = controller?.contextData.venueName ?? 'venue';

    setState(() => _exportingDeals = true);

    try {
      final bytes = DealSpreadsheetService.exportDealsBytes(deals);
      final filename =
          DealSpreadsheetService.exportFilename(venueName, DateTime.now());
      if (widget.testDownloadBytes != null) {
        widget.testDownloadBytes!(bytes, filename);
      } else {
        downloadBytes(
          bytes,
          filename,
          mimeType: DealSpreadsheetService.templateMimeType,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            deals.isEmpty
                ? 'Exported empty deals template.'
                : 'Exported ${deals.length} deals.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not export deals. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _exportingDeals = false);
      }
    }
  }

  void _clearStatusFilters() {
    setState(_selectedStatuses.clear);
  }

  void _toggleStatusFilter(String status, bool selected) {
    setState(() {
      if (selected) {
        _selectedStatuses.add(status);
      } else {
        _selectedStatuses.remove(status);
      }
    });
  }

  void _toggleSort(DealSortColumn column) {
    setState(() => _sort = _sort.toggleColumn(column));
  }

  List<DealModel> _filteredDeals(List<DealModel> deals) {
    final query = _searchQuery.trim().toLowerCase();
    return deals.where((deal) {
      final matchesQuery = query.isEmpty ||
          deal.title.toLowerCase().contains(query) ||
          deal.description.toLowerCase().contains(query) ||
          DealTypes.displayName(deal.dealType).toLowerCase().contains(query) ||
          deal.value.toLowerCase().contains(query);
      final matchesStatus =
          dealPassesStatusFilters(deal, _selectedStatuses);
      return matchesQuery && matchesStatus;
    }).toList();
  }

  List<DealModel> _displayDeals(List<DealModel> deals) {
    return sortDeals(_filteredDeals(deals), _sort);
  }

  @override
  Widget build(BuildContext context) {
    final controller = VenueDashboardController.maybeOf(context);
    final venueId = controller?.contextData.venueId ?? '';

    return StreamBuilder<List<DealModel>>(
      stream: _repository.watchManagementDeals(venueId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryPink),
          );
        }

        final deals = snapshot.data ?? const [];
        _pruneSelection(deals);
        _maybeOpenPendingCreateDealDialog(deals);
        final displayed = _displayDeals(deals);

        final dealMetrics = WebExperienceContentSupport.summary.dealMetrics(
          deals: deals,
          featured: (deal) => deal.featured,
          status: computeDealStatus,
        );

        return VenueDashboardPageScaffold(
          tab: VenueDashboardTab.deals,
          onPrimaryAction: () => _openAddDealDialog(deals),
          onQuickAction: (action) => _handleQuickAction(action, deals),
          mainContent: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VenuePageMetricRow(
                metrics: [
                  VenuePageMetricCard(
                    label: 'Total deals',
                    value: '${dealMetrics.total}',
                    icon: Icons.local_offer_outlined,
                  ),
                  VenuePageMetricCard(
                    label: 'Active',
                    value: '${dealMetrics.active}',
                    icon: Icons.check_circle_outline_rounded,
                  ),
                  VenuePageMetricCard(
                    label: 'Scheduled',
                    value: '${dealMetrics.scheduled}',
                    icon: Icons.schedule_outlined,
                  ),
                  VenuePageMetricCard(
                    label: 'Featured',
                    value: '${dealMetrics.featured}',
                    icon: Icons.star_outline_rounded,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              VenuePageSection(
                title: 'Deals',
                trailing: SizedBox(
                  width: 240,
                  child: DrinksSearchField(
                    key: const Key('deals_search_field'),
                    controller: _searchController,
                    hintText: 'Search deals…',
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DealsStatusFilterRow(
                      selectedStatuses: _selectedStatuses,
                      onAllSelected: _clearStatusFilters,
                      onStatusToggled: _toggleStatusFilter,
                    ),
                    if (_selectedDealIds.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      DealSelectionActionBar(
                        selectedCount: _selectedDealIds.length,
                        onEdit: () => _handleEditSelected(deals),
                        onDelete: () => _handleDeleteSelected(deals),
                        onClearSelection: _clearSelection,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    if (deals.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                        child: Column(
                          children: [
                            Text(
                              'No deals added yet.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: AppSpacing.sm),
                            Text(
                              'Create your first deal to start promoting your venue.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (displayed.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                        child: Text(
                          'No deals match your search.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DealTableHeader(
                            sort: _sort,
                            onSortColumn: _toggleSort,
                          ),
                          for (var i = 0; i < displayed.length; i++)
                            DealRow(
                              deal: displayed[i],
                              repository: _repository,
                              venueName:
                                  controller?.contextData.venueName ?? '',
                              venueDeals: deals,
                              updatedBy: widget.testCreatedBy ??
                                  _resolveUserId(),
                              isSelected:
                                  _selectedDealIds.contains(displayed[i].id),
                              onSelectionChanged: (selected) =>
                                  _toggleDealSelection(displayed[i].id, selected),
                              showDivider: i < displayed.length - 1,
                              onAdvancedEdit: () => _openEditDealDialog(
                                displayed[i],
                                deals,
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
