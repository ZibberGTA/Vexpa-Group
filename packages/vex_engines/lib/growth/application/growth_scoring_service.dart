import '../domain/growth_performance.dart';
import '../domain/growth_score.dart';
import '../domain/venue_growth_scores.dart';
import '../shared/growth_commercial_labels.dart';

/// Computes composite growth scores for opportunity ranking.
final class GrowthScoringService {
  const GrowthScoringService();

  GrowthScore score({
    required GrowthPerformance performance,
    required int profileCompletionRemaining,
    required bool hasActiveBoost,
    required bool hasUpcomingDealOrEvent,
  }) {
    var value = 0;
    final breakdown = <String, int>{};

    final roiPoints = switch (performance.roiSignalLabel) {
      'Strong' => 40,
      'Good' => 28,
      'Build' => 16,
      _ => 8,
    };
    value += roiPoints;
    breakdown['roi'] = roiPoints;

    if (hasActiveBoost) {
      value += 20;
      breakdown['boost'] = 20;
    }
    if (hasUpcomingDealOrEvent) {
      value += 15;
      breakdown['promotion-content'] = 15;
    }
    if (profileCompletionRemaining > 0) {
      final penalty = (profileCompletionRemaining * 3).clamp(0, 18);
      value -= penalty;
      breakdown['profile-gap'] = -penalty;
    }

    value = value.clamp(0, 100);
    return GrowthScore(
      value: value,
      label: GrowthCommercialLabels.roiSignalLabel(performance.roiSignalLabel),
      breakdown: breakdown,
    );
  }

  VenueGrowthScores venueScores({
    required GrowthPerformance performance,
    required int profileCompletionRemaining,
    required bool hasActiveBoost,
    required bool hasUpcomingDealOrEvent,
    required bool hasCampaignToolsAccess,
    required int dealCount,
  }) {
    final composite = score(
      performance: performance,
      profileCompletionRemaining: profileCompletionRemaining,
      hasActiveBoost: hasActiveBoost,
      hasUpcomingDealOrEvent: hasUpcomingDealOrEvent,
    );

    final revenueScore =
        (performance.estimatedRevenueGbp / 5).round().clamp(0, 100);
    final marketingScore = _marketingScore(
      performance: performance,
      hasActiveBoost: hasActiveBoost,
      hasUpcomingDealOrEvent: hasUpcomingDealOrEvent,
      dealCount: dealCount,
    );
    final commercialScore = _commercialScore(
      compositeValue: composite.value,
      hasCampaignToolsAccess: hasCampaignToolsAccess,
      hasActiveBoost: hasActiveBoost,
    );

    final overallLabel = composite.value >= 75
        ? 'High growth potential'
        : composite.value >= 45
        ? 'Building momentum'
        : 'Early stage';

    return VenueGrowthScores(
      growthScore: composite.value,
      commercialScore: commercialScore,
      marketingScore: marketingScore,
      revenueScore: revenueScore,
      overallLabel: overallLabel,
    );
  }

  int _marketingScore({
    required GrowthPerformance performance,
    required bool hasActiveBoost,
    required bool hasUpcomingDealOrEvent,
    required int dealCount,
  }) {
    var score = 20;
    if (performance.roiSignalLabel == 'Strong') {
      score += 40;
    } else if (performance.roiSignalLabel == 'Good') {
      score += 28;
    } else if (performance.roiSignalLabel == 'Build') {
      score += 12;
    }
    if (hasActiveBoost) score += 15;
    if (hasUpcomingDealOrEvent) score += 10;
    if (dealCount > 0) score += 5;
    return score.clamp(0, 100);
  }

  int _commercialScore({
    required int compositeValue,
    required bool hasCampaignToolsAccess,
    required bool hasActiveBoost,
  }) {
    var score = (compositeValue * 0.6).round();
    if (hasCampaignToolsAccess) score += 15;
    if (hasActiveBoost) score += 10;
    return score.clamp(0, 100);
  }
}
