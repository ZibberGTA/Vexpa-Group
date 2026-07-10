import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/components/drinkspot_button.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/light_sweep_overlay.dart';
import '../../../shared/widgets/premium_effects.dart';
import '../models/venue_dashboard_tab.dart';
import 'venue_dashboard_controller.dart';

/// Upgrade prompt encouraging venue owners to explore premium plans.
class VenueDashboardGoPremiumPanel extends StatelessWidget {
  const VenueDashboardGoPremiumPanel({super.key});

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
              padding: const EdgeInsets.all(AppSpacing.lg + 2),
              borderRadius: AppSpacing.radiusLg - 1,
              opacity: 0.9,
              innerHighlight: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppColors.brandGradient.createShader(bounds),
                    child: Text(
                      AppStrings.venueDashboardGoPremiumTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    AppStrings.venueDashboardGoPremiumBody,
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.95),
                      fontSize: 13.5,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    AppStrings.venueDashboardGoPremiumTagline,
                    style: TextStyle(
                      color: AppColors.primaryPink.withValues(alpha: 0.92),
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  DrinkSpotButton(
                    label: AppStrings.venueDashboardUpgradePlan,
                    icon: Icons.workspace_premium_rounded,
                    compact: true,
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
