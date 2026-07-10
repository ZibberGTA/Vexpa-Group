import 'dart:math';

import '../domain/discovery_trending.dart';

/// Pure trending score calculation for discovery ranking.
final class DiscoveryTrendingScorer {
  const DiscoveryTrendingScorer();

  TrendingScoreResult score(TrendingScoreInput input) {
    final breakdown = _scoreVenue(input);
    return TrendingScoreResult(score: breakdown.total, breakdown: breakdown);
  }

  List<T> rankByScore<T>({
    required Iterable<T> items,
    required double Function(T item) readScore,
    required int Function(T a, T b) tieBreaker,
    int limit = 10,
  }) {
    final sorted = items.toList()
      ..sort((a, b) {
        final scoreDiff = readScore(b).compareTo(readScore(a));
        if (scoreDiff != 0) return scoreDiff;
        return tieBreaker(a, b);
      });
    return sorted.take(limit).toList();
  }

  TrendingScoreBreakdown _scoreVenue(TrendingScoreInput input) {
    final views = input.venueViews;
    final favourites = input.favouriteTaps;
    final crowdUpdates = input.crowdUpdates;

    final viewScore = log(views + 1) * 9;
    final favouriteScore = log(favourites + 1) * 18;
    final crowdScore =
        log(crowdUpdates + 1) * 12 + _crowdLevelBonus(input.crowdLevel);

    final conversion = views == 0 ? 0 : favourites / views;
    final confidence = min(1.0, views / 30);
    final conversionScore = conversion * confidence * 40;

    final activityScore =
        (log(input.drinkViews + 1) * 5) +
        (log(input.dealViews + 1) * 8) +
        (log(input.eventViews + 1) * 8);

    final freshnessScore = input.rangeSince == null
        ? 0.0
        : _rangeFreshnessMultiplier(input.rangeSince!) * 5.0;

    return TrendingScoreBreakdown(
      viewScore: viewScore,
      favouriteScore: favouriteScore,
      crowdScore: crowdScore,
      conversionScore: conversionScore,
      activityScore: activityScore,
      freshnessScore: freshnessScore,
      boostScore: input.boostScore,
    );
  }

  double _rangeFreshnessMultiplier(DateTime since) {
    final ageDays = DateTime.now().difference(since).inDays.clamp(1, 30);
    return 1 / sqrt(ageDays);
  }

  int _crowdLevelBonus(String crowdLevel) {
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
}

/// Evaluates whether a venue boost is active from adapter-provided data.
final class DiscoveryBoostEvaluator {
  DiscoveryBoostEvaluator._();

  static bool isBoostActive({
    required bool active,
    DateTime? endsAt,
    DateTime? now,
  }) {
    if (!active) return false;
    if (endsAt == null) return true;
    return endsAt.isAfter(now ?? DateTime.now());
  }
}
