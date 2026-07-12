import '../domain/growth_opportunity.dart';
import '../domain/growth_priority.dart';
import '../domain/growth_recommendation.dart';

/// Deterministic ordering for growth recommendations and opportunities.
abstract final class GrowthOrdering {
  GrowthOrdering._();

  static int comparePriority(GrowthPriority left, GrowthPriority right) {
    return left.sortOrder.compareTo(right.sortOrder);
  }

  static int compareOpportunities(
    GrowthOpportunity left,
    GrowthOpportunity right,
  ) {
    final priorityDiff = comparePriority(left.priority, right.priority);
    if (priorityDiff != 0) return priorityDiff;
    final scoreDiff = right.score.compareTo(left.score);
    if (scoreDiff != 0) return scoreDiff;
    return left.id.compareTo(right.id);
  }

  static int compareRecommendations(
    GrowthRecommendation left,
    GrowthRecommendation right,
  ) {
    final priorityDiff = comparePriority(left.priority, right.priority);
    if (priorityDiff != 0) return priorityDiff;
    return left.id.compareTo(right.id);
  }

  static List<GrowthOpportunity> orderOpportunities(
    Iterable<GrowthOpportunity> opportunities,
  ) {
    final list = opportunities.toList(growable: false);
    list.sort(compareOpportunities);
    return list;
  }

  static List<GrowthRecommendation> orderRecommendations(
    Iterable<GrowthRecommendation> recommendations,
  ) {
    final list = recommendations.toList(growable: false);
    list.sort(compareRecommendations);
    return list;
  }
}
