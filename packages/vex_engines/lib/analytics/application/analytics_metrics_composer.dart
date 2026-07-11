import '../domain/analytics_event_type.dart';
import '../domain/analytics_venue_metrics.dart';

/// Builds standard venue dashboard metrics from count query results.
final class AnalyticsMetricsComposer {
  const AnalyticsMetricsComposer();

  AnalyticsVenueMetrics fromDashboardCounts(List<int> counts) {
    if (counts.length < analyticsDashboardCountTypes.length) {
      final padded = [...counts];
      while (padded.length < analyticsDashboardCountTypes.length) {
        padded.add(0);
      }
      counts = padded;
    }

    return AnalyticsVenueMetrics(
      profileViews: counts[0],
      saves: counts[1],
      drinkViews: counts[2],
      dealViews: counts[3],
      eventViews: counts[4],
    );
  }

  AnalyticsVenueMetrics fromSummaryCounts({
    required int venueViews,
    required int favouriteTaps,
    required int crowdUpdates,
    required int drinkViews,
    required int dealViews,
    required int eventViews,
  }) {
    return AnalyticsVenueMetrics(
      profileViews: venueViews,
      saves: favouriteTaps,
      crowdUpdates: crowdUpdates,
      drinkViews: drinkViews,
      dealViews: dealViews,
      eventViews: eventViews,
    );
  }

  bool snapshotHasData({
    required AnalyticsVenueMetrics current,
    required Iterable<dynamic> chartPoints,
  }) =>
      current.total > 0 || chartPoints.isNotEmpty;
}
