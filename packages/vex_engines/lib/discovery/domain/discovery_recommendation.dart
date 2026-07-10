/// Inputs for venue recommendation scoring.
final class RecommendationScoreInput {
  const RecommendationScoreInput({
    required this.crowdLevel,
    required this.activeDealCount,
    required this.upcomingEventCount,
    this.hasDealsFlag = false,
  });

  final String crowdLevel;
  final int activeDealCount;
  final int upcomingEventCount;
  final bool hasDealsFlag;
}

/// Scored recommendation output from discovery rules.
final class RecommendationScoreResult {
  const RecommendationScoreResult({required this.score, required this.reason});

  final int score;
  final String reason;

  bool get isEligible => score > 0;
}
