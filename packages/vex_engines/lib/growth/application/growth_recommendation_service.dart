import '../domain/growth_action.dart';
import '../domain/growth_opportunity.dart';
import '../domain/growth_performance.dart';
import '../domain/growth_priority.dart';
import '../shared/growth_constants.dart';
import '../shared/growth_ordering.dart';
import '../shared/growth_recommendation_support.dart';

/// Input for venue growth advice composition.
final class GrowthAdviceInput {
  const GrowthAdviceInput({
    required this.hasGalleryPhotos,
    this.dealCount = 0,
    this.hasUpcomingEvent = false,
    this.profileCompletionRemaining = 0,
    this.hasActiveBoost = false,
    required this.performance,
  });

  final bool hasGalleryPhotos;
  final int dealCount;
  final bool hasUpcomingEvent;
  final int profileCompletionRemaining;
  final bool hasActiveBoost;
  final GrowthPerformance performance;
}

/// Composes ranked growth opportunities and commercial advice.
final class GrowthRecommendationService {
  const GrowthRecommendationService();

  List<GrowthOpportunity> composeOpportunities(GrowthAdviceInput input) {
    final opportunities = <GrowthOpportunity>[];

    if (!input.hasGalleryPhotos) {
      opportunities.add(GrowthRecommendationSupport.profilePhotosOpportunity());
    }
    if (input.dealCount == 0) {
      opportunities.add(GrowthRecommendationSupport.createDealOpportunity());
    }
    if (!input.hasUpcomingEvent) {
      opportunities.add(
        const GrowthOpportunity(
          id: 'add-event',
          title: 'Add an upcoming event',
          message: 'Events bring more people through the door.',
          action: GrowthAction.addEvent,
          priority: GrowthPriority.high,
          score: 65,
        ),
      );
    }
    if (input.profileCompletionRemaining > 0) {
      opportunities.add(
        GrowthOpportunity(
          id: 'complete-profile',
          title: 'Complete your profile',
          message:
              'Finish ${input.profileCompletionRemaining} more steps to boost visibility.',
          action: GrowthAction.improveProfile,
          priority: GrowthPriority.medium,
          score: 50,
        ),
      );
    }
    if (!input.hasActiveBoost && input.performance.roiSignalLabel != 'Strong') {
      opportunities.add(GrowthRecommendationSupport.purchaseBoostOpportunity());
    }

    return GrowthOrdering.orderOpportunities(
      opportunities,
    ).take(GrowthConstants.maxRecommendations).toList(growable: false);
  }
}
