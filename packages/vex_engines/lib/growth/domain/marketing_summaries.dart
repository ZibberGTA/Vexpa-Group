import 'growth_performance.dart';
import 'growth_recommendation.dart';
import 'growth_score.dart';
import 'upgrade_recommendation.dart';

/// ROI-focused commercial summary.
final class GrowthRoiSummary {
  const GrowthRoiSummary({
    required this.signalLabel,
    required this.estimatedVisits,
    required this.estimatedRevenueGbp,
    required this.insightMessage,
    required this.revenueInsightMessage,
  });

  final String signalLabel;
  final int estimatedVisits;
  final int estimatedRevenueGbp;
  final String insightMessage;
  final String revenueInsightMessage;
}

/// Conversion-focused summary from engagement metrics.
final class GrowthConversionSummary {
  const GrowthConversionSummary({
    required this.conversionRatePercent,
    required this.label,
    required this.message,
  });

  final double conversionRatePercent;
  final String label;
  final String message;
}

/// Marketing dashboard summary composed from performance and recommendations.
final class GrowthMarketingSummary {
  const GrowthMarketingSummary({
    required this.headline,
    required this.performance,
    required this.roi,
    required this.conversion,
    required this.recommendations,
    required this.activeBoostLabel,
  });

  final String headline;
  final GrowthPerformance performance;
  final GrowthRoiSummary roi;
  final GrowthConversionSummary conversion;
  final List<GrowthRecommendation> recommendations;
  final String activeBoostLabel;
}

/// Full commercial summary for owner dashboards.
final class GrowthCommercialSummary {
  const GrowthCommercialSummary({
    required this.score,
    required this.marketing,
    required this.upgradeRecommendation,
    required this.campaignReadinessLabel,
    required this.forecastRevenueGbp,
  });

  final GrowthScore score;
  final GrowthMarketingSummary marketing;
  final UpgradeRecommendation? upgradeRecommendation;
  final String campaignReadinessLabel;
  final int forecastRevenueGbp;
}
