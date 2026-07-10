import '../../venue/data/models/deal_model.dart';
import 'package:vex_engines/experience/application/experience_featured_limit.dart';

/// Configurable limit for featured deals on the public venue profile.
class FeaturedDealsLimit {
  FeaturedDealsLimit._();

  static const _limit = ExperienceFeaturedLimit.deals;

  static int get maxFeaturedDeals => _limit.maxFeatured;

  static String get limitMessage => _limit.limitMessage;

  static int countFeatured(Iterable<DealModel> deals) =>
      _limit.countFeatured(deals, (deal) => deal.featured);

  static String? validateAdd({
    required bool wantsFeatured,
    required Iterable<DealModel> venueDeals,
  }) =>
      _limit.validateAdd(
        wantsFeatured: wantsFeatured,
        venueItems: venueDeals,
        isFeatured: (deal) => deal.featured,
      );

  static String? validateEdit({
    required DealModel deal,
    required bool wantsFeatured,
    required Iterable<DealModel> venueDeals,
  }) =>
      _limit.validateEdit(
        item: deal,
        currentlyFeatured: deal.featured,
        wantsFeatured: wantsFeatured,
        venueItems: venueDeals,
        isFeatured: (item) => item.featured,
        isSameItem: (item) => item.id == deal.id,
      );

  static String? validateBulkEdit({
    required Iterable<DealModel> selectedDeals,
    required Iterable<DealModel> venueDeals,
    required Iterable<bool> proposedFeaturedValues,
  }) {
    final editingIds = selectedDeals.map((deal) => deal.id).toSet();
    return _limit.validateBulkEdit(
      selectedItems: selectedDeals,
      venueItems: venueDeals,
      proposedFeaturedValues: proposedFeaturedValues,
      isFeatured: (deal) => deal.featured,
      isSelected: (deal) => editingIds.contains(deal.id),
    );
  }
}
