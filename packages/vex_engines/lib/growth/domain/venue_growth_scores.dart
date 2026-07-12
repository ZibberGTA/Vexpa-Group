/// Multi-dimensional venue growth scores for ranking and dashboards.
final class VenueGrowthScores {
  const VenueGrowthScores({
    required this.growthScore,
    required this.commercialScore,
    required this.marketingScore,
    required this.revenueScore,
    required this.overallLabel,
  });

  final int growthScore;
  final int commercialScore;
  final int marketingScore;
  final int revenueScore;
  final String overallLabel;
}
