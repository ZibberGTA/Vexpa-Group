/// Analytics inputs for trending score calculation.
final class TrendingScoreInput {
  const TrendingScoreInput({
    required this.venueViews,
    required this.favouriteTaps,
    required this.crowdUpdates,
    required this.drinkViews,
    required this.dealViews,
    required this.eventViews,
    required this.crowdLevel,
    required this.boostScore,
    this.rangeSince,
  });

  final int venueViews;
  final int favouriteTaps;
  final int crowdUpdates;
  final int drinkViews;
  final int dealViews;
  final int eventViews;
  final String crowdLevel;
  final double boostScore;
  final DateTime? rangeSince;
}

/// Breakdown of trending score components.
final class TrendingScoreBreakdown {
  const TrendingScoreBreakdown({
    required this.viewScore,
    required this.favouriteScore,
    required this.crowdScore,
    required this.conversionScore,
    required this.activityScore,
    required this.freshnessScore,
    required this.boostScore,
  });

  final double viewScore;
  final double favouriteScore;
  final double crowdScore;
  final double conversionScore;
  final double activityScore;
  final double freshnessScore;
  final double boostScore;

  double get total =>
      viewScore +
      favouriteScore +
      crowdScore +
      conversionScore +
      activityScore +
      freshnessScore +
      boostScore;
}

/// Ranked trending result returned by the discovery scorer.
final class TrendingScoreResult {
  const TrendingScoreResult({required this.score, required this.breakdown});

  final double score;
  final TrendingScoreBreakdown breakdown;

  double conversionRate(int views, int favourites) =>
      views == 0 ? 0 : (favourites / views) * 100;
}
