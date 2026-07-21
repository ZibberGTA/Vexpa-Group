import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../auth/services/user_role_service.dart';
import '../../../../core/files/file_download.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/components/drinkspot_button.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../venues/models/image_position_metadata.dart';
import '../../../venues/models/venue_model.dart';
import '../../data/venue_image_picker.dart';
import '../../data/venue_images_repository.dart';
import '../../data/venue_media_repository.dart';
import '../../data/venue_management_page_activity_support.dart';
import '../../data/venue_media_upload_errors.dart';
import '../../data/venue_media_upload_logger.dart';
import '../../data/venue_media_upload_service.dart';
import '../../services/venue_media_access_service.dart';
import '../../services/subscription_service.dart';
import '../../models/media_library_page_config.dart';
import '../../models/media_library_tab.dart';
import '../../models/media_subscription_limits.dart';
import '../../models/venue_dashboard_tab.dart';
import '../../models/venue_media_item.dart';
import '../../models/venue_page_quick_action.dart';
import '../drinks/drinks_search_field.dart';
import '../drinks/venue_drinks_management_page.dart';
import '../image_reposition/image_reposition_dialog.dart';
import '../page/venue_dashboard_page_scaffold.dart';
import '../page/venue_dashboard_page_widgets.dart';
import '../venue_dashboard_controller.dart';
import 'media_library_tab_bar.dart';
import 'media_table_widgets.dart';
import 'media_upgrade_card.dart';
import 'media_upload_dialog.dart';
import 'media_usage_card.dart';
import 'venue_gallery_preview_carousel.dart';

/// Gallery / Media Centre with separate venue, deal and event libraries.
class VenueGalleryManagementPage extends StatefulWidget {
  const VenueGalleryManagementPage({
    super.key,
    this.mediaRepository,
    this.imagesRepository,
    this.uploadService,
    this.testUploadedByUid,
    this.testUserProfile,
    this.testPickFiles,
  });

  final VenueMediaRepository? mediaRepository;
  final VenueImagesRepository? imagesRepository;
  final VenueMediaUploadService? uploadService;
  final String? testUploadedByUid;
  final UserRoleProfile? testUserProfile;
  final Future<List<({Uint8List bytes, String fileName})>> Function()?
  testPickFiles;

  @override
  State<VenueGalleryManagementPage> createState() =>
      _VenueGalleryManagementPageState();
}

class _VenueGalleryManagementPageState
    extends State<VenueGalleryManagementPage> {
  late final VenueMediaRepository _mediaRepository =
      widget.mediaRepository ?? VenueMediaRepository();
  late final VenueMediaUploadService _uploadService =
      widget.uploadService ??
      VenueMediaUploadService(repository: _mediaRepository);
  late final VenueImagesRepository _imagesRepository =
      widget.imagesRepository ?? VenueImagesRepository();

  MediaLibraryTab _activeTab = MediaLibraryTab.venueGallery;
  final _searchController = TextEditingController();
  final Set<String> _selectedIds = {};
  String _searchQuery = '';
  MediaTableSort _sort = const MediaTableSort();
  bool _exporting = false;
  String? _uploadProgressLabel;
  bool _pendingMediaUploadActionHandled = false;
  String? _settingFeaturedItemId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectTab(MediaLibraryTab tab) {
    setState(() {
      _activeTab = tab;
      _selectedIds.clear();
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _toggleSelection(String id, bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.add(id);
      } else {
        _selectedIds.remove(id);
      }
    });
  }

  void _clearSelection() {
    if (!mounted || _selectedIds.isEmpty) return;
    setState(_selectedIds.clear);
  }

  void _scheduleSelectionPrune(List<VenueMediaItem> items) {
    final activeIds = items.map((item) => item.id).toSet();
    if (_selectedIds.every(activeIds.contains)) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ids = items.map((item) => item.id).toSet();
      final hadStale = _selectedIds.any((id) => !ids.contains(id));
      if (!hadStale) return;
      setState(() => _selectedIds.removeWhere((id) => !ids.contains(id)));
    });
  }

  void _maybeOpenPendingMediaUploadWorkflow({
    required VenueModel venue,
    required List<VenueMediaItem> currentItems,
  }) {
    if (_pendingMediaUploadActionHandled) return;

    final pendingActionKey = VenueDashboardController.maybeOf(
      context,
    )?.takePendingTabActionKey?.call();
    if (pendingActionKey != VenuePageActionKeys.mediaUpload) return;

    _pendingMediaUploadActionHandled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_handleUpload(venue: venue, currentItems: currentItems));
    });
  }

  List<VenueMediaItem> _selectedItems(List<VenueMediaItem> items) {
    final activeIds = items.map((item) => item.id).toSet();
    return items
        .where(
          (item) =>
              _selectedIds.contains(item.id) && activeIds.contains(item.id),
        )
        .toList();
  }

  int _selectedCount(List<VenueMediaItem> items) {
    final activeIds = items.map((item) => item.id).toSet();
    return _selectedIds.where(activeIds.contains).length;
  }

  List<VenueMediaItem> _filteredItems(List<VenueMediaItem> items) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return items;
    return items
        .where(
          (item) =>
              item.displayName.toLowerCase().contains(query) ||
              item.url.toLowerCase().contains(query),
        )
        .toList();
  }

  List<VenueMediaItem> _displayItems(List<VenueMediaItem> items) {
    return sortMediaItems(_filteredItems(items), _sort);
  }

  void _toggleSort(MediaSortColumn column) {
    setState(() => _sort = _sort.toggleColumn(column));
  }

  Future<void> _handleUpload({
    required VenueModel venue,
    required List<VenueMediaItem> currentItems,
  }) async {
    if (!_activeTab.supportsDirectUpload) {
      _showMessage('Upload logo and banner from the Venue Profile page.');
      return;
    }

    if (venue.id.trim().isEmpty) {
      _showUploadError(
        VenueMediaUploadException(
          kind: VenueMediaUploadFailureKind.noActiveVenue,
          userMessage:
              'No active venue selected. Choose a venue and try again.',
          devDetails: 'venue.id is empty',
        ),
      );
      return;
    }

    final limit = MediaSubscriptionLimits.limitFor(
      planId: venue.subscriptionPlanId,
      tab: _activeTab,
      customLimits: venue.customMediaLimits,
    );
    final remaining = (limit - currentItems.length).clamp(0, limit);
    if (remaining == 0) {
      _showUploadError(
        VenueMediaUploadException(
          kind: VenueMediaUploadFailureKind.uploadLimitExceeded,
          userMessage:
              'You have reached your ${_activeTab.label.toLowerCase()} limit ($limit).',
          devDetails:
              'plan=${venue.subscriptionPlanId} limit=$limit current=${currentItems.length}',
        ),
      );
      return;
    }

    final bytesList = widget.testPickFiles != null
        ? await widget.testPickFiles!()
        : await pickVenueImageFiles(limit: remaining);
    if (!mounted || bytesList.isEmpty) return;

    final draft = await showMediaUploadDialog(
      context,
      tab: _activeTab,
      fileCount: bytesList.length,
      remainingSlots: remaining,
      previewImage: memoryImageFromBytes(bytesList.first.bytes),
    );
    if (!mounted || draft == null) return;

    try {
      final userId = await _resolveUserId();
      if (userId == null) {
        _showUploadError(
          VenueMediaUploadException(
            kind: VenueMediaUploadFailureKind.notSignedIn,
            userMessage: 'You must be signed in to upload media.',
            devDetails: 'FirebaseAuth.currentUser is null',
          ),
        );
        return;
      }

      final profile =
          widget.testUserProfile ??
          await UserRoleService.getCurrentUserProfile();
      if (!mounted) return;
      final controller = VenueDashboardController.maybeOf(context);

      setState(() {
        _uploadProgressLabel =
            'Uploading ${bytesList.length} ${_activeTab.emptyUnit}...';
      });

      final uploaded = await _uploadService.uploadLibraryImages(
        venueId: venue.id,
        uploadedByUid: userId,
        tab: _activeTab,
        files: bytesList,
        profile: profile,
        venueOwnerId: venue.ownerId,
        accessibleVenueIds:
            controller?.contextData.availableVenueIds ?? const [],
        startingSortOrder: currentItems.length,
        subscriptionPlanId: venue.subscriptionPlanId,
        customMediaLimits: venue.customMediaLimits,
        currentItemCount: currentItems.length,
        category: draft.category,
        caption: draft.caption,
      );

      if (!mounted) return;
      await reloadVenueManagementPageActivity(context);
      if (!mounted) return;
      _showMessage('Uploaded ${uploaded.length} ${_activeTab.emptyUnit}.');
    } on VenueMediaAccessDeniedException catch (error) {
      if (!mounted) return;
      _showUploadError(
        VenueMediaUploadException(
          kind: VenueMediaUploadFailureKind.accessDenied,
          userMessage: error.message,
          devDetails: error.toString(),
        ),
      );
    } on VenueMediaUploadException catch (error) {
      if (!mounted) return;
      _showUploadError(error);
    } catch (error, stackTrace) {
      if (!mounted) return;
      _showUploadError(
        VenueMediaUploadException.fromObject(
          error,
          stackTrace: stackTrace,
          context:
              'venueId=${venue.id} tab=${_activeTab.name} plan=${venue.subscriptionPlanId}',
        ),
      );
    } finally {
      if (mounted) setState(() => _uploadProgressLabel = null);
    }
  }

  Future<void> _handleReplaceSelected({
    required VenueModel venue,
    required List<VenueMediaItem> items,
  }) async {
    final selected = _selectedItems(items);
    if (selected.length != 1) {
      _showMessage('Select one image to replace.');
      return;
    }

    final replacement = await pickVenueImageFiles(limit: 1);
    if (!mounted || replacement.isEmpty) return;

    final existing = selected.first;
    final draft = await showMediaUploadDialog(
      context,
      tab: _activeTab,
      fileCount: 1,
      remainingSlots: 1,
      previewImage: memoryImageFromBytes(replacement.first.bytes),
    );
    if (!mounted || draft == null) return;

    try {
      final userId = await _resolveUserId();
      if (userId == null) {
        _showMessage('You must be signed in to replace media.');
        return;
      }
      final profile =
          widget.testUserProfile ??
          await UserRoleService.getCurrentUserProfile();
      if (!mounted) return;
      final controller = VenueDashboardController.maybeOf(context);

      setState(
        () => _uploadProgressLabel = 'Replacing ${existing.displayName}...',
      );
      await _uploadService.replaceLibraryImage(
        existingItem: existing,
        uploadedByUid: userId,
        file: replacement.first,
        profile: profile,
        venueOwnerId: venue.ownerId,
        accessibleVenueIds:
            controller?.contextData.availableVenueIds ?? const [],
        category: draft.category,
        caption: draft.caption,
      );
      if (!mounted) return;
      await reloadVenueManagementPageActivity(context);
      if (!mounted) return;
      _clearSelection();
      _showMessage('Image replaced.');
    } on VenueMediaAccessDeniedException catch (error) {
      if (!mounted) return;
      _showUploadError(
        VenueMediaUploadException(
          kind: VenueMediaUploadFailureKind.accessDenied,
          userMessage: error.message,
          devDetails: error.toString(),
        ),
      );
    } on VenueMediaUploadException catch (error) {
      if (!mounted) return;
      _showUploadError(error);
    } catch (error, stackTrace) {
      if (!mounted) return;
      _showUploadError(
        VenueMediaUploadException.fromObject(
          error,
          stackTrace: stackTrace,
          context: 'replace venueId=${venue.id} itemId=${existing.id}',
        ),
      );
    } finally {
      if (mounted) setState(() => _uploadProgressLabel = null);
    }
  }

  Future<void> _handleReorderGallery({
    required VenueModel venue,
    required List<VenueMediaItem> items,
  }) async {
    if (_activeTab != MediaLibraryTab.venueGallery) return;
    if (items.length < 2) {
      _showMessage('Upload at least two photos to reorder the gallery.');
      return;
    }

    final ordered = await showDialog<List<VenueMediaItem>>(
      context: context,
      builder: (context) => _GalleryReorderDialog(items: _displayItems(items)),
    );
    if (!mounted || ordered == null) return;

    try {
      final actorUid = await _resolveUserId();
      await _mediaRepository.updateSortOrder(
        venueId: venue.id,
        tab: _activeTab,
        orderedItems: ordered,
        actorUid: actorUid,
      );
      if (!mounted) return;
      await reloadVenueManagementPageActivity(context);
      if (!mounted) return;
      _clearSelection();
      _showMessage('Gallery order updated.');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not update gallery order.');
    }
  }

  Future<String?> _resolveUserId() async {
    if (widget.testUploadedByUid != null) return widget.testUploadedByUid;
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleDeleteSelected({
    required VenueModel venue,
    required List<VenueMediaItem> items,
  }) async {
    final selected = _selectedItems(items);
    if (selected.isEmpty) return;

    try {
      final actorUid = await _resolveUserId();
      await _mediaRepository.deleteMediaItems(
        venueId: venue.id,
        itemIds: selected.map((item) => item.id),
        itemsForStorage: selected,
        actorUid: actorUid,
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not delete selected items.');
      return;
    }

    if (!mounted) return;
    await reloadVenueManagementPageActivity(context);
    if (!mounted) return;
    final count = selected.length;
    _clearSelection();
    _showMessage(count == 1 ? 'Image deleted.' : '$count images deleted.');
  }

  Future<void> _handleSetFeaturedForItem({
    required VenueModel venue,
    required VenueMediaItem item,
  }) async {
    if (_activeTab != MediaLibraryTab.venueGallery) return;
    if (_settingFeaturedItemId != null) return;
    if (item.isCover) return;

    if (!item.canBeFeatured) {
      _showMessage(
        'Only active venue gallery photos with a saved URL can be featured.',
      );
      return;
    }

    if (!mounted) return;
    setState(() => _settingFeaturedItemId = item.id);

    var succeeded = false;
    try {
      final actorUid = await _resolveUserId();
      await _mediaRepository.setCoverPhoto(
        venueId: venue.id,
        itemId: item.id,
        actorUid: actorUid,
      );
      succeeded = true;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[VenueGallery] set featured failed: $error');
        debugPrint('[VenueGallery] stackTrace:\n$stackTrace');
      }
    } finally {
      _settingFeaturedItemId = null;
      if (mounted) {
        setState(() {});
      }
    }

    if (!mounted) return;
    if (succeeded) {
      _clearSelection();
      _showMessage('Featured image updated.');
      return;
    }
    _showMessage('Could not set featured image.');
  }

  Future<void> _handleSetCover({
    required VenueModel venue,
    required List<VenueMediaItem> items,
  }) async {
    if (_activeTab != MediaLibraryTab.venueGallery) return;
    if (_settingFeaturedItemId != null) return;

    final selected = _selectedItems(items);
    if (selected.length != 1) {
      _showMessage('Select one photo to set as featured.');
      return;
    }

    await _handleSetFeaturedForItem(venue: venue, item: selected.first);
  }

  Future<void> _handleAdjustPosition({
    required VenueModel venue,
    required VenueMediaItem item,
  }) async {
    if (!item.hasLoadableUrl) {
      _showMessage('Position can be adjusted once the image URL is available.');
      return;
    }

    final saved = await showImageRepositionDialog(
      context,
      frameKind: ImageFrameKind.galleryCover,
      imageUrl: item.previewUrl,
      initialMetadata: item.position,
      previewSubtitle:
          'Matches the featured gallery frame on your public profile.',
    );
    if (!mounted || saved == null) return;

    try {
      await _mediaRepository.saveItemPosition(
        venueId: venue.id,
        tab: _activeTab,
        itemId: item.id,
        metadata: saved,
        galleryIndexKey: item.id.startsWith('legacy-')
            ? item.id.split('-').last
            : item.id,
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not save image position.');
      return;
    }

    if (!mounted) return;
    _showMessage('Image position saved.');
  }

  Future<void> _handleExport(List<VenueMediaItem> items) async {
    if (_exporting) return;
    setState(() => _exporting = true);

    try {
      final csv = VenueMediaRepository.exportCsv(items);
      final bytes = Uint8List.fromList(utf8.encode(csv));
      final tabSlug = _activeTab.name
          .replaceAll(RegExp(r'([A-Z])'), '_\$1')
          .toLowerCase();
      downloadBytes(
        bytes,
        '${tabSlug}_media_${DateTime.now().millisecondsSinceEpoch}.csv',
        mimeType: 'text/csv',
      );
      if (!mounted) return;
      _showMessage('Exported ${items.length} items.');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not export list.');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _handleQuickAction(
    VenuePageQuickAction action,
    VenueModel venue,
    List<VenueMediaItem> items,
  ) {
    final key = action.actionKey;
    if (key == VenuePageActionKeys.mediaUpload) {
      _handleUpload(venue: venue, currentItems: items);
      return;
    }
    if (key == VenuePageActionKeys.mediaDeleteSelected) {
      _handleDeleteSelected(venue: venue, items: items);
      return;
    }
    if (key == VenuePageActionKeys.mediaSetCover) {
      _handleSetCover(venue: venue, items: items);
      return;
    }
    if (key == VenuePageActionKeys.mediaExport) {
      _handleExport(items);
      return;
    }
    if (key == VenuePageActionKeys.mediaReplace) {
      _handleReplaceSelected(venue: venue, items: items);
      return;
    }
    if (key == VenuePageActionKeys.mediaReorderGallery) {
      _handleReorderGallery(venue: venue, items: items);
      return;
    }
    showVenuePagePlaceholderAction(context, action.label);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _showUploadError(VenueMediaUploadException error) {
    VenueMediaUploadLogger.logFailure(error);
    _showMessage(error.messageForUi(includeDevDetails: kDebugMode));
  }

  @override
  Widget build(BuildContext context) {
    final controller = VenueDashboardController.maybeOf(context);
    final venueId = controller?.contextData.venueId ?? '';

    return StreamBuilder<Map<String, dynamic>?>(
      stream: _imagesRepository.watchVenueDocument(venueId),
      builder: (context, venueSnapshot) {
        final venueData = venueSnapshot.data;
        if (venueData == null &&
            venueSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryPink),
          );
        }

        final venue = venueData == null
            ? null
            : VenueModel.fromMap(venueId, venueData);
        if (venue == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryPink),
          );
        }

        final hasAccess = SubscriptionService.canUseGallery(
          venueId: venue.id,
          planId: venue.subscriptionPlanId,
        );
        final pageConfig = MediaLibraryPageConfig.forTab(_activeTab);
        final limit = MediaSubscriptionLimits.limitFor(
          planId: venue.subscriptionPlanId,
          tab: _activeTab,
          customLimits: venue.customMediaLimits,
        );

        if (!hasAccess) {
          return VenueDashboardPageScaffold(
            tab: VenueDashboardTab.gallery,
            quickActionsOverride: const [],
            mainContent: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MediaLibraryTabBar(
                  selectedTab: _activeTab,
                  onTabSelected: _selectTab,
                ),
                const SizedBox(height: AppSpacing.lg),
                const MediaUpgradeCard(),
              ],
            ),
          );
        }

        return StreamBuilder<List<VenueMediaItem>>(
          stream: _mediaRepository.watchMediaItems(
            venueId: venue.id,
            tab: _activeTab,
          ),
          builder: (context, mediaSnapshot) {
            final currentItems = mediaSnapshot.data ?? const [];
            final isLoading =
                mediaSnapshot.connectionState == ConnectionState.waiting &&
                !mediaSnapshot.hasData;

            _scheduleSelectionPrune(currentItems);
            _maybeOpenPendingMediaUploadWorkflow(
              venue: venue,
              currentItems: currentItems,
            );

            return VenueDashboardPageScaffold(
              tab: VenueDashboardTab.gallery,
              activityLimit: 5,
              quickActionsOverride: pageConfig.quickActions,
              primaryActionLabelOverride: pageConfig.primaryActionLabel,
              primaryActionIconOverride: pageConfig.primaryActionIcon,
              onPrimaryAction: () {
                if (!_activeTab.supportsDirectUpload) {
                  _showMessage(
                    'Upload logo and banner from the Venue Profile page.',
                  );
                  return;
                }
                _handleUpload(venue: venue, currentItems: currentItems);
              },
              onQuickAction: (action) =>
                  _handleQuickAction(action, venue, currentItems),
              mainContent: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MediaLibraryTabBar(
                    selectedTab: _activeTab,
                    onTabSelected: _selectTab,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _ActiveLibraryContent(
                    key: ValueKey(_activeTab),
                    activeTab: _activeTab,
                    limit: limit,
                    pageConfig: pageConfig,
                    items: currentItems,
                    isLoading: isLoading,
                    searchController: _searchController,
                    selectedCount: _selectedCount(currentItems),
                    sort: _sort,
                    onSearchChanged: (value) =>
                        setState(() => _searchQuery = value),
                    onToggleSelection: _toggleSelection,
                    onClearSelection: _clearSelection,
                    onToggleSort: _toggleSort,
                    onQuickAction: (action) =>
                        _handleQuickAction(action, venue, currentItems),
                    onAdjustPosition: (item) =>
                        _handleAdjustPosition(venue: venue, item: item),
                    onDeleteSelected: () => _handleDeleteSelected(
                      venue: venue,
                      items: currentItems,
                    ),
                    onSetCover: () =>
                        _handleSetCover(venue: venue, items: currentItems),
                    onSetFeaturedForItem: (item) =>
                        _handleSetFeaturedForItem(venue: venue, item: item),
                    settingFeaturedItemId: _settingFeaturedItemId,
                    uploadProgressLabel: _uploadProgressLabel,
                    displayItems: _displayItems,
                    selectedIds: _selectedIds,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ActiveLibraryContent extends StatelessWidget {
  const _ActiveLibraryContent({
    super.key,
    required this.activeTab,
    required this.limit,
    required this.pageConfig,
    required this.items,
    required this.isLoading,
    required this.searchController,
    required this.selectedCount,
    required this.selectedIds,
    required this.sort,
    required this.onSearchChanged,
    required this.onToggleSelection,
    required this.onClearSelection,
    required this.onToggleSort,
    required this.onQuickAction,
    required this.onAdjustPosition,
    required this.onDeleteSelected,
    required this.onSetCover,
    required this.onSetFeaturedForItem,
    required this.settingFeaturedItemId,
    required this.uploadProgressLabel,
    required this.displayItems,
  });

  final MediaLibraryTab activeTab;
  final int limit;
  final MediaLibraryPageConfig pageConfig;
  final List<VenueMediaItem> items;
  final bool isLoading;
  final TextEditingController searchController;
  final int selectedCount;
  final Set<String> selectedIds;
  final MediaTableSort sort;
  final ValueChanged<String> onSearchChanged;
  final void Function(String id, bool selected) onToggleSelection;
  final VoidCallback onClearSelection;
  final ValueChanged<MediaSortColumn> onToggleSort;
  final void Function(VenuePageQuickAction action) onQuickAction;
  final Future<void> Function(VenueMediaItem item) onAdjustPosition;
  final VoidCallback onDeleteSelected;
  final VoidCallback onSetCover;
  final Future<void> Function(VenueMediaItem item) onSetFeaturedForItem;
  final String? settingFeaturedItemId;
  final String? uploadProgressLabel;
  final List<VenueMediaItem> Function(List<VenueMediaItem> items) displayItems;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primaryPink),
        ),
      );
    }

    final displayed = displayItems(items);
    final isBrandAssets = activeTab == MediaLibraryTab.brandAssets;
    final showCoverColumn = activeTab == MediaLibraryTab.venueGallery;
    final showCurrentColumn = isBrandAssets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (uploadProgressLabel != null) ...[
          _MediaUploadProgressBanner(label: uploadProgressLabel!),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (activeTab == MediaLibraryTab.venueGallery) ...[
          VenueGalleryPreviewCarousel(items: items),
          const SizedBox(height: AppSpacing.lg),
        ],
        MediaUsageCard(
          tab: activeTab,
          used: activeTab == MediaLibraryTab.venueGallery ? items.length : 0,
          limit: limit,
        ),
        const SizedBox(height: AppSpacing.lg),
        VenuePageSection(
          title: pageConfig.tableTitle,
          trailing: SizedBox(
            width: 240,
            child: DrinksSearchField(
              controller: searchController,
              onChanged: onSearchChanged,
              hintText: 'Search images…',
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (selectedCount > 0) ...[
                MediaSelectionActionBar(
                  selectedCount: selectedCount,
                  onDelete: onDeleteSelected,
                  onClearSelection: onClearSelection,
                  onSetCover: activeTab == MediaLibraryTab.venueGallery
                      ? onSetCover
                      : null,
                  onReplace: selectedCount == 1
                      ? () => onQuickAction(
                          const VenuePageQuickAction(
                            label: 'Replace Image',
                            icon: Icons.swap_horiz_rounded,
                            actionKey: 'media_replace',
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Column(
                    children: [
                      Text(
                        isBrandAssets
                            ? 'No brand assets yet.'
                            : activeTab == MediaLibraryTab.venueGallery
                            ? 'No gallery photos yet.'
                            : 'No ${activeTab.emptyUnit} yet.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        isBrandAssets
                            ? 'Upload logo and banner from the Venue Profile page.'
                            : activeTab == MediaLibraryTab.venueGallery
                            ? 'Upload photos to build your venue gallery.'
                            : 'Upload ${activeTab.emptyUnit} to build your ${activeTab.label.toLowerCase()}.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
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
                    'No images match your search.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                )
              else ...[
                MediaTableHeader(
                  sort: sort,
                  onSortColumn: onToggleSort,
                  showCoverColumn: showCoverColumn || showCurrentColumn,
                  coverColumnLabel: showCurrentColumn ? 'Current' : 'Featured',
                ),
                for (var i = 0; i < displayed.length; i++)
                  MediaItemRow(
                    item: displayed[i],
                    isSelected: selectedIds.contains(displayed[i].id),
                    onSelectionChanged: (selected) =>
                        onToggleSelection(displayed[i].id, selected),
                    onAdjustPosition:
                        displayed[i].hasLoadableUrl &&
                            activeTab == MediaLibraryTab.venueGallery
                        ? () => onAdjustPosition(displayed[i])
                        : null,
                    onSetFeatured:
                        activeTab == MediaLibraryTab.venueGallery &&
                            displayed[i].canBeFeatured &&
                            !displayed[i].isCover
                        ? () => onSetFeaturedForItem(displayed[i])
                        : null,
                    isSettingFeatured: settingFeaturedItemId == displayed[i].id,
                    showCoverColumn: showCoverColumn,
                    showCurrentColumn: showCurrentColumn,
                    showDivider: i < displayed.length - 1,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MediaUploadProgressBanner extends StatelessWidget {
  const _MediaUploadProgressBanner({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppSpacing.radiusMd,
      elevation: GlassElevation.soft,
      innerHighlight: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.cloud_upload_outlined,
                color: AppColors.primaryPink,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(
            minHeight: 4,
            color: AppColors.primaryPink,
            backgroundColor: AppColors.surfaceElevated.withValues(alpha: 0.8),
          ),
        ],
      ),
    );
  }
}

class _GalleryReorderDialog extends StatefulWidget {
  const _GalleryReorderDialog({required this.items});

  final List<VenueMediaItem> items;

  @override
  State<_GalleryReorderDialog> createState() => _GalleryReorderDialogState();
}

class _GalleryReorderDialogState extends State<_GalleryReorderDialog> {
  late final List<VenueMediaItem> _items = [...widget.items];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 620),
        child: GlassContainer(
          padding: const EdgeInsets.all(AppSpacing.xl),
          borderRadius: AppSpacing.radiusLg,
          elevation: GlassElevation.medium,
          innerHighlight: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Reorder Gallery',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Drag photos into the order customers should see them.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  itemCount: _items.length,
                  onReorderItem: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = _items.removeAt(oldIndex);
                      _items.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return ListTile(
                      key: ValueKey(item.id),
                      contentPadding: EdgeInsets.zero,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Image.network(
                            item.previewUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, error, stackTrace) =>
                                const ColoredBox(
                                  color: AppColors.surfaceElevated,
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                          ),
                        ),
                      ),
                      title: Text(
                        item.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        venueGalleryCategoryLabel(item.category),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      trailing: ReorderableDragStartListener(
                        index: index,
                        child: const Icon(
                          Icons.drag_handle_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: DrinkSpotButton(
                      label: 'Cancel',
                      compact: true,
                      variant: DrinkSpotButtonVariant.secondary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: DrinkSpotButton(
                      label: 'Save Order',
                      compact: true,
                      icon: Icons.check_rounded,
                      onPressed: () => Navigator.of(context).pop(_items),
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
}
