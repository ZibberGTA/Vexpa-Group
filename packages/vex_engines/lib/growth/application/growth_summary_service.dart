import '../domain/commercial_insight.dart';
import '../domain/growth_action.dart';
import '../domain/growth_opportunity.dart';
import '../domain/growth_performance.dart';
import '../domain/growth_priority.dart';
import '../domain/growth_recommendation.dart';
import '../domain/growth_summary.dart';
import '../shared/growth_commercial_labels.dart';
import '../shared/growth_constants.dart';
import '../shared/growth_ordering.dart';
import '../shared/growth_recommendation_support.dart';
import 'growth_campaign_readiness_service.dart';
import 'growth_scoring_service.dart';
import 'growth_upgrade_service.dart';

/// Input snapshot for composing a commercial growth summary.
final class GrowthSummaryInput {
  const GrowthSummaryInput({
    required this.currentPlanId,
    required this.hasMediaCentreAccess,
    required this.hasAdvancedAnalyticsAccess,
    required this.hasCampaignToolsAccess,
    required this.hasGalleryPhotos,
    required this.hasUpcomingDealOrEvent,
    required this.hasActiveBoost,
    required this.activeBoostPlanName,
    this.activeBoostEndsAt,
    required this.performance,
    this.dealCount = 0,
    this.profileCompletionRemaining = 0,
  });

  final String currentPlanId;
  final bool hasMediaCentreAccess;
  final bool hasAdvancedAnalyticsAccess;
  final bool hasCampaignToolsAccess;
  final bool hasGalleryPhotos;
  final bool hasUpcomingDealOrEvent;
  final bool hasActiveBoost;
  final String activeBoostPlanName;
  final DateTime? activeBoostEndsAt;
  final GrowthPerformance performance;
  final int dealCount;
  final int profileCompletionRemaining;
}

/// Composes owner-facing commercial summaries and recommendations.
final class GrowthSummaryService {
  const GrowthSummaryService({
    GrowthScoringService scoringService = const GrowthScoringService(),
    GrowthUpgradeService upgradeService = const GrowthUpgradeService(),
    GrowthCampaignReadinessService campaignReadinessService =
        const GrowthCampaignReadinessService(),
  }) : _scoringService = scoringService,
       _upgradeService = upgradeService,
       _campaignReadinessService = campaignReadinessService;

  final GrowthScoringService _scoringService;
  final GrowthUpgradeService _upgradeService;
  final GrowthCampaignReadinessService _campaignReadinessService;

  GrowthSummary summarize(GrowthSummaryInput input) {
    final upgrade = _upgradeService.recommendVenueUpgrade(
      currentPlanId: input.currentPlanId,
      hasMediaCentreAccess: input.hasMediaCentreAccess,
      hasAdvancedAnalyticsAccess: input.hasAdvancedAnalyticsAccess,
      hasCampaignToolsAccess: input.hasCampaignToolsAccess,
    );

    final opportunities = <GrowthOpportunity>[
      if (!input.hasGalleryPhotos)
        GrowthRecommendationSupport.profilePhotosOpportunity(),
      if (input.dealCount == 0)
        GrowthRecommendationSupport.createDealOpportunity(),
      if (!input.hasActiveBoost)
        GrowthRecommendationSupport.purchaseBoostOpportunity(),
      if (_upgradeService.opportunityFromUpgrade(upgrade) case final value?)
        value,
    ];

    final score = _scoringService.score(
      performance: input.performance,
      profileCompletionRemaining: input.profileCompletionRemaining,
      hasActiveBoost: input.hasActiveBoost,
      hasUpcomingDealOrEvent: input.hasUpcomingDealOrEvent,
    );

    final readiness = _campaignReadinessService.assess(
      hasUpcomingDealOrEvent: input.hasUpcomingDealOrEvent,
      hasGalleryPhotos: input.hasGalleryPhotos,
      hasActiveBoost: input.hasActiveBoost,
      hasDraftCampaign: false,
      notificationsEnabled: true,
    );

    final recommendations = GrowthRecommendationSupport.topRecommendations(
      opportunities,
      maxItems: GrowthConstants.maxRecommendations,
    );

    return GrowthSummary(
      score: score,
      recommendations: recommendations,
      opportunities: GrowthOrdering.orderOpportunities(opportunities),
      upgradeRecommendation: upgrade,
      insights: _insightsFromPerformance(input.performance),
      activeBoostLabel: input.hasActiveBoost
          ? GrowthCommercialLabels.activeBoostSummary(
              planName: input.activeBoostPlanName,
              endsAt: input.activeBoostEndsAt,
            )
          : '',
      campaignReadinessLabel: _campaignReadinessService.readinessLabel(
        readiness,
      ),
    );
  }

  List<GrowthRecommendation> composeRecommendations(
    Iterable<GrowthOpportunity> opportunities,
  ) {
    return GrowthRecommendationSupport.topRecommendations(opportunities);
  }
}

List<CommercialInsight> _insightsFromPerformance(
  GrowthPerformance performance,
) {
  return [
    CommercialInsight(
      title: performance.roiSignalLabel,
      message: performance.insightMessage,
      action: GrowthAction.reviewAnalytics,
      priority: GrowthPriority.medium,
    ),
  ];
}
