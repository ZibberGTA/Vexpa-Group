import 'package:vex_engines/growth/growth_engine.dart';

/// Mobile facade for Growth Engine commercial decisions.
final class MobileGrowthCommercialSupport {
  MobileGrowthCommercialSupport._();

  static const performance = GrowthPerformanceInterpretationService();
  static const marketing = GrowthMarketingSummaryService();
  static const boostLifecycle = GrowthBoostLifecycleService();
  static const scoring = GrowthScoringService();
  static const subscription = GrowthSubscriptionService();
  static const commercial = GrowthCommercialService();

  static GrowthPerformance interpret(GrowthPerformanceInput input) {
    return performance.interpret(input);
  }

  static int estimatedVisits(GrowthPerformanceInput input) {
    return performance.estimatedVisits(input);
  }

  static int estimatedRevenueGbp(GrowthPerformanceInput input) {
    return performance.estimatedRevenueGbp(input);
  }

  static String roiSignalLabel(GrowthPerformanceInput input) {
    return performance.roiSignalLabel(input);
  }

  static GrowthRoiSummary roiSummary(GrowthPerformance performance) {
    return marketing.buildRoiSummary(performance);
  }

  static GrowthConversionSummary conversionSummary({
    required double conversionRatePercent,
    required int venueViews,
  }) {
    return marketing.buildConversionSummary(
      conversionRatePercent: conversionRatePercent,
      venueViews: venueViews,
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
    return scoring.venueScores(
      performance: performance,
      profileCompletionRemaining: profileCompletionRemaining,
      hasActiveBoost: hasActiveBoost,
      hasUpcomingDealOrEvent: hasUpcomingDealOrEvent,
      hasCampaignToolsAccess: hasCampaignToolsAccess,
      dealCount: dealCount,
    );
  }
}
