import '../domain/growth_action.dart';
import '../domain/growth_opportunity.dart';
import '../domain/growth_priority.dart';
import '../domain/growth_recommendation.dart';
import 'growth_constants.dart';
import 'growth_ordering.dart';

/// Shared helpers for turning opportunities into recommendations.
abstract final class GrowthRecommendationSupport {
  GrowthRecommendationSupport._();

  static GrowthRecommendation fromOpportunity(
    GrowthOpportunity opportunity, {
    String buttonLabel = '',
    String targetKey = '',
  }) {
    return GrowthRecommendation(
      id: opportunity.id,
      title: opportunity.title,
      message: opportunity.message,
      action: opportunity.action,
      priority: opportunity.priority,
      buttonLabel: buttonLabel,
      targetKey: targetKey,
    );
  }

  static List<GrowthRecommendation> topRecommendations(
    Iterable<GrowthOpportunity> opportunities, {
    int maxItems = GrowthConstants.maxRecommendations,
  }) {
    return GrowthOrdering.orderOpportunities(
      opportunities,
    ).take(maxItems).map(fromOpportunity).toList(growable: false);
  }

  static GrowthOpportunity profilePhotosOpportunity() {
    return const GrowthOpportunity(
      id: 'profile-photos',
      title: 'Add more photos',
      message: 'Venues with more photos get more views.',
      action: GrowthAction.addGalleryPhotos,
      priority: GrowthPriority.high,
      score: 80,
    );
  }

  static GrowthOpportunity createDealOpportunity() {
    return const GrowthOpportunity(
      id: 'create-deal',
      title: 'Create a new deal',
      message: 'Deals increase customer engagement.',
      action: GrowthAction.createCampaign,
      priority: GrowthPriority.high,
      score: 70,
    );
  }

  static GrowthOpportunity purchaseBoostOpportunity() {
    return const GrowthOpportunity(
      id: 'purchase-boost',
      title: 'Boost visibility',
      message: 'Push your venue higher in Trending with a paid boost.',
      action: GrowthAction.purchaseBoost,
      priority: GrowthPriority.medium,
      score: 60,
    );
  }
}
