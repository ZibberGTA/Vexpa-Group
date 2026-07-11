import 'analytics_chart_period.dart';

/// Dashboard analytics window identifiers shared by web and mobile adapters.
enum AnalyticsDashboardDateRange {
  today('Today', 'vs yesterday'),
  last3Days('Last 3 days', 'vs previous 3 days'),
  last7Days('Last 7 days', 'vs previous 7 days'),
  lastMonth('Last month', 'vs previous month'),
  allTime('All time', 'overall'),
  custom('Custom', 'vs previous selected period');

  const AnalyticsDashboardDateRange(this.label, this.comparisonLabel);

  final String label;
  final String comparisonLabel;

  static const AnalyticsDashboardDateRange defaultRange = last7Days;

  /// Chart panel options — excludes [custom].
  static const List<AnalyticsDashboardDateRange> chartOptions = [
    today,
    last3Days,
    last7Days,
    lastMonth,
    allTime,
  ];
}

/// Calculates dashboard period boundaries without performing queries.
final class AnalyticsDashboardPeriodCalculator {
  const AnalyticsDashboardPeriodCalculator();

  DateTime? since({
    required AnalyticsDashboardDateRange range,
    DateTime? now,
  }) {
    final anchor = now ?? DateTime.now();
    return switch (range) {
      AnalyticsDashboardDateRange.today =>
        DateTime(anchor.year, anchor.month, anchor.day),
      AnalyticsDashboardDateRange.last3Days =>
        anchor.subtract(const Duration(days: 3)),
      AnalyticsDashboardDateRange.last7Days =>
        anchor.subtract(const Duration(days: 7)),
      AnalyticsDashboardDateRange.lastMonth =>
        anchor.subtract(const Duration(days: 30)),
      AnalyticsDashboardDateRange.allTime => null,
      AnalyticsDashboardDateRange.custom =>
        anchor.subtract(const Duration(days: 7)),
    };
  }

  DateTime? previousPeriodSince({
    required AnalyticsDashboardDateRange range,
    DateTime? now,
  }) {
    final start = since(range: range, now: now);
    if (start == null) return null;

    return switch (range) {
      AnalyticsDashboardDateRange.today =>
        start.subtract(const Duration(days: 1)),
      AnalyticsDashboardDateRange.last3Days =>
        start.subtract(const Duration(days: 3)),
      AnalyticsDashboardDateRange.last7Days =>
        start.subtract(const Duration(days: 7)),
      AnalyticsDashboardDateRange.lastMonth =>
        start.subtract(const Duration(days: 30)),
      AnalyticsDashboardDateRange.allTime => null,
      AnalyticsDashboardDateRange.custom =>
        start.subtract(const Duration(days: 7)),
    };
  }

  AnalyticsChartPeriod chartPeriod(AnalyticsDashboardDateRange range) {
    return switch (range) {
      AnalyticsDashboardDateRange.today => AnalyticsChartPeriod.today,
      AnalyticsDashboardDateRange.last3Days => AnalyticsChartPeriod.last3Days,
      AnalyticsDashboardDateRange.last7Days => AnalyticsChartPeriod.last7Days,
      AnalyticsDashboardDateRange.lastMonth => AnalyticsChartPeriod.lastMonth,
      AnalyticsDashboardDateRange.allTime => AnalyticsChartPeriod.allTime,
      AnalyticsDashboardDateRange.custom => AnalyticsChartPeriod.custom,
    };
  }
}
