import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/vexda_firebase.dart';
import '../models/venue_dashboard_date_range.dart';
import '../models/venue_profile_views_chart_data.dart';

/// Reads venue analytics events from the shared `analytics` collection.
class VenueAnalyticsService {
  VenueAnalyticsService({FirebaseFirestore? firestore})
      : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  FirebaseFirestore? get _db {
    if (_firestoreOverride != null) return _firestoreOverride;
    if (!VexdaFirebase.isReady) return null;
    return FirebaseFirestore.instance;
  }

  CollectionReference<Map<String, dynamic>>? get _analytics =>
      _db?.collection('analytics');

  Future<int> countEvents({
    required String venueId,
    required String type,
    DateTime? since,
    DateTime? until,
  }) async {
    final collection = _analytics;
    if (collection == null || venueId.trim().isEmpty) return 0;

    try {
      Query<Map<String, dynamic>> query = collection
          .where('venueId', isEqualTo: venueId)
          .where('type', isEqualTo: type);

      if (since != null) {
        query = query.where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(since),
        );
      }
      if (until != null) {
        query = query.where(
          'createdAt',
          isLessThan: Timestamp.fromDate(until),
        );
      }

      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } on FirebaseException {
      return 0;
    }
  }

  Future<VenueAnalyticsSnapshot> loadSnapshot({
    required String venueId,
    required VenueDashboardDateRange range,
  }) async {
    final since = range.since;
    final previousSince = range.previousPeriodSince;

    final current = await _loadCounts(venueId: venueId, since: since);
    VenueAnalyticsCounts? previous;
    if (previousSince != null && since != null) {
      previous = await _loadCounts(
        venueId: venueId,
        since: previousSince,
        until: since,
      );
    }

    final chartPoints = await loadProfileViewsOverTime(
      venueId: venueId,
      range: range,
    );

    final hasData = current.total > 0 || chartPoints.isNotEmpty;

    return VenueAnalyticsSnapshot(
      current: current,
      previous: previous,
      chartPoints: chartPoints,
      hasData: hasData,
    );
  }

  Future<VenueAnalyticsCounts> _loadCounts({
    required String venueId,
    DateTime? since,
    DateTime? until,
  }) async {
    final results = await Future.wait<int>([
      countEvents(venueId: venueId, type: 'venue_view', since: since, until: until),
      countEvents(venueId: venueId, type: 'favourite_tap', since: since, until: until),
      countEvents(venueId: venueId, type: 'drink_view', since: since, until: until),
      countEvents(venueId: venueId, type: 'deal_view', since: since, until: until),
      countEvents(venueId: venueId, type: 'event_view', since: since, until: until),
    ]);

    return VenueAnalyticsCounts(
      profileViews: results[0],
      saves: results[1],
      drinkViews: results[2],
      dealViews: results[3],
      eventViews: results[4],
    );
  }

  Future<List<VenueProfileViewsDataPoint>> loadProfileViewsOverTime({
    required String venueId,
    required VenueDashboardDateRange range,
  }) async {
    final collection = _analytics;
    if (collection == null || venueId.trim().isEmpty) return const [];

    try {
      Query<Map<String, dynamic>> query = collection
          .where('venueId', isEqualTo: venueId)
          .where('type', isEqualTo: 'venue_view');

      final since = range.since;
      if (since != null) {
        query = query.where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(since),
        );
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) return const [];

      final buckets = <String, double>{};
      for (final doc in snapshot.docs) {
        final createdAt = doc.data()['createdAt'];
        if (createdAt is! Timestamp) continue;
        final label = _bucketLabel(createdAt.toDate(), range);
        buckets[label] = (buckets[label] ?? 0) + 1;
      }

      if (buckets.isEmpty) return const [];

      final orderedLabels = _orderedBucketLabels(range, buckets.keys.toList());
      return orderedLabels
          .map(
            (label) => VenueProfileViewsDataPoint(
              label: label,
              value: buckets[label] ?? 0,
            ),
          )
          .toList();
    } on FirebaseException {
      return const [];
    }
  }

  static double? percentChange(int current, int? previous) {
    if (previous == null) return null;
    if (previous == 0 && current == 0) return 0;
    if (previous == 0) return 100;
    return ((current - previous) / previous) * 100;
  }

  String _bucketLabel(DateTime date, VenueDashboardDateRange range) {
    return switch (range) {
      VenueDashboardDateRange.today =>
        '${((date.hour + 11) ~/ 12) * 12}${date.hour >= 12 ? 'pm' : 'am'}',
      VenueDashboardDateRange.last3Days ||
      VenueDashboardDateRange.last7Days =>
        _weekdayLabel(date.weekday),
      VenueDashboardDateRange.lastMonth => 'W${_weekOfMonth(date)}',
      VenueDashboardDateRange.allTime => _monthLabel(date.month),
      VenueDashboardDateRange.custom => _weekdayLabel(date.weekday),
    };
  }

  List<String> _orderedBucketLabels(
    VenueDashboardDateRange range,
    List<String> labels,
  ) {
    if (range == VenueDashboardDateRange.last7Days ||
        range == VenueDashboardDateRange.custom) {
      const order = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return order.where(labels.contains).toList();
    }
    if (range == VenueDashboardDateRange.last3Days) {
      return labels;
    }
    return labels..sort();
  }

  String _weekdayLabel(int weekday) {
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

  String _monthLabel(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[(month - 1).clamp(0, 11)];
  }

  int _weekOfMonth(DateTime date) {
    return ((date.day - 1) ~/ 7) + 1;
  }

  Future<VenueAnalyticsCounts> loadTodayCounts({required String venueId}) async {
    final since = VenueDashboardDateRange.today.since;
    return _loadCounts(venueId: venueId, since: since);
  }

  Future<VenueAnalyticsTopEntities> loadTopEntitiesToday({
    required String venueId,
  }) async {
    final collection = _analytics;
    if (collection == null || venueId.trim().isEmpty) {
      return const VenueAnalyticsTopEntities();
    }

    final since = VenueDashboardDateRange.today.since;
    if (since == null) return const VenueAnalyticsTopEntities();

    try {
      final snapshot = await collection
          .where('venueId', isEqualTo: venueId)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(since),
          )
          .limit(120)
          .get();

      final drinkCounts = <String, int>{};
      final dealCounts = <String, int>{};
      final eventCounts = <String, int>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final type = data['type']?.toString() ?? '';
        final payload = data['data'];
        final payloadMap =
            payload is Map ? Map<String, dynamic>.from(payload) : null;

        switch (type) {
          case 'drink_view':
            final name = payloadMap?['drinkName']?.toString().trim();
            if (name != null && name.isNotEmpty) {
              drinkCounts[name] = (drinkCounts[name] ?? 0) + 1;
            }
          case 'deal_view':
            final title = payloadMap?['dealTitle']?.toString().trim();
            if (title != null && title.isNotEmpty) {
              dealCounts[title] = (dealCounts[title] ?? 0) + 1;
            }
          case 'event_view':
            final title = payloadMap?['eventTitle']?.toString().trim();
            if (title != null && title.isNotEmpty) {
              eventCounts[title] = (eventCounts[title] ?? 0) + 1;
            }
        }
      }

      return VenueAnalyticsTopEntities(
        topDrinkName: _topKey(drinkCounts),
        topDealTitle: _topKey(dealCounts),
        topEventTitle: _topKey(eventCounts),
      );
    } on FirebaseException {
      return const VenueAnalyticsTopEntities();
    }
  }

  String? _topKey(Map<String, int> counts) {
    if (counts.isEmpty) return null;
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}

class VenueAnalyticsTopEntities {
  const VenueAnalyticsTopEntities({
    this.topDrinkName,
    this.topDealTitle,
    this.topEventTitle,
  });

  final String? topDrinkName;
  final String? topDealTitle;
  final String? topEventTitle;
}

class VenueAnalyticsCounts {
  const VenueAnalyticsCounts({
    required this.profileViews,
    required this.saves,
    required this.drinkViews,
    required this.dealViews,
    required this.eventViews,
  });

  final int profileViews;
  final int saves;
  final int drinkViews;
  final int dealViews;
  final int eventViews;

  int get total =>
      profileViews + saves + drinkViews + dealViews + eventViews;
}

class VenueAnalyticsSnapshot {
  const VenueAnalyticsSnapshot({
    required this.current,
    required this.previous,
    required this.chartPoints,
    required this.hasData,
  });

  final VenueAnalyticsCounts current;
  final VenueAnalyticsCounts? previous;
  final List<VenueProfileViewsDataPoint> chartPoints;
  final bool hasData;
}
