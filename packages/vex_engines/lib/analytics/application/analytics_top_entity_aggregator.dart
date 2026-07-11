import '../domain/analytics_event_record.dart';
import '../domain/analytics_event_type.dart';
import '../domain/analytics_venue_metrics.dart';

/// Aggregates top drinks, deals, and events from analytics event records.
final class AnalyticsTopEntityAggregator {
  const AnalyticsTopEntityAggregator();

  AnalyticsTopEntities aggregateTodayEntities(Iterable<AnalyticsEventRecord> events) {
    final drinkCounts = <String, int>{};
    final dealCounts = <String, int>{};
    final eventCounts = <String, int>{};

    for (final event in events) {
      switch (event.type) {
        case 'drink_view':
          final name = event.payload['drinkName']?.toString().trim();
          if (name != null && name.isNotEmpty) {
            drinkCounts[name] = (drinkCounts[name] ?? 0) + 1;
          }
        case 'deal_view':
          final title = event.payload['dealTitle']?.toString().trim();
          if (title != null && title.isNotEmpty) {
            dealCounts[title] = (dealCounts[title] ?? 0) + 1;
          }
        case 'event_view':
          final title = event.payload['eventTitle']?.toString().trim();
          if (title != null && title.isNotEmpty) {
            eventCounts[title] = (eventCounts[title] ?? 0) + 1;
          }
      }
    }

    return AnalyticsTopEntities(
      topDrinkName: _topKey(drinkCounts),
      topDealTitle: _topKey(dealCounts),
      topEventTitle: _topKey(eventCounts),
    );
  }

  List<AnalyticsTopItem> topItems({
    required Iterable<AnalyticsEventRecord> events,
    required String idKey,
    required String nameKey,
    int limit = 5,
  }) {
    final counts = <String, int>{};
    final names = <String, String>{};

    for (final event in events) {
      final id = event.payload[idKey]?.toString() ?? '';
      if (id.isEmpty) continue;

      counts[id] = (counts[id] ?? 0) + 1;

      final name = event.payload[nameKey]?.toString() ?? '';
      if (name.isNotEmpty) names[id] = name;
    }

    final items = counts.entries
        .map(
          (entry) => AnalyticsTopItem(
            id: entry.key,
            name: names[entry.key] ?? entry.key,
            count: entry.value,
          ),
        )
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return items.take(limit).toList();
  }

  List<AnalyticsChartPoint> crowdTrendPoints(
    Iterable<AnalyticsEventRecord> events,
  ) {
    final counts = <String, int>{};

    for (final event in events) {
      if (event.type != AnalyticsEventType.crowdUpdate.firestoreValue) {
        continue;
      }
      final level = event.payload['level']?.toString().trim();
      if (level == null || level.isEmpty) continue;
      counts[level] = (counts[level] ?? 0) + 1;
    }

    return counts.entries
        .map((entry) => AnalyticsChartPoint(label: entry.key, value: entry.value.toDouble()))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  String? _topKey(Map<String, int> counts) {
    if (counts.isEmpty) return null;
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}

/// Top entity names for quick dashboard highlights.
final class AnalyticsTopEntities {
  const AnalyticsTopEntities({
    this.topDrinkName,
    this.topDealTitle,
    this.topEventTitle,
  });

  final String? topDrinkName;
  final String? topDealTitle;
  final String? topEventTitle;

  static const empty = AnalyticsTopEntities();
}
