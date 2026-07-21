import 'package:flutter/material.dart';

import 'media_library_tab.dart';
import 'venue_page_quick_action.dart';

/// Page configuration for a media library tab within the Gallery page.
class MediaLibraryPageConfig {
  const MediaLibraryPageConfig({
    required this.tab,
    required this.primaryActionLabel,
    required this.primaryActionIcon,
    required this.quickActions,
    required this.tableTitle,
  });

  final MediaLibraryTab tab;
  final String primaryActionLabel;
  final IconData primaryActionIcon;
  final List<VenuePageQuickAction> quickActions;
  final String tableTitle;

  static MediaLibraryPageConfig forTab(MediaLibraryTab tab) {
    return switch (tab) {
      MediaLibraryTab.venueGallery => const MediaLibraryPageConfig(
        tab: MediaLibraryTab.venueGallery,
        primaryActionLabel: 'Upload Photos',
        primaryActionIcon: Icons.cloud_upload_outlined,
        tableTitle: 'Venue Gallery',
        quickActions: [
          VenuePageQuickAction(
            label: 'Upload Photos',
            icon: Icons.cloud_upload_outlined,
            actionKey: 'media_upload',
          ),
          VenuePageQuickAction(
            label: 'Reorder Gallery',
            icon: Icons.reorder_rounded,
            actionKey: 'media_reorder_gallery',
          ),
          VenuePageQuickAction(
            label: 'Set Featured Image',
            icon: Icons.star_outline_rounded,
            actionKey: 'media_set_cover',
          ),
          VenuePageQuickAction(
            label: 'Export Gallery List',
            icon: Icons.download_outlined,
            actionKey: 'media_export',
          ),
          VenuePageQuickAction(
            label: 'Delete Selected',
            icon: Icons.delete_outline_rounded,
            actionKey: 'media_delete_selected',
          ),
        ],
      ),
      MediaLibraryTab.brandAssets => const MediaLibraryPageConfig(
        tab: MediaLibraryTab.brandAssets,
        primaryActionLabel: 'Upload from Profile',
        primaryActionIcon: Icons.storefront_outlined,
        tableTitle: 'Brand Assets',
        quickActions: [
          VenuePageQuickAction(
            label: 'Delete Selected',
            icon: Icons.delete_outline_rounded,
            actionKey: 'media_delete_selected',
          ),
        ],
      ),
      MediaLibraryTab.dealImages => const MediaLibraryPageConfig(
        tab: MediaLibraryTab.dealImages,
        primaryActionLabel: 'Upload Images',
        primaryActionIcon: Icons.cloud_upload_outlined,
        tableTitle: 'Deal Images',
        quickActions: [
          VenuePageQuickAction(
            label: 'Upload Images',
            icon: Icons.cloud_upload_outlined,
            actionKey: 'media_upload',
          ),
          VenuePageQuickAction(
            label: 'Replace Image',
            icon: Icons.swap_horiz_rounded,
            actionKey: 'media_replace',
          ),
          VenuePageQuickAction(
            label: 'Export Image List',
            icon: Icons.download_outlined,
            actionKey: 'media_export',
          ),
          VenuePageQuickAction(
            label: 'Delete Selected',
            icon: Icons.delete_outline_rounded,
            actionKey: 'media_delete_selected',
          ),
        ],
      ),
      MediaLibraryTab.eventImages => const MediaLibraryPageConfig(
        tab: MediaLibraryTab.eventImages,
        primaryActionLabel: 'Upload Images',
        primaryActionIcon: Icons.cloud_upload_outlined,
        tableTitle: 'Event Images',
        quickActions: [
          VenuePageQuickAction(
            label: 'Upload Images',
            icon: Icons.cloud_upload_outlined,
            actionKey: 'media_upload',
          ),
          VenuePageQuickAction(
            label: 'Replace Image',
            icon: Icons.swap_horiz_rounded,
            actionKey: 'media_replace',
          ),
          VenuePageQuickAction(
            label: 'Export Image List',
            icon: Icons.download_outlined,
            actionKey: 'media_export',
          ),
          VenuePageQuickAction(
            label: 'Delete Selected',
            icon: Icons.delete_outline_rounded,
            actionKey: 'media_delete_selected',
          ),
        ],
      ),
    };
  }
}
