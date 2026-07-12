import 'boost_plan.dart';
import 'growth_action.dart';
import 'growth_priority.dart';

/// Boost renewal or expiry recommendation.
final class BoostLifecycleRecommendation {
  const BoostLifecycleRecommendation({
    required this.title,
    required this.message,
    required this.action,
    required this.priority,
    required this.suggestedPlanId,
    this.daysRemaining = 0,
  });

  final String title;
  final String message;
  final GrowthAction action;
  final GrowthPriority priority;
  final String suggestedPlanId;
  final int daysRemaining;
}

/// Suggested boost plan and timing for a venue.
final class BoostSuggestion {
  const BoostSuggestion({
    required this.plan,
    required this.reason,
    required this.timingLabel,
  });

  final BoostPlan plan;
  final String reason;
  final String timingLabel;
}
