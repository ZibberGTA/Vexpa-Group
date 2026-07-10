import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/positioned_venue_image.dart';
import '../../../venues/models/image_position_metadata.dart';
import '../../../venues/models/venue_model.dart';
import '../../models/venue_details_view.dart';
import '../shared/venue_section_primitives.dart';

/// Responsive venue gallery with category filters and full-screen viewing.
class VenueGallerySection extends StatelessWidget {
  const VenueGallerySection({super.key, required this.venue, this.anchorKey});

  final VenueDetailsView venue;
  final Key? anchorKey;

  @override
  Widget build(BuildContext context) {
    return VenueSectionShell(
      anchorKey: anchorKey,
      title: 'Gallery',
      subtitle: 'Step inside before you arrive.',
      child: venue.hasGallery
          ? _InteractiveGalleryGrid(
              images: _galleryImagesForVenue(venue),
              coverPosition: venue.galleryCoverPosition,
            )
          : const VenueEmptyState(
              icon: Icons.photo_library_outlined,
              title: 'Gallery coming soon',
              message:
                  'This venue has not published gallery images yet. Check back later for a look inside.',
            ),
    );
  }
}

class _InteractiveGalleryGrid extends StatefulWidget {
  const _InteractiveGalleryGrid({required this.images, this.coverPosition});

  final List<VenueGalleryImageData> images;
  final ImagePositionMetadata? coverPosition;

  @override
  State<_InteractiveGalleryGrid> createState() =>
      _InteractiveGalleryGridState();
}

class _InteractiveGalleryGridState extends State<_InteractiveGalleryGrid> {
  String _category = 'all';

  @override
  Widget build(BuildContext context) {
    final images = widget.images
        .where((image) => image.imageUrl.trim().isNotEmpty)
        .take(12)
        .toList();
    if (images.isEmpty) return const SizedBox.shrink();

    final categories = <String>{
      'all',
      for (final image in images) image.category,
    }.toList();
    final filtered = _category == 'all'
        ? images
        : images.where((image) => image.category == _category).toList();
    final featured = filtered.first;
    final remainder = filtered.skip(1).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GalleryCategoryChips(
          categories: categories,
          selected: _category,
          onSelected: (category) => setState(() => _category = category),
        ),
        const SizedBox(height: AppSpacing.md),
        _GalleryImage(
          image: featured,
          height: 320,
          featured: true,
          metadata: featured.isCover ? widget.coverPosition : null,
          onTap: () => _openLightbox(context, filtered, 0),
        ),
        if (remainder.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 900 ? 3 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: remainder.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.35,
                ),
                itemBuilder: (context, index) {
                  final image = remainder[index];
                  return _GalleryImage(
                    image: image,
                    height: 180,
                    onTap: () => _openLightbox(context, filtered, index + 1),
                  );
                },
              );
            },
          ),
        ],
      ],
    );
  }

  void _openLightbox(
    BuildContext context,
    List<VenueGalleryImageData> images,
    int initialIndex,
  ) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.82),
      builder: (context) =>
          _GalleryLightbox(images: images, initialIndex: initialIndex),
    );
  }
}

class _GalleryCategoryChips extends StatelessWidget {
  const _GalleryCategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final category in categories)
          ChoiceChip(
            selected: selected == category,
            onSelected: (_) => onSelected(category),
            label: Text(_categoryLabel(category)),
          ),
      ],
    );
  }
}

class _GalleryImage extends StatefulWidget {
  const _GalleryImage({
    required this.image,
    required this.height,
    this.featured = false,
    this.metadata,
    this.onTap,
  });

  final VenueGalleryImageData image;
  final double height;
  final bool featured;
  final ImagePositionMetadata? metadata;
  final VoidCallback? onTap;

  @override
  State<_GalleryImage> createState() => _GalleryImageState();
}

class _GalleryImageState extends State<_GalleryImage> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.015 : 1,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: SizedBox(
              height: widget.height,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FramedVenueImage(
                    imageUrl: widget.image.previewUrl,
                    metadata: widget.metadata,
                    fallback: Container(
                      color: AppColors.surfaceElevated,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: _hovered ? 1 : 0.65,
                    duration: const Duration(milliseconds: 180),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.background.withValues(alpha: 0.55),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    bottom: AppSpacing.lg,
                    child: _GalleryImageCaption(
                      label: widget.featured
                          ? 'Featured image'
                          : _categoryLabel(widget.image.category),
                      caption: widget.image.caption,
                    ),
                  ),
                  if (_hovered)
                    const Positioned(
                      top: AppSpacing.md,
                      right: AppSpacing.md,
                      child: Icon(
                        Icons.open_in_full_rounded,
                        color: AppColors.white,
                        size: 18,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GalleryImageCaption extends StatelessWidget {
  const _GalleryImageCaption({required this.label, required this.caption});

  final String label;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final text = caption.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (text.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}

class _GalleryLightbox extends StatefulWidget {
  const _GalleryLightbox({required this.images, required this.initialIndex});

  final List<VenueGalleryImageData> images;
  final int initialIndex;

  @override
  State<_GalleryLightbox> createState() => _GalleryLightboxState();
}

class _GalleryLightboxState extends State<_GalleryLightbox> {
  late int _index = widget.initialIndex.clamp(0, widget.images.length - 1);

  @override
  Widget build(BuildContext context) {
    final image = widget.images[_index];

    return Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      child: Image.network(
                        image.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.textSecondary,
                              size: 48,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    image.caption.trim().isEmpty
                        ? _categoryLabel(image.category)
                        : image.caption.trim(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.lg,
            right: AppSpacing.lg,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, color: AppColors.white),
            ),
          ),
          if (widget.images.length > 1) ...[
            Positioned(
              left: AppSpacing.lg,
              top: 0,
              bottom: 0,
              child: IconButton(
                onPressed: () => setState(
                  () => _index = (_index - 1) % widget.images.length,
                ),
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.white,
                  size: 42,
                ),
              ),
            ),
            Positioned(
              right: AppSpacing.lg,
              top: 0,
              bottom: 0,
              child: IconButton(
                onPressed: () => setState(
                  () => _index = (_index + 1) % widget.images.length,
                ),
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.white,
                  size: 42,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

List<VenueGalleryImageData> _galleryImagesForVenue(VenueDetailsView venue) {
  if (venue.galleryImages.isNotEmpty) return venue.galleryImages;
  return venue.galleryImageUrls
      .where((url) => url.trim().isNotEmpty)
      .toList()
      .asMap()
      .entries
      .map(
        (entry) => VenueGalleryImageData(
          imageId: 'legacy-${entry.key}',
          imageUrl: entry.value,
          thumbnailUrl: entry.value,
          category: entry.key == 0 ? 'cover' : 'other',
          isCover: entry.key == 0,
          sortOrder: entry.key,
        ),
      )
      .toList();
}

String _categoryLabel(String category) {
  return switch (category) {
    'cover' => 'Cover',
    'interior' => 'Interior',
    'drinks' => 'Drinks',
    'food' => 'Food',
    'events' => 'Events',
    'atmosphere' => 'Atmosphere',
    'all' => 'All',
    _ => 'Other',
  };
}
