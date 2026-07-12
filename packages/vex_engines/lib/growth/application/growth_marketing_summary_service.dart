import '../domain/growth_performance.dart';
import '../domain/marketing_summaries.dart';
import '../shared/growth_commercial_labels.dart';
import '../shared/growth_recommendation_support.dart';
import '../shared/growth_thresholds.dart';
import 'growth_performance_interpretation_service.dart';
import 'growth_recommendation_service.dart';

/// Marketing, performance, ROI, conversion, and commercial summaries.
final class GrowthMarketingSummaryService {
  const GrowthMarketingSummaryService({
    GrowthPerformanceInterpretationService performanceService =
        const GrowthPerformanceInterpretationService(),
    GrowthRecommendationService recommendationService =
        const GrowthRecommendationService(),
  }) : _performanceService = performanceService,
       _recommendationService = recommendationService;

  final GrowthPerformanceInterpretationService _performanceService;
  final GrowthRecommendationService _recommendationService;

  GrowthPerformance buildPerformanceSummary(GrowthPerformanceInput input) {
    return _performanceService.interpret(input);
  }

  GrowthRoiSummary buildRoiSummary(GrowthPerformance performance) {
    return GrowthRoiSummary(
      signalLabel: performance.roiSignalLabel,
      estimatedVisits: performance.estimatedVisits,
      estimatedRevenueGbp: performance.estimatedRevenueGbp,
      insightMessage: performance.insightMessage,
      revenueInsightMessage: performance.revenueInsightMessage,
    );
  }

  GrowthConversionSummary buildConversionSummary({
    required double conversionRatePercent,
    required int venueViews,
  }) {
    if (venueViews == 0) {
      return const GrowthConversionSummary(
        conversionRatePercent: 0,
        label: 'No data',
        message: 'Conversion rate appears once venue views are recorded.',
      );
    }

    final label = conversionRatePercent >= GrowthThresholds.lowConversionRatePercent
        ? 'Healthy conversion'
        : 'Low conversion';
    final message = conversionRatePercent >= GrowthThresholds.lowConversionRatePercent
        ? 'Views are converting into favourites at a healthy rate.'
        : 'Improve photos, deals and events to lift conversion.';

    return GrowthConversionSummary(
      conversionRatePercent: conversionRatePercent,
      label: label,
      message: message,
    );
  }

  GrowthMarketingSummary buildMarketingSummary({
    required GrowthPerformanceInput input,
    required GrowthAdviceInput adviceInput,
    required String activeBoostLabel,
  }) {
    final performance = buildPerformanceSummary(input);
    final roi = buildRoiSummary(performance);
    final conversion = buildConversionSummary(
      conversionRatePercent: input.conversionRatePercent,
      venueViews: input.venueViews,
    );
    final opportunities =
        _recommendationService.composeOpportunities(adviceInput);
    final recommendations = GrowthRecommendationSupport.topRecommendations(
      opportunities,
    );

    final headline = performance.roiSignalLabel == 'Strong'
        ? 'Strong marketing momentum'
        : performance.roiSignalLabel == 'Good'
        ? 'Steady marketing performance'
        : 'Build your marketing signal';

    return GrowthMarketingSummary(
      headline: headline,
      performance: performance,
      roi: roi,
      conversion: conversion,
      recommendations: recommendations,
      activeBoostLabel: activeBoostLabel,
    );
  }

  String performanceHeadline(GrowthPerformance performance) {
    return GrowthCommercialLabels.roiSignalLabel(performance.roiSignalLabel);
  }
}
