/// Venue profile completion progress calculated from profile fields.
final class VenueProfileCompletion {
  const VenueProfileCompletion({
    required this.completedSteps,
    required this.totalSteps,
  });

  final int completedSteps;
  final int totalSteps;

  int get percentage {
    if (totalSteps <= 0) return 0;
    return ((completedSteps / totalSteps) * 100).round().clamp(0, 100);
  }

  double get progressFraction {
    if (totalSteps <= 0) return 0;
    return (completedSteps / totalSteps).clamp(0.0, 1.0);
  }

  String get progressLabel =>
      '$completedSteps out of $totalSteps steps completed';

  static const totalChecklistSteps = 10;

  static const VenueProfileCompletion empty = VenueProfileCompletion(
    completedSteps: 0,
    totalSteps: totalChecklistSteps,
  );

  /// Placeholder kept for legacy tests only.
  static const VenueProfileCompletion mock = VenueProfileCompletion(
    completedSteps: 7,
    totalSteps: 10,
  );
}
