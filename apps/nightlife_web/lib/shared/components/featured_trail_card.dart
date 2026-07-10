import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/home/models/trail_preview.dart';
import '../../shared/widgets/light_sweep_overlay.dart';
import 'pill_tag.dart';

class FeaturedTrailCard extends StatefulWidget {
  const FeaturedTrailCard({
    super.key,
    required this.trail,
    this.onTap,
  });

  final TrailPreview trail;
  final VoidCallback? onTap;

  @override
  State<FeaturedTrailCard> createState() => _FeaturedTrailCardState();
}

class _FeaturedTrailCardState extends State<FeaturedTrailCard>
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
    _glowAnimation = Tween<double>(begin: 0.14, end: 0.28).animate(
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
                  color: AppColors.trailGold.withValues(
                    alpha: _hovered
                        ? _glowAnimation.value + 0.12
                        : _glowAnimation.value,
                  ),
                  blurRadius: _hovered ? 36 : 28,
                  spreadRadius: -2,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: AppColors.primaryPink.withValues(
                    alpha: _glowAnimation.value * 0.65,
                  ),
                  blurRadius: 24,
                  spreadRadius: -6,
                ),
                BoxShadow(
                  color: AppColors.primaryPurple.withValues(
                    alpha: _glowAnimation.value * 0.55,
                  ),
                  blurRadius: 32,
                  spreadRadius: -8,
                ),
              ],
            ),
            child: child,
          );
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.trailGold.withValues(alpha: 0.75),
                AppColors.primaryPink.withValues(alpha: 0.55),
                AppColors.primaryPurple.withValues(alpha: 0.75),
              ],
            ),
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
                    _FeaturedBanner(trail: widget.trail),
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
                          Text(
                            widget.trail.name,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            widget.trail.area,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              _MetaChip(
                                icon: Icons.place_outlined,
                                label: '${widget.trail.stops} stops',
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              _MetaChip(
                                icon: Icons.schedule_rounded,
                                label: widget.trail.duration,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              for (var i = 0; i < widget.trail.tags.length; i++)
                                PillTag(
                                  label: widget.trail.tags[i],
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
  const _FeaturedBanner({required this.trail});

  final TrailPreview trail;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusLg - 1),
      ),
      child: SizedBox(
        height: 176,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: trail.imageGradient,
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.background.withValues(alpha: 0.35),
                  ],
                ),
              ),
            ),
            const LightSweepOverlay(),
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.trailGold.withValues(alpha: 0.65),
                  ),
                ),
                child: const Text(
                  'Featured Tonight',
                  style: TextStyle(
                    color: AppColors.trailGold,
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
              right: 14,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: const Icon(
                      Icons.route_rounded,
                      color: AppColors.trailGold,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Text(
                      "Tonight's curated trail",
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
