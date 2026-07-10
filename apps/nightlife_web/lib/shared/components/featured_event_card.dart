import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/home/models/event_preview.dart';
import '../../shared/widgets/light_sweep_overlay.dart';
import 'pill_tag.dart';

class FeaturedEventCard extends StatefulWidget {
  const FeaturedEventCard({
    super.key,
    required this.event,
    this.onTap,
  });

  final EventPreview event;
  final VoidCallback? onTap;

  @override
  State<FeaturedEventCard> createState() => _FeaturedEventCardState();
}

class _FeaturedEventCardState extends State<FeaturedEventCard>
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
    _glowAnimation = Tween<double>(begin: 0.10, end: 0.22).animate(
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
            transform: Matrix4.translationValues(0, _hovered ? -8.0 : 0, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryPurple.withValues(
                    alpha: _hovered
                        ? _glowAnimation.value + 0.12
                        : _glowAnimation.value,
                  ),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
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
              colors: [
                AppColors.primaryPurple.withValues(alpha: 0.8),
                AppColors.primaryPink.withValues(alpha: 0.65),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(1.3),
            child: Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg - 1),
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg - 1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Banner(event: widget.event),
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
                            widget.event.name,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            widget.event.venue,
                            style: const TextStyle(
                              color: AppColors.primaryPink,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.event.area,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              for (var i = 0; i < widget.event.tags.length; i++)
                                PillTag(
                                  label: widget.event.tags[i],
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

class _Banner extends StatelessWidget {
  const _Banner({required this.event});

  final EventPreview event;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusLg - 1),
      ),
      child: SizedBox(
        height: 156,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: event.imageGradient,
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
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: const Text(
                  'Featured Tonight',
                  style: TextStyle(
                    color: AppColors.white,
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryPink,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      event.time,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
