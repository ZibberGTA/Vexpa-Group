import '../domain/growth_action.dart';
import '../domain/growth_opportunity.dart';
import '../domain/growth_priority.dart';
import '../domain/upgrade_recommendation.dart';
import '../shared/growth_constants.dart';
import '../shared/growth_product_catalog.dart';

/// Upgrade recommendations based on plan catalog and adapter entitlement flags.
final class GrowthUpgradeService {
  const GrowthUpgradeService();

  UpgradeRecommendation? recommendVenueUpgrade({
    required String currentPlanId,
    required bool hasMediaCentreAccess,
    required bool hasAdvancedAnalyticsAccess,
    required bool hasCampaignToolsAccess,
  }) {
    final normalized = currentPlanId.trim().toLowerCase();
    if (normalized.isEmpty) {
      return _starterUpgrade();
    }

    if (!hasMediaCentreAccess &&
        normalized == GrowthConstants.defaultVenuePlanId) {
      return _professionalUpgrade(normalized);
    }

    if (!hasAdvancedAnalyticsAccess &&
        (normalized == GrowthConstants.defaultVenuePlanId ||
            normalized == GrowthConstants.professionalPlanId)) {
      final next = GrowthProductCatalog.nextVenuePlan(normalized);
      if (next == null) return null;
      return UpgradeRecommendation(
        currentPlanId: normalized,
        recommendedPlanId: next.id,
        title: 'Unlock ${next.name}',
        message: 'Upgrade for advanced analytics and stronger discovery tools.',
        benefits: next.features.take(4).toList(growable: false),
        priority: GrowthPriority.high,
      );
    }

    if (!hasCampaignToolsAccess &&
        normalized != GrowthConstants.premiumPlanId &&
        normalized != 'corporate') {
      final premium = GrowthProductCatalog.venuePlanById(
        GrowthConstants.premiumPlanId,
      );
      if (premium == null) return null;
      return UpgradeRecommendation(
        currentPlanId: normalized,
        recommendedPlanId: premium.id,
        title: 'Unlock campaign tools',
        message: 'Premium adds campaign and promotion tools for active venues.',
        benefits: premium.features.take(4).toList(growable: false),
        priority: GrowthPriority.medium,
      );
    }

    return null;
  }

  UpgradeRecommendation _starterUpgrade() {
    return _professionalUpgrade(GrowthConstants.defaultVenuePlanId);
  }

  UpgradeRecommendation _professionalUpgrade(String currentPlanId) {
    const benefits = [
      '20 venue gallery photos',
      'Deal artwork',
      'Event banners',
      'Rich customer experience',
      'Increased customer engagement',
    ];
    return UpgradeRecommendation(
      currentPlanId: currentPlanId,
      recommendedPlanId: GrowthConstants.professionalPlanId,
      title: 'Professional Feature',
      message: 'Bring your venue to life with photos.',
      benefits: benefits,
      priority: GrowthPriority.high,
    );
  }

  GrowthOpportunity? opportunityFromUpgrade(UpgradeRecommendation? upgrade) {
    if (upgrade == null) return null;
    return GrowthOpportunity(
      id: 'upgrade-${upgrade.recommendedPlanId}',
      title: upgrade.title,
      message: upgrade.message,
      action: GrowthAction.upgradeSubscription,
      priority: upgrade.priority,
      score: 90,
    );
  }

  static const mediaUpgradeBenefits = [
    '20 venue gallery photos',
    'Deal artwork',
    'Event banners',
    'Rich customer experience',
    'Increased customer engagement',
  ];
}
