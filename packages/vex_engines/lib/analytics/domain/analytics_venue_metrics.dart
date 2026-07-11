/// Aggregated venue analytics counts for a time window.
final class AnalyticsVenueMetrics {
  const AnalyticsVenueMetrics({
    required this.profileViews,
    required this.saves,
    required this.drinkViews,
    required this.dealViews,
    required this.eventViews,
    this.crowdUpdates = 0,
  });

  final int profileViews;
  final int saves;
  final int drinkViews;
  final int dealViews;
  final int eventViews;
  final int crowdUpdates;

  int get total =>
      profileViews + saves + drinkViews + dealViews + eventViews + crowdUpdates;

  static const empty = AnalyticsVenueMetrics(
    profileViews: 0,
    saves: 0,
    drinkViews: 0,
    dealViews: 0,
    eventViews: 0,
  );
}

/// Profile views chart point for dashboard time series.
final class AnalyticsChartPoint {
  const AnalyticsChartPoint({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;
}

/// Ranked analytics entity such as a drink, deal, or event.
final class AnalyticsTopItem {
  const AnalyticsTopItem({
    required this.id,
    required this.name,
    required this.count,
  });

  final String id;
  final String name;
  final int count;
}

/// Weekly activity growth comparison.
final class AnalyticsWeeklyGrowth {
  const AnalyticsWeeklyGrowth({
    required this.thisWeekScore,
    required this.lastWeekScore,
    required this.percentageChange,
  });

  final int thisWeekScore;
  final int lastWeekScore;
  final double percentageChange;

  bool get hasActivity => thisWeekScore > 0 || lastWeekScore > 0;
  bool get isGrowing => percentageChange >= 0;

  String get formattedPercentage {
    final prefix = percentageChange >= 0 ? '+' : '';
    return '$prefix${percentageChange.round()}%';
  }

  String get dashboardLabel {
    if (!hasActivity) return 'No activity yet';
    return isGrowing
        ? 'Growing $formattedPercentage'
        : 'Down $formattedPercentage';
  }

  static const empty = AnalyticsWeeklyGrowth(
    thisWeekScore: 0,
    lastWeekScore: 0,
    percentageChange: 0,
  );
}

/// Engagement metrics derived from venue analytics counts.
final class AnalyticsEngagementMetrics {
  const AnalyticsEngagementMetrics({
    required this.favouriteConversionRate,
    required this.totalContentViews,
    required this.popularityScore,
  });

  final double favouriteConversionRate;
  final int totalContentViews;
  final int popularityScore;
}
