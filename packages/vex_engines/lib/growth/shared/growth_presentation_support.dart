import '../domain/growth_performance.dart';

/// Presentation helpers for growth summaries (adapter/UI agnostic strings).
abstract final class GrowthPresentationSupport {
  GrowthPresentationSupport._();

  static String performanceHeadline(GrowthPerformance performance) {
    return performance.roiSignalLabel;
  }

  static String revenueSignalLine(GrowthPerformance performance) {
    final visits = performance.estimatedVisits;
    final visitLabel = visits == 1 ? 'visit' : 'visits';
    return 'Revenue signal: £${performance.estimatedRevenueGbp} projected from '
        '$visits likely $visitLabel. ${performance.revenueInsightMessage}';
  }
}
