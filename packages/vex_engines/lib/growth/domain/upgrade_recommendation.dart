import 'growth_action.dart';
import 'growth_priority.dart';

/// Recommended subscription upgrade for a venue.
final class UpgradeRecommendation {
  const UpgradeRecommendation({
    required this.currentPlanId,
    required this.recommendedPlanId,
    required this.title,
    required this.message,
    required this.benefits,
    this.priority = GrowthPriority.high,
    this.action = GrowthAction.upgradeSubscription,
  });

  final String currentPlanId;
  final String recommendedPlanId;
  final String title;
  final String message;
  final List<String> benefits;
  final GrowthPriority priority;
  final GrowthAction action;
}
