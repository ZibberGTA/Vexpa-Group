import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/constants/breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'home_section.dart';

/// Marketing statistics strip with placeholder numbers.
class HomeStatsStrip extends StatelessWidget {
  const HomeStatsStrip({super.key});

  static const _stats = [
    (value: '10,000+', label: 'Venues', icon: Icons.storefront_outlined),
    (value: '5,000+', label: 'Events every month', icon: Icons.event_outlined),
    (value: '20,000+', label: 'Drinks & deals', icon: Icons.local_bar_outlined),
    (value: '100,000+', label: 'Happy explorers', icon: Icons.groups_2_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final isDesktop = Breakpoints.isDesktop(context);

    return HomeSection(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: isMobile ? AppSpacing.xl : (isDesktop ? 18 : AppSpacing.lg),
              horizontal: isMobile ? AppSpacing.lg : AppSpacing.xxl,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              color: AppColors.surface.withValues(alpha: 0.55),
              border: Border.all(
                color: AppColors.primaryPurple.withValues(alpha: 0.25),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                if (isWide) {
                  return Row(
                    children: [
                      for (var i = 0; i < _stats.length; i++) ...[
                        if (i > 0)
                          Container(
                            width: 1,
                            height: isDesktop ? 58 : 72,
                            margin: EdgeInsets.symmetric(
                              horizontal: isDesktop ? AppSpacing.md : AppSpacing.lg,
                            ),
                            color: AppColors.primaryPurple.withValues(alpha: 0.25),
                          ),
                        Expanded(child: _StatItem(stat: _stats[i], compact: isDesktop)),
                      ],
                    ],
                  );
                }

                return Column(
                  children: [
                    for (var i = 0; i < _stats.length; i++) ...[
                      if (i > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                          child: Divider(
                            color: AppColors.primaryPurple.withValues(alpha: 0.2),
                            height: 1,
                          ),
                        ),
                      _StatItem(stat: _stats[i], compact: false),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.stat, required this.compact});

  final ({String value, String label, IconData icon}) stat;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          stat.icon,
          color: AppColors.primaryPink.withValues(alpha: 0.85),
          size: compact ? 26 : 22,
        ),
        SizedBox(height: compact ? 6 : AppSpacing.sm),
        ShaderMask(
          shaderCallback: (bounds) => AppColors.brandGradient.createShader(bounds),
          child: Text(
            stat.value,
            style: TextStyle(
              color: AppColors.white,
              fontSize: compact ? 26 : 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        SizedBox(height: compact ? 4 : AppSpacing.xs),
        Text(
          stat.label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
