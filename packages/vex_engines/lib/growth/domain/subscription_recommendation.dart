import 'growth_action.dart';
import 'growth_priority.dart';

/// Kind of subscription commercial recommendation.
enum SubscriptionRecommendationKind {
  upgrade,
  downgrade,
  renewal,
  trial,
}

/// Subscription product summary for pricing surfaces.
final class GrowthProductSummary {
  const GrowthProductSummary({
    required this.planId,
    required this.name,
    required this.monthlyPriceGbp,
    required this.discountedMonthlyPriceGbp,
    required this.features,
    this.audience = '',
    this.highlighted = false,
  });

  final String planId;
  final String name;
  final String audience;
  final int monthlyPriceGbp;
  final int discountedMonthlyPriceGbp;
  final List<String> features;
  final bool highlighted;
}

/// Subscription upgrade/downgrade/renewal/trial recommendation.
final class SubscriptionRecommendation {
  const SubscriptionRecommendation({
    required this.kind,
    required this.planId,
    required this.title,
    required this.message,
    required this.action,
    required this.priority,
    this.targetPlanId = '',
  });

  final SubscriptionRecommendationKind kind;
  final String planId;
  final String targetPlanId;
  final String title;
  final String message;
  final GrowthAction action;
  final GrowthPriority priority;
}
