import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/home/models/venue_preview.dart';
import '../widgets/safe_venue_branding_image.dart';
import 'pill_tag.dart';

class VenuePreviewCard extends StatefulWidget {
  const VenuePreviewCard({super.key, required this.venue, this.onTap});

  final VenuePreview venue;
  final VoidCallback? onTap;

  @override
  State<VenuePreviewCard> createState() => _VenuePreviewCardState();
}

class _VenuePreviewCardState extends State<VenuePreviewCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovered ? -6.0 : 0, 0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: _hovered
                ? AppColors.primaryPurple.withValues(alpha: 0.65)
                : AppColors.primaryPurple.withValues(alpha: 0.28),
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: AppColors.primaryPink.withValues(alpha: 0.14),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            hoverColor: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ImageArea(venue: widget.venue, hovered: _hovered),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.venue.name,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          _RatingBadge(rating: widget.venue.rating),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        widget.venue.area,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (var i = 0; i < widget.venue.tags.length; i++)
                            PillTag(
                              label: widget.venue.tags[i],
                              highlighted: i == 0,
                            ),
                        ],
                      ),
                    ],
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

class _ImageArea extends StatelessWidget {
  const _ImageArea({required this.venue, required this.hovered});

  final VenuePreview venue;
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusLg),
      ),
      child: SizedBox(
        height: 132,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            SafeVenueBrandingImage(
              url: venue.bannerImageUrl,
              fit: BoxFit.cover,
              fallback: _PreviewGradient(venue: venue),
            ),
            Positioned(
              top: -20,
              right: -20,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white.withValues(
                    alpha: hovered ? 0.10 : 0.06,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: const Text(
                  'Open tonight',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewGradient extends StatelessWidget {
  const _PreviewGradient({required this.venue});

  final VenuePreview venue;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: venue.imageGradient,
        ),
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            size: 14,
            color: AppColors.primaryPink,
          ),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
