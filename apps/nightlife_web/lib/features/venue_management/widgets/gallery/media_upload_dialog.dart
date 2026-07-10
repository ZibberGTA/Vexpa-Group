import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/components/drinkspot_button.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../models/media_library_tab.dart';

class MediaUploadDraft {
  const MediaUploadDraft({required this.category, required this.caption});

  final String category;
  final String caption;
}

const kVenueGalleryCategories = <({String value, String label, IconData icon})>[
  (value: 'cover', label: 'Cover / Hero', icon: Icons.wallpaper_rounded),
  (value: 'interior', label: 'Interior', icon: Icons.chair_outlined),
  (value: 'drinks', label: 'Drinks', icon: Icons.local_bar_outlined),
  (value: 'food', label: 'Food', icon: Icons.restaurant_outlined),
  (value: 'events', label: 'Events', icon: Icons.celebration_outlined),
  (value: 'atmosphere', label: 'Atmosphere', icon: Icons.nightlife_outlined),
  (value: 'other', label: 'Other', icon: Icons.photo_library_outlined),
];

String venueGalleryCategoryLabel(String category) {
  final normalized = category.trim().toLowerCase();
  for (final option in kVenueGalleryCategories) {
    if (option.value == normalized) return option.label;
  }
  return 'Other';
}

/// Upload preview and metadata modal for media library items.
Future<MediaUploadDraft?> showMediaUploadDialog(
  BuildContext context, {
  required MediaLibraryTab tab,
  required int fileCount,
  required int remainingSlots,
  ImageProvider? previewImage,
}) {
  return showDialog<MediaUploadDraft>(
    context: context,
    builder: (context) => _MediaUploadDialog(
      tab: tab,
      fileCount: fileCount,
      remainingSlots: remainingSlots,
      previewImage: previewImage,
    ),
  );
}

class _MediaUploadDialog extends StatefulWidget {
  const _MediaUploadDialog({
    required this.tab,
    required this.fileCount,
    required this.remainingSlots,
    this.previewImage,
  });

  final MediaLibraryTab tab;
  final int fileCount;
  final int remainingSlots;
  final ImageProvider? previewImage;

  @override
  State<_MediaUploadDialog> createState() => _MediaUploadDialogState();
}

class _MediaUploadDialogState extends State<_MediaUploadDialog> {
  final TextEditingController _captionController = TextEditingController();
  String _category = 'interior';

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isGallery = widget.tab == MediaLibraryTab.venueGallery;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: GlassContainer(
          padding: const EdgeInsets.all(AppSpacing.xl),
          borderRadius: AppSpacing.radiusLg,
          elevation: GlassElevation.medium,
          innerHighlight: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isGallery ? 'Upload Gallery Photos' : 'Upload Images',
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Preview, categorise and publish ${widget.fileCount == 1 ? 'this image' : '${widget.fileCount} images'} to ${widget.tab.label}. '
                'You have ${widget.remainingSlots} ${widget.tab.emptyUnit} remaining on your plan.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (widget.previewImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: SizedBox(
                    height: 190,
                    child: Image(
                      image: widget.previewImage!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              if (widget.previewImage != null)
                const SizedBox(height: AppSpacing.lg),
              if (isGallery) ...[
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final option in kVenueGalleryCategories)
                      ChoiceChip(
                        selected: _category == option.value,
                        onSelected: (_) =>
                            setState(() => _category = option.value),
                        avatar: Icon(option.icon, size: 16),
                        label: Text(option.label),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              TextField(
                controller: _captionController,
                maxLength: 120,
                style: const TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  labelText: 'Caption (optional)',
                  hintText: isGallery
                      ? 'e.g. Neon-lit cocktail bar on Friday nights'
                      : 'Optional image note',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceElevated.withValues(alpha: 0.78),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: DrinkSpotButton(
                      label: 'Cancel',
                      variant: DrinkSpotButtonVariant.secondary,
                      compact: true,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: DrinkSpotButton(
                      label: 'Upload',
                      icon: Icons.cloud_upload_outlined,
                      compact: true,
                      onPressed: () => Navigator.of(context).pop(
                        MediaUploadDraft(
                          category: isGallery ? _category : 'other',
                          caption: _captionController.text.trim(),
                        ),
                      ),
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
