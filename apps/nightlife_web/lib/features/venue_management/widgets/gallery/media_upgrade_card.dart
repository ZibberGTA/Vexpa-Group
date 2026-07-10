import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/components/drinkspot_button.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/light_sweep_overlay.dart';
import '../../../../shared/widgets/premium_effects.dart';
import '../../models/venue_dashboard_tab.dart';
import '../venue_dashboard_controller.dart';

/// Upgrade prompt shown when Starter venues open the media centre.
class MediaUpgradeCard extends StatelessWidget {
  const MediaUpgradeCard({super.key});

  static const benefits = [
    '20 venue gallery photos',
    'Deal artwork',
    'Event banners',
    'Rich customer experience',
    'Increased customer engagement',
  ];

  @override
  Widget build(BuildContext context) {
    final selectTab = VenueDashboardController.maybeOf(context)?.selectTab;

    return PremiumGradientBorder(
      glow: true,
      borderRadius: AppSpacing.radiusLg,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg - 1),
        child: Stack(
          children: [
            GlassContainer(
              padding: const EdgeInsets.all(AppSpacing.xl),
              borderRadius: AppSpacing.radiusLg - 1,
              opacity: 0.92,
              innerHighlight: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppColors.brandGradient.createShader(bounds),
                    child: Text(
                      'Professional Feature',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Bring your venue to life with photos.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text(
                    'Professional includes:',
                    style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final benefit in benefits)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: AppColors.primaryPink.withValues(alpha: 0.95),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              benefit,
                              style: TextStyle(
                                color: AppColors.textSecondary.withValues(alpha: 0.98),
                                fontSize: 13.5,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  DrinkSpotButton(
                    label: 'Upgrade to Professional',
                    icon: Icons.workspace_premium_rounded,
                    onPressed: selectTab == null
                        ? null
                        : () => selectTab(VenueDashboardTab.subscription),
                  ),
                ],
              ),
            ),
            const Positioned.fill(child: LightSweepOverlay()),
          ],
        ),
      ),
    );
  }
}
