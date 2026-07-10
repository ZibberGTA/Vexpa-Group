import 'package:cloud_firestore/cloud_firestore.dart';

import '../../analytics/services/analytics_service.dart';
import '../../monetisation/services/boost_service.dart';

class AdminDashboardMetrics {
  final int venues;
  final int users;
  final int owners;
  final int activeBoosts;
  final int paidBoosts;
  final int revenuePence;
  final AnalyticsSummary analytics;

  const AdminDashboardMetrics({
    required this.venues,
    required this.users,
    required this.owners,
    required this.activeBoosts,
    required this.paidBoosts,
    required this.revenuePence,
    required this.analytics,
  });

  String get revenueLabel => '£${(revenuePence / 100).toStringAsFixed(2)}';
}

class AdminMetricsService {
  AdminMetricsService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<int> _count(CollectionReference<Map<String, dynamic>> ref) async {
    final snapshot = await ref.count().get();
    return snapshot.count ?? 0;
  }

  static Future<int> _countQuery(Query<Map<String, dynamic>> query) async {
    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }

  static Future<AdminDashboardMetrics> getDashboardMetrics({
    AnalyticsRange range = AnalyticsRange.sevenDays,
  }) async {
    final revenue = await BoostService.revenueSummary();
    final now = Timestamp.fromDate(DateTime.now());

    final results = await Future.wait<int>([
      _countQuery(_db.collection('venues').where('isDeleted', isEqualTo: false)),
      _count(_db.collection('users')),
      _countQuery(_db.collection('users').where('role', isEqualTo: 'owner')),
      _countQuery(
        _db
            .collection('venue_boosts')
            .where('active', isEqualTo: true)
            .where('endsAt', isGreaterThan: now),
      ),
    ]);

    final analyticsResults = await Future.wait<int>([
      _countAnalytics(type: 'venue_view', range: range),
      _countAnalytics(type: 'favourite_tap', range: range),
      _countAnalytics(type: 'crowd_update', range: range),
      _countAnalytics(type: 'drink_view', range: range),
      _countAnalytics(type: 'deal_view', range: range),
      _countAnalytics(type: 'event_view', range: range),
    ]);

    return AdminDashboardMetrics(
      venues: results[0],
      users: results[1],
      owners: results[2],
      activeBoosts: results[3],
      paidBoosts: revenue['paidBoosts'] ?? 0,
      revenuePence: revenue['totalPence'] ?? 0,
      analytics: AnalyticsSummary(
        venueViews: analyticsResults[0],
        favouriteTaps: analyticsResults[1],
        crowdUpdates: analyticsResults[2],
        drinkViews: analyticsResults[3],
        dealViews: analyticsResults[4],
        eventViews: analyticsResults[5],
        topDrinks: const [],
        topDeals: const [],
        crowdTrends: const [],
      ),
    );
  }

  static Future<int> _countAnalytics({
    required String type,
    required AnalyticsRange range,
  }) async {
    Query<Map<String, dynamic>> query = _db.collection('analytics').where('type', isEqualTo: type);
    final since = range.since;
    if (since != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since));
    }
    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> recentBoostsStream() {
    return _db
        .collection('venue_boosts')
        .orderBy('startedAt', descending: true)
        .limit(20)
        .snapshots();
  }
}
