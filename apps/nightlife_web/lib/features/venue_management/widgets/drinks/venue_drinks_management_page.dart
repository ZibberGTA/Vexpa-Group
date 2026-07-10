import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/files/file_download.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../venue/data/models/drink_model.dart';
import '../../../venue/data/venue_drinks_repository.dart';
import '../../models/drink_categories.dart';
import '../../models/venue_dashboard_activity.dart';
import '../../models/venue_dashboard_tab.dart';
import '../../models/venue_page_quick_action.dart';
import '../../data/drink_spreadsheet_service.dart';
import '../page/venue_dashboard_page_scaffold.dart';
import '../page/venue_dashboard_page_widgets.dart';
import '../venue_dashboard_controller.dart';
import 'add_drink_dialog.dart';
import 'bulk_import_drinks_dialog.dart';
import 'bulk_delete_drinks_confirmation_dialog.dart';
import 'bulk_edit_drinks_dialog.dart';
import 'drink_row.dart';
import 'drink_selection_action_bar.dart';
import 'drink_table_sort.dart';
import 'drinks_category_filter.dart';
import 'drinks_search_field.dart';
import 'edit_drink_dialog.dart';

/// Venue drinks management workspace with Firestore-backed menu list.
class VenueDrinksManagementPage extends StatefulWidget {
  const VenueDrinksManagementPage({
    super.key,
    this.repository,
    this.testCreatedBy,
    this.testPickFile,
    this.testDownloadBytes,
  });

  final VenueDrinksRepository? repository;
  final String? testCreatedBy;
  final Future<({Uint8List bytes, String filename})?> Function()? testPickFile;
  final void Function(Uint8List bytes, String filename)? testDownloadBytes;

  @override
  State<VenueDrinksManagementPage> createState() =>
      _VenueDrinksManagementPageState();
}

class _VenueDrinksManagementPageState extends State<VenueDrinksManagementPage> {
  late final VenueDrinksRepository _repository =
      widget.repository ?? VenueDrinksRepository();

  final _searchController = TextEditingController();
  final Set<String> _selectedDrinkIds = {};
  String _searchQuery = '';
  final Set<String> _selectedCategories = {};
  bool _exportingDrinks = false;
  DrinkTableSort _sort = const DrinkTableSort();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleDrinkSelection(String drinkId, bool selected) {
    setState(() {
      if (selected) {
        _selectedDrinkIds.add(drinkId);
      } else {
        _selectedDrinkIds.remove(drinkId);
      }
    });
  }

  void _clearSelection() {
    if (_selectedDrinkIds.isEmpty) return;
    setState(_selectedDrinkIds.clear);
  }

  void _pruneSelection(List<DrinkModel> drinks) {
    final activeIds = drinks.map((drink) => drink.id).toSet();
    _selectedDrinkIds.removeWhere((id) => !activeIds.contains(id));
  }

  List<DrinkModel> _selectedDrinks(List<DrinkModel> drinks) {
    return drinks.where((drink) => _selectedDrinkIds.contains(drink.id)).toList();
  }

  Future<void> _openAddDrinkDialog(List<DrinkModel> venueDrinks) async {
    final added = await showAddDrinkDialog(
      context,
      repository: _repository,
      testCreatedBy: widget.testCreatedBy,
      venueDrinks: venueDrinks,
    );
    if (!mounted || !added) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Drink added to your menu.')),
    );
  }

  Future<void> _openEditDrinkDialog(
    DrinkModel drink,
    List<DrinkModel> venueDrinks,
  ) async {
    final result = await showEditDrinkDialog(
      context,
      drink: drink,
      repository: _repository,
      testUpdatedBy: widget.testCreatedBy,
      venueDrinks: venueDrinks,
    );
    if (!mounted || result == null) return;

    if (result == DrinkEditResult.deleted) {
      _clearSelection();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Drink deleted successfully.')),
      );
    }
  }

  Future<void> _handleEditSelected(List<DrinkModel> allDrinks) async {
    final selected = _selectedDrinks(allDrinks);
    if (selected.isEmpty) return;

    if (selected.length == 1) {
      await _openEditDrinkDialog(selected.first, allDrinks);
      return;
    }

    final controller = VenueDashboardController.maybeOf(context);
    final venueName = controller?.contextData.venueName ?? '';

    final applied = await showBulkEditDrinksDialog(
      context,
      drinks: selected,
      venueDrinks: allDrinks,
      venueName: venueName,
      repository: _repository,
      testUpdatedBy: widget.testCreatedBy,
    );
    if (!mounted || !applied) return;

    _clearSelection();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Updated ${selected.length} drinks.')),
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

  Future<void> _handleDeleteSelected(List<DrinkModel> allDrinks) async {
    final selected = _selectedDrinks(allDrinks);
    if (selected.isEmpty) return;

    final confirmed = await BulkDeleteDrinksConfirmationDialog.show(
      context,
      drinkCount: selected.length,
    );
    if (!confirmed || !mounted) return;

    final userId = _resolveUserId();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to delete drinks.')),
      );
      return;
    }

    try {
      await _repository.bulkDeleteDrinks(
        drinkIds: selected.map((drink) => drink.id).toList(),
        deletedBy: userId,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete selected drinks.')),
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
              ? 'Drink deleted successfully.'
              : '$count drinks deleted successfully.',
        ),
      ),
    );
  }

  void _handleQuickAction(VenuePageQuickAction action, List<DrinkModel> drinks) {
    if (action.actionKey == VenuePageActionKeys.addDrink) {
      _openAddDrinkDialog(drinks);
      return;
    }
    if (action.actionKey == VenuePageActionKeys.bulkImportDrinks) {
      _openBulkImportDialog(drinks);
      return;
    }
    if (action.actionKey == VenuePageActionKeys.exportDrinks) {
      _handleExportDrinks(drinks);
      return;
    }
    showVenuePagePlaceholderAction(context, action.label);
  }

  Future<void> _openBulkImportDialog(List<DrinkModel> drinks) async {
    final controller = VenueDashboardController.maybeOf(context);
    final contextData = controller?.contextData;
    if (contextData == null) return;

    final imported = await showBulkImportDrinksDialog(
      context,
      venueId: contextData.venueId,
      venueName: contextData.venueName,
      existingDrinks: drinks,
      repository: _repository,
      testCreatedBy: widget.testCreatedBy,
      testPickFile: widget.testPickFile,
      testDownloadBytes: widget.testDownloadBytes,
    );
    if (!mounted || !imported) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Drinks imported successfully.')),
    );
  }

  Future<void> _handleExportDrinks(List<DrinkModel> drinks) async {
    if (_exportingDrinks) return;

    final controller = VenueDashboardController.maybeOf(context);
    final venueName = controller?.contextData.venueName ?? 'venue';

    setState(() => _exportingDrinks = true);

    try {
      final bytes = DrinkSpreadsheetService.exportDrinksBytes(drinks);
      final filename = DrinkSpreadsheetService.exportFilename(venueName, DateTime.now());
      if (widget.testDownloadBytes != null) {
        widget.testDownloadBytes!(bytes, filename);
      } else {
        downloadBytes(
          bytes,
          filename,
          mimeType: DrinkSpreadsheetService.templateMimeType,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            drinks.isEmpty
                ? 'Exported empty drinks template.'
                : 'Exported ${drinks.length} drinks.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not export drinks. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _exportingDrinks = false);
      }
    }
  }

  List<VenueDashboardActivity> _buildRecentActivity(List<DrinkModel> drinks) {
    final sorted = [...drinks]
      ..sort((a, b) {
        final aTime = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

    return sorted.take(5).map((drink) {
      final timestamp = drink.updatedAt ?? drink.createdAt;
      final isNew = drink.createdAt != null &&
          drink.updatedAt != null &&
          drink.updatedAt!.difference(drink.createdAt!).inMinutes <= 2;

      return VenueDashboardActivity(
        title: isNew ? 'Drink added: ${drink.name}' : 'Drink updated: ${drink.name}',
        timestampLabel: timestamp == null
            ? 'Recently'
            : VenueDrinksRepository.relativeTimeLabel(timestamp),
        icon: Icons.local_bar_outlined,
      );
    }).toList();
  }

  void _clearCategoryFilters() {
    setState(_selectedCategories.clear);
  }

  void _toggleCategoryFilter(String category, bool selected) {
    setState(() {
      if (selected) {
        _selectedCategories.add(category);
      } else {
        _selectedCategories.remove(category);
      }
    });
  }

  void _toggleSort(DrinkSortColumn column) {
    setState(() => _sort = _sort.toggleColumn(column));
  }

  List<DrinkModel> _filteredDrinks(List<DrinkModel> drinks) {
    final query = _searchQuery.trim().toLowerCase();
    return drinks.where((drink) {
      final matchesQuery = query.isEmpty ||
          drink.name.toLowerCase().contains(query) ||
          DrinkCategories.displayName(drink.category).toLowerCase().contains(query);
      final matchesCategory = _selectedCategories.isEmpty ||
          _selectedCategories.contains(DrinkCategories.displayName(drink.category));
      return matchesQuery && matchesCategory;
    }).toList();
  }

  List<DrinkModel> _displayDrinks(List<DrinkModel> drinks) {
    return sortDrinks(_filteredDrinks(drinks), _sort);
  }

  @override
  Widget build(BuildContext context) {
    final controller = VenueDashboardController.maybeOf(context);
    final venueId = controller?.contextData.venueId ?? '';

    return StreamBuilder<List<DrinkModel>>(
      stream: _repository.watchDrinks(venueId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryPink),
          );
        }

        final drinks = snapshot.data ?? const [];
        _pruneSelection(drinks);
        final displayed = _displayDrinks(drinks);

        return VenueDashboardPageScaffold(
          tab: VenueDashboardTab.drinks,
          onPrimaryAction: () => _openAddDrinkDialog(drinks),
          onQuickAction: (action) => _handleQuickAction(action, drinks),
          activities: _buildRecentActivity(drinks),
          mainContent: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VenuePageMetricRow(
                metrics: [
                  VenuePageMetricCard(
                    label: 'Total drinks',
                    value: '${drinks.length}',
                    icon: Icons.local_bar_outlined,
                  ),
                  VenuePageMetricCard(
                    label: 'Categories',
                    value: '${{for (final d in drinks) DrinkCategories.displayName(d.category)}.length}',
                    icon: Icons.category_outlined,
                  ),
                  VenuePageMetricCard(
                    label: 'Available',
                    value: '${drinks.where((d) => d.available).length}',
                    icon: Icons.check_circle_outline_rounded,
                  ),
                  VenuePageMetricCard(
                    label: 'Featured',
                    value: '${drinks.where((d) => d.featured).length}',
                    icon: Icons.star_outline_rounded,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              VenuePageSection(
                title: 'Drinks Menu',
                trailing: SizedBox(
                  width: 240,
                  child: DrinksSearchField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DrinksCategoryFilterRow(
                      selectedCategories: _selectedCategories,
                      onAllSelected: _clearCategoryFilters,
                      onCategoryToggled: _toggleCategoryFilter,
                    ),
                    if (_selectedDrinkIds.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      DrinkSelectionActionBar(
                        selectedCount: _selectedDrinkIds.length,
                        onEdit: () => _handleEditSelected(drinks),
                        onDelete: () => _handleDeleteSelected(drinks),
                        onClearSelection: _clearSelection,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    if (drinks.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                        child: Column(
                          children: [
                            Text(
                              'No drinks added yet.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: AppSpacing.sm),
                            Text(
                              'Add your first drink to start building your menu.',
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
                          'No drinks match your search.',
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
                          DrinkTableHeader(
                            sort: _sort,
                            onSortColumn: _toggleSort,
                          ),
                          for (var i = 0; i < displayed.length; i++)
                            DrinkRow(
                              drink: displayed[i],
                              repository: _repository,
                              venueName:
                                  controller?.contextData.venueName ?? '',
                              venueDrinks: drinks,
                              updatedBy: widget.testCreatedBy ??
                                  _resolveUserId(),
                              isSelected: _selectedDrinkIds.contains(displayed[i].id),
                              onSelectionChanged: (selected) =>
                                  _toggleDrinkSelection(displayed[i].id, selected),
                              showDivider: i < displayed.length - 1,
                              onAdvancedEdit: () => _openEditDrinkDialog(
                                displayed[i],
                                drinks,
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

/// Shared quick-action keys for venue management pages.
class VenuePageActionKeys {
  VenuePageActionKeys._();

  static const addDrink = 'add_drink';
  static const bulkImportDrinks = 'bulk_import_drinks';
  static const exportDrinks = 'export_drinks';
  static const createDeal = 'create_deal';
  static const exportDeals = 'export_deals';
  static const duplicateDeal = 'duplicate_deal';
  static const pauseSelectedDeals = 'pause_selected_deals';
  static const viewDealPerformance = 'view_deal_performance';
  static const createSupportTicket = 'create_support_ticket';
  static const addEvent = 'add_event';
  static const duplicateEvent = 'duplicate_event';
  static const exportEvents = 'export_events';
  static const uploadEventBanner = 'upload_event_banner';
  static const viewEventPerformance = 'view_event_performance';
  static const changeBanner = 'change_banner';
  static const uploadLogo = 'upload_logo';
  static const adjustBannerPosition = 'adjust_banner_position';
  static const adjustLogoPosition = 'adjust_logo_position';
  static const mediaUpload = 'media_upload';
  static const mediaReorderGallery = 'media_reorder_gallery';
  static const mediaSetCover = 'media_set_cover';
  static const mediaExport = 'media_export';
  static const mediaDeleteSelected = 'media_delete_selected';
  static const mediaReplace = 'media_replace';
}
