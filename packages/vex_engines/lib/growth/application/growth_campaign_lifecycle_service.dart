import '../domain/campaign_lifecycle.dart';
import '../domain/campaign_readiness.dart';
import '../domain/growth_action.dart';
import '../domain/growth_issue.dart';
import '../domain/growth_priority.dart';
import '../domain/growth_recommendation.dart';
import '../shared/growth_constants.dart';
import '../shared/growth_ordering.dart';
import '../shared/growth_recommendation_support.dart';
import 'growth_campaign_readiness_service.dart';

/// Campaign readiness, health, completion, scoring, and recommendations.
final class GrowthCampaignLifecycleService {
  const GrowthCampaignLifecycleService({
    GrowthCampaignReadinessService readinessService =
        const GrowthCampaignReadinessService(),
  }) : _readinessService = readinessService;

  final GrowthCampaignReadinessService _readinessService;

  CampaignReadiness assessReadiness({
    required bool hasUpcomingDealOrEvent,
    required bool hasGalleryPhotos,
    required bool hasActiveBoost,
    required bool hasDraftCampaign,
    required bool notificationsEnabled,
  }) {
    return _readinessService.assess(
      hasUpcomingDealOrEvent: hasUpcomingDealOrEvent,
      hasGalleryPhotos: hasGalleryPhotos,
      hasActiveBoost: hasActiveBoost,
      hasDraftCampaign: hasDraftCampaign,
      notificationsEnabled: notificationsEnabled,
    );
  }

  CampaignCompletionStatus completionStatus({
    required bool hasDraftCampaign,
    required bool hasScheduledCampaign,
    required bool hasLiveCampaign,
    required bool campaignEnded,
  }) {
    if (campaignEnded) return CampaignCompletionStatus.completed;
    if (hasLiveCampaign) return CampaignCompletionStatus.live;
    if (hasScheduledCampaign) return CampaignCompletionStatus.scheduled;
    if (hasDraftCampaign) return CampaignCompletionStatus.draft;
    return CampaignCompletionStatus.notStarted;
  }

  CampaignHealth assessHealth({
    required CampaignReadiness readiness,
    required bool hasActiveBoost,
    required double notificationOpenRatePercent,
    required int impressions,
  }) {
    var score = readiness.ready ? 70 : 35;
    final issues = <GrowthIssue>[...readiness.issues];

    if (hasActiveBoost) score += 15;
    if (notificationOpenRatePercent >= 20) {
      score += 10;
    } else if (notificationOpenRatePercent > 0) {
      issues.add(
        const GrowthIssue(
          code: 'low-open-rate',
          message: 'Notification open rate is below target.',
          priority: GrowthPriority.medium,
        ),
      );
      score -= 5;
    }
    if (impressions >= 500) {
      score += 5;
    } else if (impressions == 0 && readiness.ready) {
      issues.add(
        const GrowthIssue(
          code: 'no-impressions',
          message: 'Campaign is ready but has no impressions yet.',
          priority: GrowthPriority.low,
        ),
      );
    }

    score = score.clamp(0, 100);
    final label = switch (score) {
      >= 80 => 'Healthy',
      >= 55 => 'Building',
      _ => 'Needs attention',
    };

    return CampaignHealth(score: score, label: label, issues: issues);
  }

  CampaignScore scoreCampaign({
    required CampaignReadiness readiness,
    required CampaignHealth health,
  }) {
    final readinessPoints = readiness.ready ? 50 : 20;
    final engagementPoints = (health.score * 0.5).round();
    final value = (readinessPoints + engagementPoints).clamp(0, 100);
    final label = value >= 75
        ? 'High potential'
        : value >= 45
        ? 'Moderate potential'
        : 'Low potential';

    return CampaignScore(
      value: value,
      label: label,
      readinessPoints: readinessPoints,
      engagementPoints: engagementPoints,
    );
  }

  List<GrowthRecommendation> recommendCampaignActions({
    required CampaignReadiness readiness,
    required CampaignHealth health,
    required bool hasActiveBoost,
  }) {
    final recommendations = <GrowthRecommendation>[];

    for (final missing in readiness.missingRequirements) {
      recommendations.add(
        GrowthRecommendation(
          id: 'campaign-fix-$missing',
          title: 'Fix campaign requirement',
          message: switch (missing) {
            'gallery-photos' => 'Add venue photos before launching.',
            'promotion-content' => 'Create a deal or event to promote.',
            'notifications' => 'Enable business notifications.',
            _ => 'Complete missing campaign setup.',
          },
          action: switch (missing) {
            'gallery-photos' => GrowthAction.addGalleryPhotos,
            'promotion-content' => GrowthAction.addEvent,
            _ => GrowthAction.createCampaign,
          },
          priority: GrowthPriority.high,
        ),
      );
    }

    if (!hasActiveBoost && health.score < 70) {
      recommendations.add(
        GrowthRecommendationSupport.fromOpportunity(
          GrowthRecommendationSupport.purchaseBoostOpportunity(),
        ),
      );
    }

    return GrowthOrdering.orderRecommendations(recommendations)
        .take(GrowthConstants.maxRecommendations)
        .toList(growable: false);
  }

  CampaignLifecycleSummary summarize({
    required bool hasUpcomingDealOrEvent,
    required bool hasGalleryPhotos,
    required bool hasActiveBoost,
    required bool hasDraftCampaign,
    required bool hasScheduledCampaign,
    required bool hasLiveCampaign,
    required bool campaignEnded,
    required bool notificationsEnabled,
    required double notificationOpenRatePercent,
    required int impressions,
  }) {
    final readiness = assessReadiness(
      hasUpcomingDealOrEvent: hasUpcomingDealOrEvent,
      hasGalleryPhotos: hasGalleryPhotos,
      hasActiveBoost: hasActiveBoost,
      hasDraftCampaign: hasDraftCampaign,
      notificationsEnabled: notificationsEnabled,
    );
    final health = assessHealth(
      readiness: readiness,
      hasActiveBoost: hasActiveBoost,
      notificationOpenRatePercent: notificationOpenRatePercent,
      impressions: impressions,
    );
    final score = scoreCampaign(readiness: readiness, health: health);

    return CampaignLifecycleSummary(
      status: completionStatus(
        hasDraftCampaign: hasDraftCampaign,
        hasScheduledCampaign: hasScheduledCampaign,
        hasLiveCampaign: hasLiveCampaign,
        campaignEnded: campaignEnded,
      ),
      health: health,
      score: score,
      recommendations: recommendCampaignActions(
        readiness: readiness,
        health: health,
        hasActiveBoost: hasActiveBoost,
      ),
      readinessLabel: _readinessService.readinessLabel(readiness),
    );
  }
}
