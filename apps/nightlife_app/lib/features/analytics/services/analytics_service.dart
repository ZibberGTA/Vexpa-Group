import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsRange {
  final String label;
  final int? days;

  const AnalyticsRange._(this.label, this.days);

  static const today = AnalyticsRange._('Today', 1);
  static const sevenDays = AnalyticsRange._('7 days', 7);
  static const thirtyDays = AnalyticsRange._('30 days', 30);
  static const allTime = AnalyticsRange._('All time', null);

  static const values = [today, sevenDays, thirtyDays, allTime];

  DateTime? get since {
    if (days == null) return null;
    return DateTime.now().subtract(Duration(days: days!));
  }
}

class TopAnalyticsItem {
  final String id;
  final String name;
  final int count;

  const TopAnalyticsItem({
    required this.id,
    required this.name,
    required this.count,
  });
}

class CrowdTrendPoint {
  final String label;
  final int count;

  const CrowdTrendPoint({
    required this.label,
    required this.count,
  });
}

class WeeklyGrowthMetric {
  final int thisWeekScore;
  final int lastWeekScore;
  final double percentageChange;

  const WeeklyGrowthMetric({
    required this.thisWeekScore,
    required this.lastWeekScore,
    required this.percentageChange,
  });

  bool get hasActivity => thisWeekScore > 0 || lastWeekScore > 0;
  bool get isGrowing => percentageChange >= 0;

  String get formattedPercentage {
    final prefix = percentageChange >= 0 ? '+' : '';
    return '$prefix${percentageChange.round()}%';
  }

  String get dashboardLabel {
    if (!hasActivity) return 'No activity yet';
    return isGrowing ? 'Growing $formattedPercentage' : 'Down $formattedPercentage';
  }
}

class AnalyticsSummary {
  final int venueViews;
  final int favouriteTaps;
  final int crowdUpdates;
  final int drinkViews;
  final int dealViews;
  final int eventViews;
  final List<TopAnalyticsItem> topDrinks;
  final List<TopAnalyticsItem> topDeals;
  final List<CrowdTrendPoint> crowdTrends;

  const AnalyticsSummary({
    required this.venueViews,
    required this.favouriteTaps,
    required this.crowdUpdates,
    required this.drinkViews,
    required this.dealViews,
    required this.eventViews,
    required this.topDrinks,
    required this.topDeals,
    required this.crowdTrends,
  });

  double get favouriteConversionRate {
    if (venueViews == 0) return 0;
    return (favouriteTaps / venueViews) * 100;
  }

  String get formattedConversionRate =>
      '${favouriteConversionRate.toStringAsFixed(1)}%';
}

class AnalyticsService {
  AnalyticsService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _analytics =>
      _db.collection('analytics');

  static Future<void> logEvent({
    required String venueId,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    if (venueId.trim().isEmpty || type.trim().isEmpty) return;

    await _analytics.add({
      'venueId': venueId,
      'type': type,
      'data': data ?? <String, dynamic>{},
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> logVenueView(String venueId) {
    return logEvent(venueId: venueId, type: 'venue_view');
  }

  static Future<void> logFavouriteTap(String venueId) {
    return logEvent(venueId: venueId, type: 'favourite_tap');
  }

  static Future<void> logCrowdUpdate({
    required String venueId,
    required String level,
  }) {
    return logEvent(
      venueId: venueId,
      type: 'crowd_update',
      data: {
        'level': level,
        'notificationReady': true,
      },
    );
  }

  static Future<void> logDrinkView({
    required String venueId,
    required String drinkId,
    String? drinkName,
  }) {
    return logEvent(
      venueId: venueId,
      type: 'drink_view',
      data: {
        'drinkId': drinkId,
        if (drinkName != null && drinkName.trim().isNotEmpty)
          'drinkName': drinkName.trim(),
      },
    );
  }

  static Future<void> logDealView({
    required String venueId,
    required String dealId,
    String? dealTitle,
  }) {
    return logEvent(
      venueId: venueId,
      type: 'deal_view',
      data: {
        'dealId': dealId,
        if (dealTitle != null && dealTitle.trim().isNotEmpty)
          'dealTitle': dealTitle.trim(),
      },
    );
  }

  static Future<void> logEventView({
    required String venueId,
    required String eventId,
    String? eventTitle,
  }) {
    return logEvent(
      venueId: venueId,
      type: 'event_view',
      data: {
        'eventId': eventId,
        if (eventTitle != null && eventTitle.trim().isNotEmpty)
          'eventTitle': eventTitle.trim(),
      },
    );
  }

  static Query<Map<String, dynamic>> _baseQuery({
    required String type,
    String? venueId,
    List<String>? venueIds,
    DateTime? since,
  }) {
    Query<Map<String, dynamic>> query = _analytics.where('type', isEqualTo: type);

    if (venueId != null) {
      query = query.where('venueId', isEqualTo: venueId);
    } else if (venueIds != null && venueIds.isNotEmpty) {
      query = query.where('venueId', whereIn: venueIds);
    }

    if (since != null) {
      query = query.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(since),
      );
    }

    return query;
  }

  static Future<int> countEvents({
    required String venueId,
    required String type,
    DateTime? since,
  }) async {
    final snapshot = await _baseQuery(
      venueId: venueId,
      type: type,
      since: since,
    ).count().get();

    return snapshot.count ?? 0;
  }

  static Future<int> countEventsForVenues({
    required List<String> venueIds,
    required String type,
    DateTime? since,
  }) async {
    final cleanVenueIds = venueIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (cleanVenueIds.isEmpty) return 0;

    var total = 0;

    for (var i = 0; i < cleanVenueIds.length; i += 30) {
      final end = i + 30 > cleanVenueIds.length ? cleanVenueIds.length : i + 30;
      final batch = cleanVenueIds.sublist(i, end);

      final snapshot = await _baseQuery(
        venueIds: batch,
        type: type,
        since: since,
      ).count().get();

      total += snapshot.count ?? 0;
    }

    return total;
  }

  static Future<AnalyticsSummary> getVenueSummary({
    required String venueId,
    required AnalyticsRange range,
  }) async {
    final since = range.since;

    final results = await Future.wait<int>([
      countEvents(venueId: venueId, type: 'venue_view', since: since),
      countEvents(venueId: venueId, type: 'favourite_tap', since: since),
      countEvents(venueId: venueId, type: 'crowd_update', since: since),
      countEvents(venueId: venueId, type: 'drink_view', since: since),
      countEvents(venueId: venueId, type: 'deal_view', since: since),
      countEvents(venueId: venueId, type: 'event_view', since: since),
    ]);

    final topDrinks = await topItemsForVenue(
      venueId: venueId,
      type: 'drink_view',
      idKey: 'drinkId',
      nameKey: 'drinkName',
      since: since,
    );

    final topDeals = await topItemsForVenue(
      venueId: venueId,
      type: 'deal_view',
      idKey: 'dealId',
      nameKey: 'dealTitle',
      since: since,
    );

    final crowdTrends = await crowdTrendForVenue(
      venueId: venueId,
      since: since,
    );

    return AnalyticsSummary(
      venueViews: results[0],
      favouriteTaps: results[1],
      crowdUpdates: results[2],
      drinkViews: results[3],
      dealViews: results[4],
      eventViews: results[5],
      topDrinks: topDrinks,
      topDeals: topDeals,
      crowdTrends: crowdTrends,
    );
  }

  static Future<AnalyticsSummary> getOwnerSummary({
    required List<String> venueIds,
    required AnalyticsRange range,
  }) async {
    final since = range.since;

    final results = await Future.wait<int>([
      countEventsForVenues(venueIds: venueIds, type: 'venue_view', since: since),
      countEventsForVenues(venueIds: venueIds, type: 'favourite_tap', since: since),
      countEventsForVenues(venueIds: venueIds, type: 'crowd_update', since: since),
      countEventsForVenues(venueIds: venueIds, type: 'drink_view', since: since),
      countEventsForVenues(venueIds: venueIds, type: 'deal_view', since: since),
      countEventsForVenues(venueIds: venueIds, type: 'event_view', since: since),
    ]);

    return AnalyticsSummary(
      venueViews: results[0],
      favouriteTaps: results[1],
      crowdUpdates: results[2],
      drinkViews: results[3],
      dealViews: results[4],
      eventViews: results[5],
      topDrinks: const [],
      topDeals: const [],
      crowdTrends: const [],
    );
  }

  static Future<List<TopAnalyticsItem>> topItemsForVenue({
    required String venueId,
    required String type,
    required String idKey,
    required String nameKey,
    DateTime? since,
    int limit = 5,
  }) async {
    final snapshot = await _baseQuery(
      venueId: venueId,
      type: type,
      since: since,
    ).get();

    final counts = <String, int>{};
    final names = <String, String>{};

    for (final doc in snapshot.docs) {
      final data = doc.data()['data'];
      if (data is! Map) continue;

      final id = data[idKey]?.toString() ?? '';
      if (id.isEmpty) continue;

      counts[id] = (counts[id] ?? 0) + 1;

      final name = data[nameKey]?.toString() ?? '';
      if (name.isNotEmpty) names[id] = name;
    }

    final items = counts.entries
        .map(
          (entry) => TopAnalyticsItem(
            id: entry.key,
            name: names[entry.key] ?? entry.key,
            count: entry.value,
          ),
        )
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return items.take(limit).toList();
  }

  static Future<List<CrowdTrendPoint>> crowdTrendForVenue({
    required String venueId,
    DateTime? since,
  }) async {
    final snapshot = await _baseQuery(
      venueId: venueId,
      type: 'crowd_update',
      since: since,
    ).get();

    final counts = <String, int>{};

    for (final doc in snapshot.docs) {
      final data = doc.data()['data'];
      if (data is! Map) continue;

      final level = data['level']?.toString().trim();
      if (level == null || level.isEmpty) continue;

      counts[level] = (counts[level] ?? 0) + 1;
    }

    final items = counts.entries
        .map((entry) => CrowdTrendPoint(label: entry.key, count: entry.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return items;
  }


  static Future<WeeklyGrowthMetric> getWeeklyGrowthForVenue({
    required String venueId,
    DateTime? now,
  }) async {
    final cleanVenueId = venueId.trim();
    if (cleanVenueId.isEmpty) {
      return const WeeklyGrowthMetric(
        thisWeekScore: 0,
        lastWeekScore: 0,
        percentageChange: 0,
      );
    }

    final currentNow = now ?? DateTime.now();
    final thisWeekStart = currentNow.subtract(const Duration(days: 7));
    final lastWeekStart = currentNow.subtract(const Duration(days: 14));

    final snapshot = await _analytics
        .where('venueId', isEqualTo: cleanVenueId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(lastWeekStart))
        .where('createdAt', isLessThan: Timestamp.fromDate(currentNow))
        .get();

    var thisWeekScore = 0;
    var lastWeekScore = 0;

    for (final doc in snapshot.docs) {
      final createdAt = doc.data()['createdAt'];
      if (createdAt is! Timestamp) continue;

      final createdDate = createdAt.toDate();

      if (!createdDate.isBefore(thisWeekStart)) {
        thisWeekScore++;
      } else {
        lastWeekScore++;
      }
    }

    double percentageChange;

    if (lastWeekScore == 0 && thisWeekScore == 0) {
      percentageChange = 0;
    } else if (lastWeekScore == 0) {
      percentageChange = 100;
    } else {
      percentageChange =
          ((thisWeekScore - lastWeekScore) / lastWeekScore) * 100;
    }

    return WeeklyGrowthMetric(
      thisWeekScore: thisWeekScore,
      lastWeekScore: lastWeekScore,
      percentageChange: percentageChange,
    );
  }

  static Future<void> logNotificationLead({
    required String venueId,
    required String trigger,
    Map<String, dynamic>? data,
  }) {
    return logEvent(
      venueId: venueId,
      type: 'notification_lead',
      data: {
        'trigger': trigger,
        ...?data,
      },
    );
  }
}
