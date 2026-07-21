import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/carousel_edge_fade.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/premium_effects.dart';
import '../../../../shared/widgets/venue_network_image.dart';
import '../../models/venue_media_item.dart';
import '../page/venue_dashboard_page_widgets.dart';
import 'media_table_widgets.dart';

/// Orders active gallery items for preview: featured first, no duplicates.
List<VenueMediaItem> orderGalleryPreviewItems(List<VenueMediaItem> items) {
  final seen = <String>{};
  final ordered = <VenueMediaItem>[];
  for (final item in items) {
    if (!seen.add(item.id)) continue;
    ordered.add(item);
  }

  final featured = ordered.where((item) => item.isCover).toList();
  final rest = ordered.where((item) => !item.isCover).toList();
  return [...featured, ...rest];
}

/// Compact horizontal preview of active venue gallery images.
class VenueGalleryPreviewCarousel extends StatelessWidget {
  const VenueGalleryPreviewCarousel({super.key, required this.items});

  final List<VenueMediaItem> items;

  @override
  Widget build(BuildContext context) {
    final previewItems = orderGalleryPreviewItems(items);

    return VenuePageSection(
      title: 'Venue Gallery Preview',
      child: GlassContainer(
        padding: const EdgeInsets.all(AppSpacing.md),
        borderRadius: AppSpacing.radiusLg,
        elevation: GlassElevation.soft,
        innerHighlight: true,
        child: previewItems.isEmpty
            ? const _GalleryPreviewEmptyState()
            : _GalleryPreviewScroller(items: previewItems),
      ),
    );
  }
}

class _GalleryPreviewEmptyState extends StatelessWidget {
  const _GalleryPreviewEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.sm,
      ),
      child: Text(
        'Uploaded Venue Gallery images will appear here.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.textSecondary.withValues(alpha: 0.95),
          fontSize: 14,
          height: 1.45,
        ),
      ),
    );
  }
}

class _GalleryPreviewScroller extends StatefulWidget {
  const _GalleryPreviewScroller({required this.items});

  final List<VenueMediaItem> items;

  @override
  State<_GalleryPreviewScroller> createState() =>
      _GalleryPreviewScrollerState();
}

class _GalleryPreviewScrollerState extends State<_GalleryPreviewScroller> {
  late final ScrollController _controller;
  bool _hovered = false;
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _onScroll();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  bool get _isScrollPositionReady {
    if (!_controller.hasClients) return false;
    return _controller.position.hasContentDimensions;
  }

  void _onScroll() {
    if (!mounted || !_isScrollPositionReady) return;

    final position = _controller.position;
    final offset = position.pixels;
    final max = position.maxScrollExtent;
    final nextLeft = offset > 4;
    final nextRight = offset < max - 4;
    if (nextLeft != _canScrollLeft || nextRight != _canScrollRight) {
      setState(() {
        _canScrollLeft = nextLeft;
        _canScrollRight = nextRight;
      });
    }
  }

  void _scrollBy(double delta) {
    if (!_isScrollPositionReady) return;

    final position = _controller.position;
    final target = (position.pixels + delta).clamp(
      0.0,
      position.maxScrollExtent,
    );
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _GalleryPreviewMetrics.resolve(
          context,
          constraints.maxWidth,
          widget.items.length,
        );
        final needsScroll = metrics.needsScroll;
        final showArrows = Breakpoints.isDesktop(context) && needsScroll;

        final scroller = Listener(
          onPointerSignal: (signal) {
            if (!needsScroll) return;
            if (signal is PointerScrollEvent && signal.scrollDelta.dy != 0) {
              _scrollBy(signal.scrollDelta.dy);
            }
          },
          child: ListView.separated(
            key: const Key('venue-gallery-preview-list'),
            controller: _controller,
            scrollDirection: Axis.horizontal,
            physics: needsScroll
                ? const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  )
                : const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: widget.items.length,
            separatorBuilder: (_, _) => SizedBox(width: metrics.spacing),
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return SizedBox(
                width: metrics.cardWidth,
                child: _GalleryPreviewCard(
                  key: ValueKey('gallery-preview-${item.id}'),
                  item: item,
                  height: metrics.cardHeight,
                ),
              );
            },
          ),
        );

        return MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: SizedBox(
            height: metrics.cardHeight,
            width: double.infinity,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: needsScroll
                      ? CarouselEdgeFade(
                          showLeftEdge: _canScrollLeft,
                          showRightEdge: _canScrollRight,
                          surfaceTintColor: AppColors.surface,
                          child: scroller,
                        )
                      : scroller,
                ),
                if (showArrows) ...[
                  _GalleryPreviewScrollArrow(
                    visible: _hovered && _canScrollLeft,
                    alignment: Alignment.centerLeft,
                    icon: Icons.chevron_left_rounded,
                    onTap: () => _scrollBy(-metrics.cardWidth * 0.85),
                  ),
                  _GalleryPreviewScrollArrow(
                    visible: _hovered && _canScrollRight,
                    alignment: Alignment.centerRight,
                    icon: Icons.chevron_right_rounded,
                    onTap: () => _scrollBy(metrics.cardWidth * 0.85),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GalleryPreviewMetrics {
  const _GalleryPreviewMetrics({
    required this.cardWidth,
    required this.cardHeight,
    required this.spacing,
    required this.needsScroll,
  });

  final double cardWidth;
  final double cardHeight;
  final double spacing;
  final bool needsScroll;

  static const _aspectRatio = 4 / 3;
  static const _minCardWidth = 148.0;
  static const _maxCardWidth = 272.0;

  static _GalleryPreviewMetrics resolve(
    BuildContext context,
    double viewportWidth,
    int itemCount,
  ) {
    final spacing = AppSpacing.md;
    if (itemCount <= 0 || viewportWidth <= 0) {
      return const _GalleryPreviewMetrics(
        cardWidth: 0,
        cardHeight: 0,
        spacing: AppSpacing.md,
        needsScroll: false,
      );
    }

    final cardsVisible = switch (Breakpoints.of(context)) {
      ScreenSize.desktop => 3.6,
      ScreenSize.tablet => 2.4,
      ScreenSize.mobile => 1.35,
    };

    final cardWidth =
        ((viewportWidth - (spacing * (cardsVisible - 1))) / cardsVisible).clamp(
          _minCardWidth,
          _maxCardWidth,
        );
    final cardHeight = cardWidth / _aspectRatio;
    final contentWidth = (itemCount * cardWidth) + ((itemCount - 1) * spacing);
    final needsScroll = contentWidth > viewportWidth + 1;

    return _GalleryPreviewMetrics(
      cardWidth: cardWidth,
      cardHeight: cardHeight,
      spacing: spacing,
      needsScroll: needsScroll,
    );
  }
}

class _GalleryPreviewCard extends StatefulWidget {
  const _GalleryPreviewCard({
    super.key,
    required this.item,
    required this.height,
  });

  final VenueMediaItem item;
  final double height;

  @override
  State<_GalleryPreviewCard> createState() => _GalleryPreviewCardState();
}

class _GalleryPreviewCardState extends State<_GalleryPreviewCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final featured = item.isCover;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered && Breakpoints.isDesktop(context) ? 1.02 : 1,
        duration: PremiumEffects.fast,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: item.hasLoadableUrl
                ? () => showVenueMediaItemPreviewOverlay(context, item)
                : null,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Ink(
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: featured
                      ? AppColors.primaryPink.withValues(alpha: 0.85)
                      : AppColors.glassBorder.withValues(alpha: 0.55),
                  width: featured ? 1.6 : 1,
                ),
                boxShadow: featured
                    ? [
                        BoxShadow(
                          color: AppColors.primaryPink.withValues(alpha: 0.18),
                          blurRadius: 14,
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd - 1),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (item.hasLoadableUrl)
                      VenueNetworkImage(
                        url: item.previewUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorWidget: const _GalleryPreviewImageFallback(),
                      )
                    else
                      const _GalleryPreviewImageFallback(),
                    if (featured)
                      Positioned(
                        left: AppSpacing.sm,
                        top: AppSpacing.sm,
                        child: _FeaturedBadge(),
                      ),
                    if (_hovered && Breakpoints.isDesktop(context))
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.primaryPink.withValues(
                              alpha: 0.08,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: AppColors.primaryPink.withValues(alpha: 0.65),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_rounded,
              size: 14,
              color: AppColors.primaryPink.withValues(alpha: 0.95),
            ),
            const SizedBox(width: 4),
            Text(
              'Featured',
              style: TextStyle(
                color: AppColors.primaryPink.withValues(alpha: 0.95),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryPreviewImageFallback extends StatelessWidget {
  const _GalleryPreviewImageFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.88),
        border: Border.all(color: AppColors.glassBorder.withValues(alpha: 0.5)),
      ),
      child: const Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: AppColors.textSecondary,
          size: 28,
        ),
      ),
    );
  }
}

class _GalleryPreviewScrollArrow extends StatelessWidget {
  const _GalleryPreviewScrollArrow({
    required this.visible,
    required this.alignment,
    required this.icon,
    required this.onTap,
  });

  final bool visible;
  final Alignment alignment;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        child: IgnorePointer(
          ignoring: !visible,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.88),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryPurple.withValues(alpha: 0.45),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.background.withValues(alpha: 0.45),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Icon(icon, color: AppColors.white, size: 22),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
