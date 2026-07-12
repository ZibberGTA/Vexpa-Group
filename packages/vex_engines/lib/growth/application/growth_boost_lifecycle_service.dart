import '../domain/boost_plan.dart';
import '../domain/boost_lifecycle.dart';
import '../domain/growth_action.dart';
import '../domain/promotion_status.dart';
import '../domain/growth_boost_state.dart';
import '../domain/growth_performance.dart';
import '../domain/growth_priority.dart';
import '../shared/growth_product_catalog.dart';
import 'growth_boost_service.dart';

/// Boost renewal, expiry, duration, plan, and campaign timing recommendations.
final class GrowthBoostLifecycleService {
  const GrowthBoostLifecycleService({
    GrowthBoostService boostService = const GrowthBoostService(),
  }) : _boostService = boostService;

  final GrowthBoostService _boostService;

  BoostLifecycleRecommendation? renewalRecommendation({
    required GrowthActiveBoost? activeBoost,
    required GrowthPerformance performance,
    DateTime? now,
  }) {
    if (activeBoost == null || !activeBoost.active) return null;
    final endsAt = activeBoost.endsAt;
    if (endsAt == null) return null;

    final clock = now ?? DateTime.now();
    final daysRemaining = endsAt.difference(clock).inDays;
    if (daysRemaining > 3 || daysRemaining < 0) return null;

    final suggestedPlanId = performance.roiSignalLabel == 'Strong'
        ? 'boost_30d'
        : 'boost_7d';

    return BoostLifecycleRecommendation(
      title: 'Renew your boost',
      message: daysRemaining == 0
          ? 'Your boost expires today — extend visibility before it drops.'
          : 'Your boost ends in $daysRemaining day(s). Renew to stay in Trending.',
      action: GrowthAction.purchaseBoost,
      priority: daysRemaining <= 1 ? GrowthPriority.high : GrowthPriority.medium,
      suggestedPlanId: suggestedPlanId,
      daysRemaining: daysRemaining,
    );
  }

  BoostLifecycleRecommendation? expiryRecommendation({
    required GrowthActiveBoost? activeBoost,
    DateTime? now,
  }) {
    if (activeBoost == null) return null;
    final status = _boostService.resolveStatus(activeBoost, now: now);
    if (status != PromotionStatus.expired) return null;

    return const BoostLifecycleRecommendation(
      title: 'Boost expired',
      message: 'Reactivate a boost to regain Trending placement.',
      action: GrowthAction.purchaseBoost,
      priority: GrowthPriority.high,
      suggestedPlanId: 'boost_7d',
      daysRemaining: 0,
    );
  }

  BoostPlan? suggestPlan({
    required GrowthPerformance performance,
    required bool hasWeekendEvent,
  }) {
    if (performance.roiSignalLabel == 'Strong' && hasWeekendEvent) {
      return GrowthProductCatalog.boostPlanById('boost_24h');
    }
    if (performance.estimatedVisits >= 15) {
      return GrowthProductCatalog.boostPlanById('boost_7d');
    }
    return GrowthProductCatalog.boostPlanById('boost_24h');
  }

  int suggestDurationDays({
    required GrowthPerformance performance,
    required bool hasWeekendEvent,
  }) {
    return suggestPlan(
          performance: performance,
          hasWeekendEvent: hasWeekendEvent,
        )?.days ??
        1;
  }

  String suggestCampaignTiming({
    required bool hasUpcomingEvent,
    required bool hasWeekendDeal,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final isWeekend = clock.weekday >= DateTime.friday;
    if (hasUpcomingEvent) {
      return 'Launch boost 48 hours before your event starts.';
    }
    if (hasWeekendDeal || isWeekend) {
      return 'Start a boost on Thursday for weekend visibility.';
    }
    return 'Run a 7-day boost during your busiest trading days.';
  }

  BoostSuggestion? composeSuggestion({
    required GrowthPerformance performance,
    required bool hasUpcomingEvent,
    required bool hasWeekendDeal,
    DateTime? now,
  }) {
    final plan = suggestPlan(
      performance: performance,
      hasWeekendEvent: hasUpcomingEvent || hasWeekendDeal,
    );
    if (plan == null) return null;

    return BoostSuggestion(
      plan: plan,
      reason: performance.roiSignalLabel == 'Strong'
          ? 'Strong engagement — short boost can capture peak demand.'
          : 'Build visibility with a focused boost window.',
      timingLabel: suggestCampaignTiming(
        hasUpcomingEvent: hasUpcomingEvent,
        hasWeekendDeal: hasWeekendDeal,
        now: now,
      ),
    );
  }
}
