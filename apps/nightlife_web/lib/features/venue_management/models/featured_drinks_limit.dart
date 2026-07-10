import '../../venue/data/models/drink_model.dart';
import 'package:vex_engines/experience/application/experience_featured_limit.dart';

/// Configurable limit for featured drinks shown in the customer app.
class FeaturedDrinksLimit {
  FeaturedDrinksLimit._();

  static const _limit = ExperienceFeaturedLimit.drinks;

  static int get maxFeaturedDrinks => _limit.maxFeatured;

  static String get limitMessage => _limit.limitMessage;

  static int countFeatured(Iterable<DrinkModel> drinks) =>
      _limit.countFeatured(drinks, (drink) => drink.featured);

  static String? validateAdd({
    required bool wantsFeatured,
    required Iterable<DrinkModel> venueDrinks,
  }) =>
      _limit.validateAdd(
        wantsFeatured: wantsFeatured,
        venueItems: venueDrinks,
        isFeatured: (drink) => drink.featured,
      );

  static String? validateEdit({
    required DrinkModel drink,
    required bool wantsFeatured,
    required Iterable<DrinkModel> venueDrinks,
  }) =>
      _limit.validateEdit(
        item: drink,
        currentlyFeatured: drink.featured,
        wantsFeatured: wantsFeatured,
        venueItems: venueDrinks,
        isFeatured: (item) => item.featured,
        isSameItem: (item) => item.id == drink.id,
      );

  static String? validateBulkEdit({
    required Iterable<DrinkModel> selectedDrinks,
    required Iterable<DrinkModel> venueDrinks,
    required Iterable<bool> proposedFeaturedValues,
  }) {
    final editingIds = selectedDrinks.map((drink) => drink.id).toSet();
    return _limit.validateBulkEdit(
      selectedItems: selectedDrinks,
      venueItems: venueDrinks,
      proposedFeaturedValues: proposedFeaturedValues,
      isFeatured: (drink) => drink.featured,
      isSelected: (drink) => editingIds.contains(drink.id),
    );
  }
}
