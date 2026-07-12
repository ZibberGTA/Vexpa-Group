import '../domain/growth_issue.dart';
import '../shared/growth_formatting.dart';
import '../shared/growth_product_catalog.dart';

/// Subscription and product comparison helpers.
final class GrowthComparisonService {
  const GrowthComparisonService();

  List<GrowthVenuePlanProduct> compareVenuePlans({
    required String currentPlanId,
  }) {
    final currentIndex = GrowthProductCatalog.webVenuePlans.indexWhere(
      (plan) => plan.id == currentPlanId.trim().toLowerCase(),
    );
    if (currentIndex < 0) {
      return GrowthProductCatalog.webVenuePlans;
    }
    return GrowthProductCatalog.webVenuePlans
        .skip(currentIndex)
        .toList(growable: false);
  }

  int priceDifferenceGbp({
    required String fromPlanId,
    required String toPlanId,
  }) {
    final from = GrowthProductCatalog.venuePlanById(fromPlanId);
    final to = GrowthProductCatalog.venuePlanById(toPlanId);
    if (from == null || to == null) return 0;
    return to.monthlyPriceGbp - from.monthlyPriceGbp;
  }

  int discountedPriceGbp(int monthlyPriceGbp) {
    return GrowthFormatting.discountedLaunchPriceGbp(monthlyPriceGbp);
  }

  List<GrowthIssue> detectPlanConflicts({
    required String venuePlanId,
    required String? consumerPlanId,
  }) {
    if (consumerPlanId == null || consumerPlanId.trim().isEmpty) {
      return const [];
    }

    final normalizedConsumer = consumerPlanId.trim().toLowerCase();
    if (normalizedConsumer == GrowthProductCatalog.venueProConsumerPlanId &&
        venuePlanId.trim().toLowerCase() ==
            GrowthProductCatalog.venueProConsumerPlanId) {
      return const [];
    }

    if (normalizedConsumer == GrowthProductCatalog.venueProConsumerPlanId &&
        venuePlanId.trim().isNotEmpty &&
        venuePlanId.trim().toLowerCase() !=
            GrowthProductCatalog.venueProConsumerPlanId) {
      return const [
        GrowthIssue(
          code: 'mixed-product-models',
          message:
              'Venue web tier and mobile Owner Pro use different billing products.',
        ),
      ];
    }

    return const [];
  }
}
