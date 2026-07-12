import '../domain/growth_performance.dart';
import '../shared/growth_thresholds.dart';

/// Interprets adapter-supplied engagement metrics into commercial guidance.
final class GrowthPerformanceInterpretationService {
  const GrowthPerformanceInterpretationService();

  int estimatedVisits(GrowthPerformanceInput input) {
    return ((input.venueViews * GrowthThresholds.visitViewMultiplier) +
            (input.intentSignals * GrowthThresholds.visitIntentMultiplier))
        .round();
  }

  int estimatedRevenueGbp(GrowthPerformanceInput input) {
    return estimatedVisits(input) *
        GrowthThresholds.revenuePerEstimatedVisitGbp;
  }

  String roiSignalLabel(GrowthPerformanceInput input) {
    if (input.venueViews == 0) return 'New';
    final rate = input.intentSignals / input.venueViews;
    if (rate >= GrowthThresholds.strongIntentRate) return 'Strong';
    if (rate >= GrowthThresholds.goodIntentRate) return 'Good';
    return 'Build';
  }

  String engagementInsightMessage(GrowthPerformanceInput input) {
    if (input.venueViews == 0) {
      return 'Views will appear here once users start opening this venue.';
    }
    if (input.conversionRatePercent <
        GrowthThresholds.lowConversionRatePercent) {
      return 'People are viewing this venue, but favourites are low. '
          'Try improving photos, deals or event details.';
    }
    return 'This venue is converting views into favourites well. '
        'Keep deals and crowd levels updated.';
  }

  String revenueInsightMessage(GrowthPerformanceInput input) {
    final visits = estimatedVisits(input);
    if (visits == 0) {
      return 'Start driving saves, deal views and event interest to build a '
          'revenue signal.';
    }
    return 'Estimated from views, saves, deal taps and event interest. '
        'Connect redemptions or POS later for exact revenue.';
  }

  GrowthPerformance interpret(GrowthPerformanceInput input) {
    final visits = estimatedVisits(input);
    return GrowthPerformance(
      estimatedVisits: visits,
      estimatedRevenueGbp: estimatedRevenueGbp(input),
      roiSignalLabel: roiSignalLabel(input),
      insightMessage: engagementInsightMessage(input),
      revenueInsightMessage: revenueInsightMessage(input),
    );
  }
}
