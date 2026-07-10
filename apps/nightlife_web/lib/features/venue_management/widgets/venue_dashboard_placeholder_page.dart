import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/glass_container.dart';
import '../models/venue_dashboard_tab.dart';
import '../models/venue_dashboard_tab_content.dart';
import 'venue_dashboard_layout.dart';

/// Placeholder framework page for venue dashboard tabs awaiting full implementation.
class VenueDashboardPlaceholderPage extends StatelessWidget {
  const VenueDashboardPlaceholderPage({
    super.key,
    required this.tab,
  });

  final VenueDashboardTab tab;

  @override
  Widget build(BuildContext context) {
    final copy = tab.pageCopy;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: VenueDashboardLayout.contentMaxWidth,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => AppColors.brandGradient.createShader(bounds),
              child: Text(
                copy.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              copy.subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                height: 1.6,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            GlassContainer(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.xxxl,
              ),
              borderRadius: AppSpacing.radiusLg,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          color: AppColors.primaryPurple.withValues(alpha: 0.16),
                          border: Border.all(
                            color: AppColors.primaryPurple.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Icon(
                          tab.selectedIcon,
                          color: AppColors.primaryPink,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        copy.placeholderMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ],
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
