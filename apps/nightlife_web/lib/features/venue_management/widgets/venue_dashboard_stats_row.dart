import 'package:flutter/material.dart';

import '../../../core/constants/breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/premium_effects.dart';
import '../models/venue_dashboard_date_range.dart';
import '../models/venue_dashboard_stat.dart';

/// Responsive row of venue analytics statistic cards.
class VenueDashboardStatsRow extends StatelessWidget {
  const VenueDashboardStatsRow({
    super.key,
    required this.stats,
    required this.dateRange,
  });

  final List<VenueDashboardStat> stats;
  final VenueDashboardDateRange dateRange;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.md;
        const minCardWidth = 148.0;
        final available = constraints.maxWidth;
        final fitsInOneRow =
            available >= (minCardWidth * stats.length) + (gap * (stats.length - 1));

        if (fitsInOneRow) {
          return Row(
            children: [
              for (var i = 0; i < stats.length; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                Expanded(
                  child: VenueDashboardStatCard(
                    stat: stats[i],
                    dateRange: dateRange,
                  ),
                ),
              ],
            ],
          );
        }

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: stats
              .map(
                (stat) => SizedBox(
                  width: Breakpoints.isMobile(context)
                      ? available
                      : (available - gap) / 2,
                  child: VenueDashboardStatCard(
                    stat: stat,
                    dateRange: dateRange,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

/// Glass analytics metric card for the venue dashboard home screen.
class VenueDashboardStatCard extends StatefulWidget {
  const VenueDashboardStatCard({
    super.key,
    required this.stat,
    required this.dateRange,
  });

  final VenueDashboardStat stat;
  final VenueDashboardDateRange dateRange;

  @override
  State<VenueDashboardStatCard> createState() => _VenueDashboardStatCardState();
}

class _VenueDashboardStatCardState extends State<VenueDashboardStatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final stat = widget.stat;
    final positive = stat.isPositive;
    final changeColor = positive ? AppColors.primaryPink : const Color(0xFFEF6B6B);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.02 : 1,
        duration: PremiumEffects.fast,
        curve: PremiumEffects.easeOut,
        child: PremiumGradientBorder(
          subtle: true,
          glow: _hovered,
          borderRadius: AppSpacing.radiusLg,
          child: GlassContainer(
            padding: const EdgeInsets.all(AppSpacing.lg + 2),
            borderRadius: AppSpacing.radiusLg - 1,
            opacity: _hovered ? 0.86 : 0.78,
            elevation: _hovered ? GlassElevation.soft : GlassElevation.none,
            innerHighlight: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        stat.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    PremiumIconBadge(
                      icon: stat.icon,
                      highlighted: _hovered,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                AnimatedStatValue(
                  value: stat.value,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                    height: 1.05,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm + 2),
                Row(
                  children: [
                    if (stat.hasComparison) ...[
                      Icon(
                        positive
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 14,
                        color: changeColor,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Expanded(
                      child: Text(
                        stat.subtitleLabel(widget.dateRange),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: stat.hasComparison
                              ? changeColor
                              : AppColors.textSecondary.withValues(alpha: 0.88),
                          fontWeight: FontWeight.w500,
                          fontSize: 11.5,
                          height: 1.35,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
