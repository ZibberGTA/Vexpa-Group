import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/components/drinkspot_button.dart';
import '../../../shared/components/public_page_hero.dart';
import '../../../shared/components/section_header.dart';
import '../../../shared/layouts/content_container.dart';
import '../../../shared/layouts/public_page_shell.dart';
import '../../../shared/widgets/glass_container.dart';

/// Business landing page for venue owners.
class BusinessLandingPage extends StatelessWidget {
  const BusinessLandingPage({super.key});

  static const _valueProps = [
    (
      icon: Icons.trending_up_rounded,
      title: 'Grow your venue',
      detail:
          'Put your venue in front of customers actively searching for tonight\'s plans.',
    ),
    (
      icon: Icons.groups_2_outlined,
      title: 'Reach more customers',
      detail:
          'Increase discoverability across search, map, deals, events and trails.',
    ),
    (
      icon: Icons.campaign_outlined,
      title: 'Venue Experience Discovery Advertising',
      detail:
          'Vexda helps venues grow through discovery — not just management.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return PublicPageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PublicPageHero(
            eyebrow: 'For venues',
            title: AppStrings.businessTitle,
            subtitle: AppStrings.businessSubtitle,
            trailing: Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                DrinkSpotButton(
                  label: 'Claim Your Venue',
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRouter.businessClaim),
                ),
                DrinkSpotButton(
                  label: 'View pricing',
                  variant: DrinkSpotButtonVariant.secondary,
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRouter.businessPricing),
                ),
              ],
            ),
          ),
          ContentContainer(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ..._valueProps.map(
                    (prop) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              prop.icon,
                              color: AppColors.primaryPink,
                              size: 28,
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    prop.title,
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    prop.detail,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                      height: 1.55,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SectionDivider(),
                  const SectionHeader(
                    title: 'Subscription overview',
                    subtitle:
                        'Flexible plans for every venue — launch with 50% off your first 12 months.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: DrinkSpotButton(
                      label: 'Compare plans',
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRouter.businessPricing,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
