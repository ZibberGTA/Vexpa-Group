/// Composite growth score for opportunity ranking.
final class GrowthScore {
  const GrowthScore({
    required this.value,
    required this.label,
    this.breakdown = const {},
  });

  final int value;
  final String label;
  final Map<String, int> breakdown;
}
