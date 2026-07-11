import '../domain/analytics_dashboard_models.dart';

/// Sorts and limits dashboard activity entries by recency.
final class AnalyticsActivityAggregator {
  const AnalyticsActivityAggregator();

  List<AnalyticsActivityEntry> sortAndLimit(
    Iterable<AnalyticsActivityEntry> entries, {
    int limit = 5,
  }) {
    if (limit <= 0) return const [];

    final sorted = entries.toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    return sorted.take(limit).toList();
  }
}

/// Formats relative timestamps for dashboard activity rows.
final class AnalyticsRelativeTimeFormatter {
  const AnalyticsRelativeTimeFormatter();

  String format(DateTime date, {DateTime? now}) {
    final anchor = now ?? DateTime.now();
    final diff = anchor.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
