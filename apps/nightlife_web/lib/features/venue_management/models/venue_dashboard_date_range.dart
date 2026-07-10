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

  /// Chart panel options — excludes [custom].
  static const List<VenueDashboardDateRange> chartOptions = [
    today,
    last3Days,
    last7Days,
    lastMonth,
    allTime,
  ];

  /// Start of the selected analytics window, or null for all time.
  DateTime? get since {
    final now = DateTime.now();
    return switch (this) {
      today => DateTime(now.year, now.month, now.day),
      last3Days => now.subtract(const Duration(days: 3)),
      last7Days => now.subtract(const Duration(days: 7)),
      lastMonth => now.subtract(const Duration(days: 30)),
      allTime => null,
      custom => now.subtract(const Duration(days: 7)),
    };
  }

  /// Start of the comparison window immediately before [since].
  DateTime? get previousPeriodSince {
    final start = since;
    if (start == null) return null;

    return switch (this) {
      today => start.subtract(const Duration(days: 1)),
      last3Days => start.subtract(const Duration(days: 3)),
      last7Days => start.subtract(const Duration(days: 7)),
      lastMonth => start.subtract(const Duration(days: 30)),
      allTime => null,
      custom => start.subtract(const Duration(days: 7)),
    };
  }
}
