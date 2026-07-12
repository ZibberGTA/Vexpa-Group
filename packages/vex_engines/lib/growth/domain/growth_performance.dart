/// Adapter-supplied engagement metrics for commercial interpretation.
///
/// Does not perform analytics calculations — adapters supply counts.
final class GrowthPerformanceInput {
  const GrowthPerformanceInput({
    this.venueViews = 0,
    this.favouriteTaps = 0,
    this.dealViews = 0,
    this.eventViews = 0,
    this.crowdUpdates = 0,
    this.conversionRatePercent = 0,
  });

  final int venueViews;
  final int favouriteTaps;
  final int dealViews;
  final int eventViews;
  final int crowdUpdates;
  final double conversionRatePercent;

  int get intentSignals => favouriteTaps + dealViews + eventViews;
}

/// Commercial interpretation of engagement performance.
final class GrowthPerformance {
  const GrowthPerformance({
    required this.estimatedVisits,
    required this.estimatedRevenueGbp,
    required this.roiSignalLabel,
    required this.insightMessage,
    required this.revenueInsightMessage,
  });

  final int estimatedVisits;
  final int estimatedRevenueGbp;
  final String roiSignalLabel;
  final String insightMessage;
  final String revenueInsightMessage;
}
