import '../../venue/data/models/drink_model.dart';

/// Configurable limit for featured drinks shown in the customer app.
class FeaturedDrinksLimit {
  FeaturedDrinksLimit._();

  static const int maxFeaturedDrinks = 5;

  static const String limitMessage =
      'You can feature up to 5 drinks. Unfeature another drink first.';

  static int countFeatured(Iterable<DrinkModel> drinks) =>
      drinks.where((drink) => drink.featured).length;

  static String? validateAdd({
    required bool wantsFeatured,
    required Iterable<DrinkModel> venueDrinks,
  }) {
    if (!wantsFeatured) return null;
    if (countFeatured(venueDrinks) >= maxFeaturedDrinks) {
      return limitMessage;
    }
    return null;
  }

  static String? validateEdit({
    required DrinkModel drink,
    required bool wantsFeatured,
    required Iterable<DrinkModel> venueDrinks,
  }) {
    if (!wantsFeatured || drink.featured) return null;

    final otherFeatured = venueDrinks
        .where((item) => item.featured && item.id != drink.id)
        .length;
    if (otherFeatured >= maxFeaturedDrinks) {
      return limitMessage;
    }
    return null;
  }

  static String? validateBulkEdit({
    required Iterable<DrinkModel> selectedDrinks,
    required Iterable<DrinkModel> venueDrinks,
    required Iterable<bool> proposedFeaturedValues,
  }) {
    final editingIds = selectedDrinks.map((drink) => drink.id).toSet();
    final unchangedFeatured = venueDrinks
        .where((drink) => drink.featured && !editingIds.contains(drink.id))
        .length;
    final proposedFeatured =
        proposedFeaturedValues.where((value) => value).length;

    if (unchangedFeatured + proposedFeatured > maxFeaturedDrinks) {
      return limitMessage;
    }
    return null;
  }
}
