import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vex_engines/analytics/application/analytics_chart_series_builder.dart';
import 'package:vex_engines/analytics/application/analytics_metrics_composer.dart';
import 'package:vex_engines/analytics/application/analytics_percent_change.dart';
import 'package:vex_engines/analytics/application/analytics_top_entity_aggregator.dart';
import 'package:vex_engines/analytics/domain/analytics_chart_period.dart';
import 'package:vex_engines/analytics/domain/analytics_event_record.dart';
import 'package:vex_engines/analytics/domain/analytics_venue_metrics.dart';

import '../../../core/firebase/vexda_firebase.dart';
import '../models/venue_dashboard_date_range.dart';
import '../models/venue_profile_views_chart_data.dart';

/// Reads venue analytics events from the shared `analytics` collection.
class VenueAnalyticsService {
  VenueAnalyticsService({
    FirebaseFirestore? firestore,
    AnalyticsMetricsComposer? metricsComposer,
    AnalyticsChartSeriesBuilder? chartSeriesBuilder,
    AnalyticsTopEntityAggregator? topEntityAggregator,
  })  : _firestoreOverride = firestore,
        _metricsComposer = metricsComposer ?? const AnalyticsMetricsComposer(),
        _chartSeriesBuilder =
            chartSeriesBuilder ?? const AnalyticsChartSeriesBuilder(),
        _topEntityAggregator =
            topEntityAggregator ?? const AnalyticsTopEntityAggregator();

  final FirebaseFirestore? _firestoreOverride;
  final AnalyticsMetricsComposer _metricsComposer;
  final AnalyticsChartSeriesBuilder _chartSeriesBuilder;
  final AnalyticsTopEntityAggregator _topEntityAggregator;

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

    final hasData = _metricsComposer.snapshotHasData(
      current: AnalyticsVenueMetrics(
        profileViews: current.profileViews,
        saves: current.saves,
        drinkViews: current.drinkViews,
        dealViews: current.dealViews,
        eventViews: current.eventViews,
      ),
      chartPoints: chartPoints,
    );

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

    final metrics = _metricsComposer.fromDashboardCounts(results);
    return VenueAnalyticsCounts(
      profileViews: metrics.profileViews,
      saves: metrics.saves,
      drinkViews: metrics.drinkViews,
      dealViews: metrics.dealViews,
      eventViews: metrics.eventViews,
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

      final timestamps = <DateTime>[];
      for (final doc in snapshot.docs) {
        final createdAt = doc.data()['createdAt'];
        if (createdAt is Timestamp) {
          timestamps.add(createdAt.toDate());
        }
      }

      final series = _chartSeriesBuilder.buildProfileViewsSeries(
        timestamps: timestamps,
        period: _chartPeriod(range),
      );

      return series
          .map(
            (point) => VenueProfileViewsDataPoint(
              label: point.label,
              value: point.value,
            ),
          )
          .toList();
    } on FirebaseException {
      return const [];
    }
  }

  static double? percentChange(int current, int? previous) =>
      AnalyticsPercentChange.calculate(current, previous);

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

      final records = snapshot.docs.map((doc) {
        final data = doc.data();
        final payload = data['data'];
        return AnalyticsEventRecord(
          type: data['type']?.toString() ?? '',
          payload: payload is Map
              ? Map<String, dynamic>.from(payload)
              : const {},
          createdAt: data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : null,
        );
      });

      final top = _topEntityAggregator.aggregateTodayEntities(records);
      return VenueAnalyticsTopEntities(
        topDrinkName: top.topDrinkName,
        topDealTitle: top.topDealTitle,
        topEventTitle: top.topEventTitle,
      );
    } on FirebaseException {
      return const VenueAnalyticsTopEntities();
    }
  }

  static AnalyticsChartPeriod _chartPeriod(VenueDashboardDateRange range) {
    return switch (range) {
      VenueDashboardDateRange.today => AnalyticsChartPeriod.today,
      VenueDashboardDateRange.last3Days => AnalyticsChartPeriod.last3Days,
      VenueDashboardDateRange.last7Days => AnalyticsChartPeriod.last7Days,
      VenueDashboardDateRange.lastMonth => AnalyticsChartPeriod.lastMonth,
      VenueDashboardDateRange.allTime => AnalyticsChartPeriod.allTime,
      VenueDashboardDateRange.custom => AnalyticsChartPeriod.custom,
    };
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
