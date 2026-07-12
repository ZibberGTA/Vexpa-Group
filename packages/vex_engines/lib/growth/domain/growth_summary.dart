import 'commercial_insight.dart';
import 'growth_opportunity.dart';
import 'growth_recommendation.dart';
import 'growth_score.dart';
import 'upgrade_recommendation.dart';

/// Owner-facing commercial summary for dashboard or marketing surfaces.
final class GrowthSummary {
  const GrowthSummary({
    required this.score,
    required this.recommendations,
    this.opportunities = const [],
    this.upgradeRecommendation,
    this.insights = const [],
    this.activeBoostLabel = '',
    this.campaignReadinessLabel = '',
  });

  final GrowthScore score;
  final List<GrowthRecommendation> recommendations;
  final List<GrowthOpportunity> opportunities;
  final UpgradeRecommendation? upgradeRecommendation;
  final List<CommercialInsight> insights;
  final String activeBoostLabel;
  final String campaignReadinessLabel;
}
