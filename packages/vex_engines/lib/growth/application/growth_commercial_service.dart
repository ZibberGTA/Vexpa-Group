import '../domain/growth_opportunity.dart';
import '../domain/growth_performance.dart';
import '../domain/marketing_summaries.dart';
import '../shared/growth_product_catalog.dart';
import 'growth_comparison_service.dart';
import 'growth_marketing_summary_service.dart';
import 'growth_recommendation_service.dart';
import 'growth_summary_service.dart';
/// Pricing interpretation, forecasting, renewal prompts, and commercial summaries.
final class GrowthCommercialService {
  const GrowthCommercialService({
    GrowthComparisonService comparisonService = const GrowthComparisonService(),
    GrowthMarketingSummaryService marketingSummaryService =
        const GrowthMarketingSummaryService(),
    GrowthRecommendationService recommendationService =
        const GrowthRecommendationService(),
    GrowthSummaryService summaryService = const GrowthSummaryService(),
  }) : _comparisonService = comparisonService,
       _marketingSummaryService = marketingSummaryService,
       _recommendationService = recommendationService,
       _summaryService = summaryService;

  final GrowthComparisonService _comparisonService;
  final GrowthMarketingSummaryService _marketingSummaryService;
  final GrowthRecommendationService _recommendationService;
  final GrowthSummaryService _summaryService;
  int interpretMonthlyPriceGbp(String planId) {
    return GrowthProductCatalog.venuePlanById(planId)?.monthlyPriceGbp ?? 0;
  }

  int interpretDiscountedPriceGbp(int monthlyPriceGbp) {
    return _comparisonService.discountedPriceGbp(monthlyPriceGbp);
  }

  String pricingLabel({
    required int monthlyPriceGbp,
    required bool includeLaunchDiscount,
  }) {
    if (!includeLaunchDiscount) return '£$monthlyPriceGbp / month';
    final discounted = interpretDiscountedPriceGbp(monthlyPriceGbp);
    return '£$discounted / month (${GrowthProductCatalog.launchDiscountLabel})';
  }

  int planPriceDifferenceGbp({
    required String fromPlanId,
    required String toPlanId,
  }) {
    return _comparisonService.priceDifferenceGbp(
      fromPlanId: fromPlanId,
      toPlanId: toPlanId,
    );
  }

  String? renewalPrompt({required int daysUntilRenewal}) {
    if (daysUntilRenewal < 0) return null;
    if (daysUntilRenewal > 14) return null;
    if (daysUntilRenewal == 0) return 'Your subscription renews today.';
    if (daysUntilRenewal == 1) return 'Your subscription renews tomorrow.';
    return 'Your subscription renews in $daysUntilRenewal days.';
  }

  int forecastRevenueGbp({
    required GrowthPerformance performance,
    required int months,
  }) {
    if (months <= 0) return 0;
    return (performance.estimatedRevenueGbp * months).clamp(0, 999999);
  }

  GrowthCommercialSummary buildCommercialSummary({
    required GrowthSummaryInput summaryInput,
    required GrowthPerformanceInput performanceInput,
    required GrowthAdviceInput adviceInput,
  }) {
    final summary = _summaryService.summarize(summaryInput);
    final marketing = _marketingSummaryService.buildMarketingSummary(
      input: performanceInput,
      adviceInput: adviceInput,
      activeBoostLabel: summary.activeBoostLabel,
    );

    return GrowthCommercialSummary(
      score: summary.score,
      marketing: marketing,
      upgradeRecommendation: summary.upgradeRecommendation,
      campaignReadinessLabel: summary.campaignReadinessLabel,
      forecastRevenueGbp: forecastRevenueGbp(
        performance: summaryInput.performance,
        months: 3,
      ),
    );
  }

  List<GrowthOpportunity> growthOpportunities(GrowthAdviceInput input) {
    return _recommendationService.composeOpportunities(input);
  }
}
