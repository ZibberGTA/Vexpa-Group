import '../domain/analytics_chart_period.dart';
import '../domain/analytics_venue_metrics.dart';

/// Labels and ordering for profile-view time-series charts.
final class AnalyticsTimeBucketService {
  AnalyticsTimeBucketService._();

  static String bucketLabel(DateTime date, AnalyticsChartPeriod period) {
    return switch (period) {
      AnalyticsChartPeriod.today =>
        '${((date.hour + 11) ~/ 12) * 12}${date.hour >= 12 ? 'pm' : 'am'}',
      AnalyticsChartPeriod.last3Days ||
      AnalyticsChartPeriod.last7Days ||
      AnalyticsChartPeriod.custom =>
        _weekdayLabel(date.weekday),
      AnalyticsChartPeriod.lastMonth => 'W${_weekOfMonth(date)}',
      AnalyticsChartPeriod.allTime => _monthLabel(date.month),
    };
  }

  static List<String> orderedBucketLabels(
    AnalyticsChartPeriod period,
    Iterable<String> labels,
  ) {
    final unique = labels.toSet();
    if (period == AnalyticsChartPeriod.last7Days ||
        period == AnalyticsChartPeriod.custom) {
      const order = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return order.where(unique.contains).toList();
    }
    if (period == AnalyticsChartPeriod.last3Days) {
      return unique.toList();
    }
    final sorted = unique.toList()..sort();
    return sorted;
  }

  static String _weekdayLabel(int weekday) {
    return switch (weekday) {
      DateTime.monday => 'Mon',
      DateTime.tuesday => 'Tue',
      DateTime.wednesday => 'Wed',
      DateTime.thursday => 'Thu',
      DateTime.friday => 'Fri',
      DateTime.saturday => 'Sat',
      DateTime.sunday => 'Sun',
      _ => 'Day',
    };
  }

  static String _monthLabel(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[(month - 1).clamp(0, 11)];
  }

  static int _weekOfMonth(DateTime date) {
    return ((date.day - 1) ~/ 7) + 1;
  }
}

/// Builds chart series from profile-view timestamps.
final class AnalyticsChartSeriesBuilder {
  const AnalyticsChartSeriesBuilder();

  List<AnalyticsChartPoint> buildProfileViewsSeries({
    required Iterable<DateTime> timestamps,
    required AnalyticsChartPeriod period,
  }) {
    final buckets = <String, double>{};
    for (final date in timestamps) {
      final label = AnalyticsTimeBucketService.bucketLabel(date, period);
      buckets[label] = (buckets[label] ?? 0) + 1;
    }

    if (buckets.isEmpty) return const [];

    final orderedLabels = AnalyticsTimeBucketService.orderedBucketLabels(
      period,
      buckets.keys,
    );

    return orderedLabels
        .map(
          (label) => AnalyticsChartPoint(
            label: label,
            value: buckets[label] ?? 0,
          ),
        )
        .toList();
  }
}
