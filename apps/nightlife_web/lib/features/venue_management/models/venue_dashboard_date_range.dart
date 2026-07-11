import 'package:vex_engines/analytics/domain/analytics_dashboard_date_range.dart';

import '../models/venue_dashboard_date_range.dart';
import '../services/venue_dashboard_engine_mapper.dart';

/// Date range filter for venue dashboard analytics.
enum VenueDashboardDateRange {
  today('Today', 'vs yesterday'),
  last3Days('Last 3 days', 'vs previous 3 days'),
  last7Days('Last 7 days', 'vs previous 7 days'),
  lastMonth('Last month', 'vs previous month'),
  allTime('All time', 'overall'),
  custom('Custom', 'vs previous selected period');

  const VenueDashboardDateRange(this.label, this.comparisonLabel);

  final String label;
  final String comparisonLabel;

  static const VenueDashboardDateRange defaultRange = last7Days;

  static const _periodCalculator = AnalyticsDashboardPeriodCalculator();

  /// Chart panel options — excludes [custom].
  static const List<VenueDashboardDateRange> chartOptions = [
    today,
    last3Days,
    last7Days,
    lastMonth,
    allTime,
  ];

  AnalyticsDashboardDateRange get _analyticsRange =>
      VenueDashboardEngineMapper.toAnalyticsRange(this);

  /// Start of the selected analytics window, or null for all time.
  DateTime? get since => _periodCalculator.since(range: _analyticsRange);

  /// Start of the comparison window immediately before [since].
  DateTime? get previousPeriodSince =>
      _periodCalculator.previousPeriodSince(range: _analyticsRange);
}
