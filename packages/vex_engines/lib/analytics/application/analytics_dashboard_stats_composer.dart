import '../domain/analytics_dashboard_models.dart';
import '../domain/analytics_venue_metrics.dart';
import 'analytics_percent_change.dart';

/// Builds dashboard stat rows with deterministic period comparisons.
final class AnalyticsDashboardStatsComposer {
  const AnalyticsDashboardStatsComposer();

  List<AnalyticsDashboardStat> compose({
    required AnalyticsVenueMetrics current,
    AnalyticsVenueMetrics? previous,
  }) {
    return [
      AnalyticsDashboardStat(
        metricKey: AnalyticsDashboardMetricKey.profileViews,
        value: current.profileViews,
        changePercent: previous == null
            ? null
            : AnalyticsPercentChange.calculate(
                current.profileViews,
                previous.profileViews,
              ),
      ),
      AnalyticsDashboardStat(
        metricKey: AnalyticsDashboardMetricKey.saves,
        value: current.saves,
        changePercent: previous == null
            ? null
            : AnalyticsPercentChange.calculate(
                current.saves,
                previous.saves,
              ),
      ),
      AnalyticsDashboardStat(
        metricKey: AnalyticsDashboardMetricKey.drinkViews,
        value: current.drinkViews,
        changePercent: previous == null
            ? null
            : AnalyticsPercentChange.calculate(
                current.drinkViews,
                previous.drinkViews,
              ),
      ),
      AnalyticsDashboardStat(
        metricKey: AnalyticsDashboardMetricKey.dealViews,
        value: current.dealViews,
        changePercent: previous == null
            ? null
            : AnalyticsPercentChange.calculate(
                current.dealViews,
                previous.dealViews,
              ),
      ),
      AnalyticsDashboardStat(
        metricKey: AnalyticsDashboardMetricKey.eventViews,
        value: current.eventViews,
        changePercent: previous == null
            ? null
            : AnalyticsPercentChange.calculate(
                current.eventViews,
                previous.eventViews,
              ),
      ),
    ];
  }

  List<AnalyticsDashboardStat> empty() {
    return AnalyticsDashboardMetricKey.displayOrder
        .map(
          (key) => AnalyticsDashboardStat(metricKey: key, value: 0),
        )
        .toList();
  }
}
