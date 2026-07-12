import '../domain/growth_action.dart';
import '../domain/growth_priority.dart';
import '../domain/subscription_recommendation.dart';
import '../domain/upgrade_recommendation.dart';
import '../shared/growth_formatting.dart';
import '../shared/growth_ordering.dart';
import '../shared/growth_product_catalog.dart';
import 'growth_comparison_service.dart';
import 'growth_upgrade_service.dart';

/// Subscription upgrade, downgrade, renewal, trial, and product summaries.
final class GrowthSubscriptionService {
  const GrowthSubscriptionService({
    GrowthUpgradeService upgradeService = const GrowthUpgradeService(),
    GrowthComparisonService comparisonService = const GrowthComparisonService(),
  }) : _upgradeService = upgradeService,
       _comparisonService = comparisonService;

  final GrowthUpgradeService _upgradeService;
  final GrowthComparisonService _comparisonService;

  UpgradeRecommendation? recommendUpgrade({
    required String currentPlanId,
    required bool hasMediaCentreAccess,
    required bool hasAdvancedAnalyticsAccess,
    required bool hasCampaignToolsAccess,
  }) {
    return _upgradeService.recommendVenueUpgrade(
      currentPlanId: currentPlanId,
      hasMediaCentreAccess: hasMediaCentreAccess,
      hasAdvancedAnalyticsAccess: hasAdvancedAnalyticsAccess,
      hasCampaignToolsAccess: hasCampaignToolsAccess,
    );
  }

  SubscriptionRecommendation? recommendDowngrade({
    required String currentPlanId,
    required bool underutilizedPremiumFeatures,
    required int activeVenueCount,
  }) {
    final normalized = currentPlanId.trim().toLowerCase();
    if (!underutilizedPremiumFeatures) return null;
    if (normalized == 'starter' || normalized == 'free') return null;

    final previousIndex = GrowthProductCatalog.webVenuePlans.indexWhere(
      (plan) => plan.id == normalized,
    );
    if (previousIndex <= 0) return null;

    if (normalized == 'corporate' && activeVenueCount <= 3) {
      final target = GrowthProductCatalog.webVenuePlans[previousIndex - 1];
      return SubscriptionRecommendation(
        kind: SubscriptionRecommendationKind.downgrade,
        planId: normalized,
        targetPlanId: target.id,
        title: 'Consider ${target.name}',
        message:
            'You may not need Corporate features for $activeVenueCount venue(s).',
        action: GrowthAction.upgradeSubscription,
        priority: GrowthPriority.low,
      );
    }

    if (normalized == 'premium' && activeVenueCount <= 1) {
      const targetId = 'professional';
      return SubscriptionRecommendation(
        kind: SubscriptionRecommendationKind.downgrade,
        planId: normalized,
        targetPlanId: targetId,
        title: 'Right-size to Professional',
        message: 'Premium campaign tools are unused on a single-venue account.',
        action: GrowthAction.upgradeSubscription,
        priority: GrowthPriority.low,
      );
    }

    return null;
  }

  SubscriptionRecommendation? recommendRenewal({
    required String currentPlanId,
    required int daysUntilExpiry,
    required int growthScoreValue,
  }) {
    if (daysUntilExpiry < 0) return null;
    if (daysUntilExpiry > 30) return null;

    final urgency = daysUntilExpiry <= 7
        ? GrowthPriority.high
        : GrowthPriority.medium;
    return SubscriptionRecommendation(
      kind: SubscriptionRecommendationKind.renewal,
      planId: currentPlanId.trim().toLowerCase(),
      title: daysUntilExpiry <= 7
          ? 'Renew before your plan expires'
          : 'Renewal coming up',
      message: growthScoreValue >= 60
          ? 'Your venue is performing well — renew to keep momentum.'
          : 'Renew now and use growth tools to improve visibility.',
      action: GrowthAction.upgradeSubscription,
      priority: urgency,
    );
  }

  SubscriptionRecommendation? recommendTrial({
    required bool hasActiveSubscription,
    required bool hasPublishedContent,
  }) {
    if (hasActiveSubscription) return null;
    if (!hasPublishedContent) return null;

    return const SubscriptionRecommendation(
      kind: SubscriptionRecommendationKind.trial,
      planId: 'starter',
      targetPlanId: 'professional',
      title: 'Try Professional features',
      message:
          'Your venue is live — unlock gallery, events and stronger discovery.',
      action: GrowthAction.upgradeSubscription,
      priority: GrowthPriority.high,
    );
  }

  List<GrowthVenuePlanProduct> comparePlans({required String currentPlanId}) {
    return _comparisonService.compareVenuePlans(currentPlanId: currentPlanId);
  }

  GrowthProductSummary? productSummary(String planId) {
    final plan = GrowthProductCatalog.venuePlanById(planId);
    if (plan == null) return null;
    return GrowthProductSummary(
      planId: plan.id,
      name: plan.name,
      audience: plan.audience,
      monthlyPriceGbp: plan.monthlyPriceGbp,
      discountedMonthlyPriceGbp:
          GrowthFormatting.discountedLaunchPriceGbp(plan.monthlyPriceGbp),
      features: plan.features,
      highlighted: plan.highlighted,
    );
  }

  List<SubscriptionRecommendation> subscriptionRecommendations({
    required String currentPlanId,
    required bool hasMediaCentreAccess,
    required bool hasAdvancedAnalyticsAccess,
    required bool hasCampaignToolsAccess,
    required bool underutilizedPremiumFeatures,
    required int activeVenueCount,
    required int daysUntilExpiry,
    required int growthScoreValue,
    required bool hasActiveSubscription,
    required bool hasPublishedContent,
  }) {
    final items = <SubscriptionRecommendation>[];

    final upgrade = recommendUpgrade(
      currentPlanId: currentPlanId,
      hasMediaCentreAccess: hasMediaCentreAccess,
      hasAdvancedAnalyticsAccess: hasAdvancedAnalyticsAccess,
      hasCampaignToolsAccess: hasCampaignToolsAccess,
    );
    if (upgrade != null) {
      items.add(
        SubscriptionRecommendation(
          kind: SubscriptionRecommendationKind.upgrade,
          planId: upgrade.currentPlanId,
          targetPlanId: upgrade.recommendedPlanId,
          title: upgrade.title,
          message: upgrade.message,
          action: GrowthAction.upgradeSubscription,
          priority: upgrade.priority,
        ),
      );
    }

    final renewal = recommendRenewal(
      currentPlanId: currentPlanId,
      daysUntilExpiry: daysUntilExpiry,
      growthScoreValue: growthScoreValue,
    );
    if (renewal != null) items.add(renewal);

    final trial = recommendTrial(
      hasActiveSubscription: hasActiveSubscription,
      hasPublishedContent: hasPublishedContent,
    );
    if (trial != null) items.add(trial);

    final downgrade = recommendDowngrade(
      currentPlanId: currentPlanId,
      underutilizedPremiumFeatures: underutilizedPremiumFeatures,
      activeVenueCount: activeVenueCount,
    );
    if (downgrade != null) items.add(downgrade);

    items.sort((a, b) {
      final priorityDiff =
          GrowthOrdering.comparePriority(a.priority, b.priority);
      if (priorityDiff != 0) return priorityDiff;
      return a.kind.index.compareTo(b.kind.index);
    });
    return items;
  }
}
