import '../domain/analytics_venue_metrics.dart';

/// Computes weekly activity growth from event timestamps.
final class AnalyticsWeeklyGrowthCalculator {
  const AnalyticsWeeklyGrowthCalculator();

  AnalyticsWeeklyGrowth compute({
    required Iterable<DateTime> eventTimestamps,
    DateTime? now,
  }) {
    final currentNow = now ?? DateTime.now();
    final thisWeekStart = currentNow.subtract(const Duration(days: 7));
    final lastWeekStart = currentNow.subtract(const Duration(days: 14));

    var thisWeekScore = 0;
    var lastWeekScore = 0;

    for (final createdDate in eventTimestamps) {
      if (createdDate.isBefore(lastWeekStart) ||
          !createdDate.isBefore(currentNow)) {
        continue;
      }

      if (!createdDate.isBefore(thisWeekStart)) {
        thisWeekScore++;
      } else {
        lastWeekScore++;
      }
    }

    double percentageChange;
    if (lastWeekScore == 0 && thisWeekScore == 0) {
      percentageChange = 0;
    } else if (lastWeekScore == 0) {
      percentageChange = 100;
    } else {
      percentageChange =
          ((thisWeekScore - lastWeekScore) / lastWeekScore) * 100;
    }

    return AnalyticsWeeklyGrowth(
      thisWeekScore: thisWeekScore,
      lastWeekScore: lastWeekScore,
      percentageChange: percentageChange,
    );
  }
}
