import 'package:vex_engines/growth/growth_engine.dart';

/// Web facade for Growth Engine commercial decisions.
final class GrowthCommercialSupport {
  GrowthCommercialSupport._();

  static const _upgradeService = GrowthUpgradeService();
  static const _comparisonService = GrowthComparisonService();
  static const _performanceService = GrowthPerformanceInterpretationService();
  static const _summaryService = GrowthSummaryService();
  static const _subscriptionService = GrowthSubscriptionService();
  static const _campaignLifecycleService = GrowthCampaignLifecycleService();
  static const _marketingSummaryService = GrowthMarketingSummaryService();
  static const _commercialService = GrowthCommercialService();
  static const _boostLifecycleService = GrowthBoostLifecycleService();
  static const _scoringService = GrowthScoringService();

  static UpgradeRecommendation? recommendVenueUpgrade({
    required String currentPlanId,
    required bool hasMediaCentreAccess,
    required bool hasAdvancedAnalyticsAccess,
    required bool hasCampaignToolsAccess,
  }) {
    return _subscriptionService.recommendUpgrade(
      currentPlanId: currentPlanId,
      hasMediaCentreAccess: hasMediaCentreAccess,
      hasAdvancedAnalyticsAccess: hasAdvancedAnalyticsAccess,
      hasCampaignToolsAccess: hasCampaignToolsAccess,
    );
  }

  static GrowthPerformance interpretPerformance(GrowthPerformanceInput input) {
    return _performanceService.interpret(input);
  }

  static GrowthSummary summarize(GrowthSummaryInput input) {
    return _summaryService.summarize(input);
  }

  static int discountedLaunchPriceGbp(int monthlyPriceGbp) {
    return _comparisonService.discountedPriceGbp(monthlyPriceGbp);
  }

  static List<SubscriptionRecommendation> subscriptionRecommendations({
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
    return _subscriptionService.subscriptionRecommendations(
      currentPlanId: currentPlanId,
      hasMediaCentreAccess: hasMediaCentreAccess,
      hasAdvancedAnalyticsAccess: hasAdvancedAnalyticsAccess,
      hasCampaignToolsAccess: hasCampaignToolsAccess,
      underutilizedPremiumFeatures: underutilizedPremiumFeatures,
      activeVenueCount: activeVenueCount,
      daysUntilExpiry: daysUntilExpiry,
      growthScoreValue: growthScoreValue,
      hasActiveSubscription: hasActiveSubscription,
      hasPublishedContent: hasPublishedContent,
    );
  }

  static GrowthProductSummary? productSummary(String planId) {
    return _subscriptionService.productSummary(planId);
  }

  static CampaignLifecycleSummary summarizeCampaign({
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
    return _campaignLifecycleService.summarize(
      hasUpcomingDealOrEvent: hasUpcomingDealOrEvent,
      hasGalleryPhotos: hasGalleryPhotos,
      hasActiveBoost: hasActiveBoost,
      hasDraftCampaign: hasDraftCampaign,
      hasScheduledCampaign: hasScheduledCampaign,
      hasLiveCampaign: hasLiveCampaign,
      campaignEnded: campaignEnded,
      notificationsEnabled: notificationsEnabled,
      notificationOpenRatePercent: notificationOpenRatePercent,
      impressions: impressions,
    );
  }

  static GrowthMarketingSummary buildMarketingSummary({
    required GrowthPerformanceInput input,
    required GrowthAdviceInput adviceInput,
    required String activeBoostLabel,
  }) {
    return _marketingSummaryService.buildMarketingSummary(
      input: input,
      adviceInput: adviceInput,
      activeBoostLabel: activeBoostLabel,
    );
  }

  static GrowthCommercialSummary buildCommercialSummary({
    required GrowthSummaryInput summaryInput,
    required GrowthPerformanceInput performanceInput,
    required GrowthAdviceInput adviceInput,
  }) {
    return _commercialService.buildCommercialSummary(
      summaryInput: summaryInput,
      performanceInput: performanceInput,
      adviceInput: adviceInput,
    );
  }

  static String? renewalPrompt({required int daysUntilRenewal}) {
    return _commercialService.renewalPrompt(daysUntilRenewal: daysUntilRenewal);
  }

  static BoostSuggestion? suggestBoost({
    required GrowthPerformance performance,
    required bool hasUpcomingEvent,
    required bool hasWeekendDeal,
  }) {
    return _boostLifecycleService.composeSuggestion(
      performance: performance,
      hasUpcomingEvent: hasUpcomingEvent,
      hasWeekendDeal: hasWeekendDeal,
    );
  }

  static VenueGrowthScores venueScores({
    required GrowthPerformance performance,
    required int profileCompletionRemaining,
    required bool hasActiveBoost,
    required bool hasUpcomingDealOrEvent,
    required bool hasCampaignToolsAccess,
    required int dealCount,
  }) {
    return _scoringService.venueScores(
      performance: performance,
      profileCompletionRemaining: profileCompletionRemaining,
      hasActiveBoost: hasActiveBoost,
      hasUpcomingDealOrEvent: hasUpcomingDealOrEvent,
      hasCampaignToolsAccess: hasCampaignToolsAccess,
      dealCount: dealCount,
    );
  }
}
