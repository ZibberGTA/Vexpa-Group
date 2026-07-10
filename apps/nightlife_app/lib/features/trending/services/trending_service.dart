import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vex_engines/discovery/application/discovery_trending_scorer.dart';
import 'package:vex_engines/discovery/domain/discovery_trending.dart';

import '../../analytics/services/analytics_service.dart';
import '../../home/models/venue_model.dart';

export 'package:vex_engines/discovery/domain/discovery_trending.dart'
    show TrendingScoreBreakdown;

class TrendingVenue {
  final VenueModel venue;
  final int views;
  final int favourites;
  final int crowdUpdates;
  final int boostScore;
  final double score;
  final TrendingScoreBreakdown breakdown;

  const TrendingVenue({
    required this.venue,
    required this.views,
    required this.favourites,
    required this.crowdUpdates,
    required this.boostScore,
    required this.score,
    required this.breakdown,
  });

  double get conversionRate => views == 0 ? 0 : (favourites / views) * 100;
}

class TrendingService {
  TrendingService._();

  static const _scorer = DiscoveryTrendingScorer();
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<List<TrendingVenue>> getTrendingVenues({
    AnalyticsRange range = AnalyticsRange.sevenDays,
    int limit = 10,
  }) async {
    final venueSnapshot = await _db
        .collection('venues')
        .where('isDeleted', isEqualTo: false)
        .get();

    final venues = venueSnapshot.docs
        .map((doc) => VenueModel.fromMap(doc.id, doc.data()))
        .toList();

    if (venues.isEmpty) return <TrendingVenue>[];

    final since = range.since;
    final items = <TrendingVenue>[];

    for (final venue in venues) {
      final boostDoc = await _db.collection('venue_boosts').doc(venue.id).get();
      final boost = boostDoc.data();
      final boostActive = _isBoostActive(boost);
      final boostScore = boostActive
          ? ((boost?['boostScore'] as num?)?.toInt() ?? 25)
          : 0;

      final summary = await AnalyticsService.getVenueSummary(
        venueId: venue.id,
        range: range,
      );

      final scored = _scorer.score(
        TrendingScoreInput(
          venueViews: summary.venueViews,
          favouriteTaps: summary.favouriteTaps,
          crowdUpdates: summary.crowdUpdates,
          drinkViews: summary.drinkViews,
          dealViews: summary.dealViews,
          eventViews: summary.eventViews,
          crowdLevel: venue.crowdLevel,
          boostScore: boostScore.toDouble(),
          rangeSince: since,
        ),
      );

      if (scored.score > 0 || boostActive) {
        items.add(
          TrendingVenue(
            venue: venue,
            views: summary.venueViews,
            favourites: summary.favouriteTaps,
            crowdUpdates: summary.crowdUpdates,
            boostScore: boostScore,
            score: scored.score,
            breakdown: scored.breakdown,
          ),
        );
      }
    }

    return _scorer.rankByScore(
      items: items,
      readScore: (item) => item.score,
      tieBreaker: (a, b) =>
          a.venue.name.toLowerCase().compareTo(b.venue.name.toLowerCase()),
      limit: limit,
    );
  }

  static bool _isBoostActive(Map<String, dynamic>? data) {
    if (data == null) return false;
    final endsAt = data['endsAt'];
    return DiscoveryBoostEvaluator.isBoostActive(
      active: data['active'] == true,
      endsAt: endsAt is Timestamp ? endsAt.toDate() : null,
    );
  }
}
