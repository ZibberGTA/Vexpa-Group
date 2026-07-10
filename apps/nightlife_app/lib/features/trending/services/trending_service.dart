import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../analytics/services/analytics_service.dart';
import '../../home/models/venue_model.dart';

class TrendingScoreBreakdown {
  final double viewScore;
  final double favouriteScore;
  final double crowdScore;
  final double conversionScore;
  final double activityScore;
  final double freshnessScore;
  final double boostScore;

  const TrendingScoreBreakdown({
    required this.viewScore,
    required this.favouriteScore,
    required this.crowdScore,
    required this.conversionScore,
    required this.activityScore,
    required this.freshnessScore,
    required this.boostScore,
  });

  double get total => viewScore + favouriteScore + crowdScore + conversionScore + activityScore + freshnessScore + boostScore;
}

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

      final breakdown = _scoreVenue(
        venue: venue,
        summary: summary,
        boostScore: boostScore.toDouble(),
        since: since,
      );

      final score = breakdown.total;

      if (score > 0 || boostActive) {
        items.add(
          TrendingVenue(
            venue: venue,
            views: summary.venueViews,
            favourites: summary.favouriteTaps,
            crowdUpdates: summary.crowdUpdates,
            boostScore: boostScore,
            score: score,
            breakdown: breakdown,
          ),
        );
      }
    }

    items.sort((a, b) => b.score.compareTo(a.score));
    return items.take(limit).toList();
  }

  static TrendingScoreBreakdown _scoreVenue({
    required VenueModel venue,
    required AnalyticsSummary summary,
    required double boostScore,
    DateTime? since,
  }) {
    final views = summary.venueViews;
    final favourites = summary.favouriteTaps;
    final crowdUpdates = summary.crowdUpdates;
    final drinkViews = summary.drinkViews;
    final dealViews = summary.dealViews;
    final eventViews = summary.eventViews;

    // Logarithmic scoring prevents one massive venue from permanently dominating.
    final viewScore = log(views + 1) * 9;
    final favouriteScore = log(favourites + 1) * 18;
    final crowdScore = log(crowdUpdates + 1) * 12 + _crowdLevelBonus(venue.crowdLevel);

    // Rewards venues that convert views into saves, without overrewarding tiny samples.
    final conversion = views == 0 ? 0 : favourites / views;
    final confidence = min(1.0, views / 30);
    final conversionScore = conversion * confidence * 40;

    // Rewards live inventory activity: drinks, deals, and events that users engage with.
    final activityScore = (log(drinkViews + 1) * 5) +
        (log(dealViews + 1) * 8) +
        (log(eventViews + 1) * 8);

    // Fresh ranges should move faster; all-time still works but has less freshness pressure.
    final double freshnessScore =
    since == null ? 0.0 : _rangeFreshnessMultiplier(since) * 5.0;

    return TrendingScoreBreakdown(
      viewScore: viewScore,
      favouriteScore: favouriteScore,
      crowdScore: crowdScore,
      conversionScore: conversionScore,
      activityScore: activityScore,
      freshnessScore: freshnessScore.toDouble(),
      boostScore: boostScore,
    );
  }

  static double _rangeFreshnessMultiplier(DateTime since) {
    final ageDays = DateTime.now().difference(since).inDays.clamp(1, 30);
    return 1 / sqrt(ageDays);
  }

  static int _crowdLevelBonus(String crowdLevel) {
    switch (crowdLevel.toLowerCase()) {
      case 'packed':
        return 24;
      case 'busy':
        return 16;
      case 'medium':
      case 'moderate':
        return 8;
      default:
        return 0;
    }
  }

  static bool _isBoostActive(Map<String, dynamic>? data) {
    if (data == null || data['active'] != true) return false;
    final endsAt = data['endsAt'];
    if (endsAt is Timestamp) return endsAt.toDate().isAfter(DateTime.now());
    return true;
  }
}
