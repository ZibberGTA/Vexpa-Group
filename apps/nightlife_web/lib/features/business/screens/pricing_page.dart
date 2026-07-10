import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/subscription_plans.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/components/drinkspot_button.dart';
import '../../../shared/components/public_page_hero.dart';
import '../../../shared/layouts/content_container.dart';
import '../../../shared/layouts/public_page_shell.dart';
import '../../../shared/widgets/glass_container.dart';

/// Subscription pricing comparison page.
class PricingPage extends StatelessWidget {
  const PricingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PublicPageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PublicPageHero(
            eyebrow: 'Pricing',
            title: AppStrings.pricingTitle,
            subtitle: AppStrings.pricingSubtitle,
          ),
          ContentContainer(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
              child: Column(
                children: [
                  GlassContainer(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.lg,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_offer_outlined,
                          color: AppColors.trailGold.withValues(alpha: 0.95),
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          SubscriptionPlans.launchDiscountLabel,
                          style: TextStyle(
                            color: AppColors.trailGold.withValues(alpha: 0.95),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 1000;
                      return Wrap(
                        spacing: AppSpacing.lg,
                        runSpacing: AppSpacing.lg,
                        alignment: WrapAlignment.center,
                        children: SubscriptionPlans.tiers
                            .map(
                              (plan) => SizedBox(
                                width: isWide ? 260 : double.infinity,
                                child: _PricingTierCard(plan: plan),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  DrinkSpotButton(
                    label: 'Claim Your Venue',
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRouter.businessClaim),
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

class _PricingTierCard extends StatelessWidget {
  const _PricingTierCard({required this.plan});

  final SubscriptionPlan plan;

  @override
  Widget build(BuildContext context) {
    final discounted = SubscriptionPlans.discountedPrice(plan.monthlyPriceGbp);

    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (plan.highlighted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: const Text(
                'Most popular',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (plan.highlighted) const SizedBox(height: AppSpacing.md),
          Text(
            plan.name,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            plan.audience,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '£$discounted',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '/mo',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          Text(
            '£${plan.monthlyPriceGbp}/mo after 12 months',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...plan.features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_rounded,
                    color: AppColors.primaryPink,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      feature,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 13.5,
                        height: 1.4,
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
