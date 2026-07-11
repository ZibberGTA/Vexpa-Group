import '../domain/analytics_venue_metrics.dart';

/// Percentage change between two metric values.
final class AnalyticsPercentChange {
  AnalyticsPercentChange._();

  static double? calculate(int current, int? previous) {
    if (previous == null) return null;
    if (previous == 0 && current == 0) return 0;
    if (previous == 0) return 100;
    return ((current - previous) / previous) * 100;
  }
}
