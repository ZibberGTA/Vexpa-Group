import 'growth_issue.dart';
import 'growth_recommendation.dart';

/// Campaign health derived from readiness and engagement signals.
final class CampaignHealth {
  const CampaignHealth({
    required this.score,
    required this.label,
    required this.issues,
  });

  final int score;
  final String label;
  final List<GrowthIssue> issues;
}

/// Campaign completion state for lifecycle tracking.
enum CampaignCompletionStatus {
  notStarted,
  draft,
  scheduled,
  live,
  completed,
  expired,
}

/// Campaign score for ranking and dashboard metrics.
final class CampaignScore {
  const CampaignScore({
    required this.value,
    required this.label,
    required this.readinessPoints,
    required this.engagementPoints,
  });

  final int value;
  final String label;
  final int readinessPoints;
  final int engagementPoints;
}

/// Campaign lifecycle summary for marketing dashboards.
final class CampaignLifecycleSummary {
  const CampaignLifecycleSummary({
    required this.status,
    required this.health,
    required this.score,
    required this.recommendations,
    required this.readinessLabel,
  });

  final CampaignCompletionStatus status;
  final CampaignHealth health;
  final CampaignScore score;
  final List<GrowthRecommendation> recommendations;
  final String readinessLabel;
}
