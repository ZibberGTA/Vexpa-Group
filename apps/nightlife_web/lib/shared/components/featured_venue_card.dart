import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/home/models/venue_preview.dart';
import '../../shared/widgets/light_sweep_overlay.dart';
import '../../shared/widgets/safe_venue_branding_image.dart';
import 'pill_tag.dart';

class FeaturedVenueCard extends StatefulWidget {
  const FeaturedVenueCard({super.key, required this.venue, this.onTap});

  final VenuePreview venue;
  final VoidCallback? onTap;

  @override
  State<FeaturedVenueCard> createState() => _FeaturedVenueCardState();
}

class _FeaturedVenueCardState extends State<FeaturedVenueCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.12, end: 0.24).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(0, _hovered ? -8.0 : 0, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryPink.withValues(
                    alpha: _hovered
                        ? _glowAnimation.value + 0.14
                        : _glowAnimation.value,
                  ),
                  blurRadius: _hovered ? 34 : 26,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: AppColors.primaryPurple.withValues(
                    alpha: _glowAnimation.value * 0.7,
                  ),
                  blurRadius: 28,
                  spreadRadius: -6,
                ),
              ],
            ),
            child: child,
          );
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            gradient: AppColors.brandGradient,
          ),
          child: Padding(
            padding: const EdgeInsets.all(1.4),
            child: Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg - 1),
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg - 1),
                hoverColor: Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _FeaturedBanner(venue: widget.venue),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
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
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
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
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
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
        ),
      ),
    );
  }
}

class _FeaturedBanner extends StatelessWidget {
  const _FeaturedBanner({required this.venue});

  final VenuePreview venue;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusLg - 1),
      ),
      child: SizedBox(
        height: 168,
        child: Stack(
          fit: StackFit.expand,
          children: [
            SafeVenueBrandingImage(
              url: venue.bannerImageUrl,
              fit: BoxFit.cover,
              fallback: _FeaturedGradient(venue: venue),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.background.withValues(alpha: 0.38),
                  ],
                ),
              ),
            ),
            const LightSweepOverlay(),
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.primaryPink.withValues(alpha: 0.55),
                  ),
                ),
                child: const Text(
                  'Featured Tonight',
                  style: TextStyle(
                    color: AppColors.primaryPink,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: const Text(
                  'Open tonight',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 11,
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

class _FeaturedGradient extends StatelessWidget {
  const _FeaturedGradient({required this.venue});

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
