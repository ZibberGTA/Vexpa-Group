import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/home/models/trail_preview.dart';
import 'pill_tag.dart';

class TrailPreviewCard extends StatefulWidget {
  const TrailPreviewCard({
    super.key,
    required this.trail,
    this.onTap,
  });

  final TrailPreview trail;
  final VoidCallback? onTap;

  @override
  State<TrailPreviewCard> createState() => _TrailPreviewCardState();
}

class _TrailPreviewCardState extends State<TrailPreviewCard> {
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
            color: AppColors.primaryPurple.withValues(
              alpha: _hovered ? 0.65 : 0.28,
            ),
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: AppColors.primaryPurple.withValues(alpha: 0.16),
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
                _TrailBanner(trail: widget.trail),
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
                      Text(
                        widget.trail.name,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        widget.trail.area,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
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
                      const SizedBox(height: AppSpacing.sm),
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
    );
  }
}

class _TrailBanner extends StatelessWidget {
  const _TrailBanner({required this.trail});

  final TrailPreview trail;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusLg),
      ),
      child: SizedBox(
        height: 136,
        width: double.infinity,
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
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: const Text(
                  'Curated route',
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
