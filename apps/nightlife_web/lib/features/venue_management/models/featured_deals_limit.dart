import '../../venue/data/models/deal_model.dart';

/// Configurable limit for featured deals on the public venue profile.
class FeaturedDealsLimit {
  FeaturedDealsLimit._();

  static const int maxFeaturedDeals = 3;

  static const String limitMessage =
      'You can feature up to 3 deals. Unfeature another deal first.';

  static int countFeatured(Iterable<DealModel> deals) =>
      deals.where((deal) => deal.featured).length;

  static String? validateAdd({
    required bool wantsFeatured,
    required Iterable<DealModel> venueDeals,
  }) {
    if (!wantsFeatured) return null;
    if (countFeatured(venueDeals) >= maxFeaturedDeals) return limitMessage;
    return null;
  }

  static String? validateEdit({
    required DealModel deal,
    required bool wantsFeatured,
    required Iterable<DealModel> venueDeals,
  }) {
    if (!wantsFeatured || deal.featured) return null;
    final otherFeatured = venueDeals
        .where((item) => item.featured && item.id != deal.id)
        .length;
    if (otherFeatured >= maxFeaturedDeals) return limitMessage;
    return null;
  }

  static String? validateBulkEdit({
    required Iterable<DealModel> selectedDeals,
    required Iterable<DealModel> venueDeals,
    required Iterable<bool> proposedFeaturedValues,
  }) {
    final editingIds = selectedDeals.map((deal) => deal.id).toSet();
    final unchangedFeatured = venueDeals
        .where((deal) => deal.featured && !editingIds.contains(deal.id))
        .length;
    final proposedFeatured =
        proposedFeaturedValues.where((value) => value).length;

    if (unchangedFeatured + proposedFeatured > maxFeaturedDeals) {
      return limitMessage;
    }
    return null;
  }
}
