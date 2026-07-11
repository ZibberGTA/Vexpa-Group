import 'package:vex_engines/experience/application/experience_drink_grouper.dart';

import 'models/drink_model.dart';

/// Groups and normalises venue drinks using Experience Engine menu rules.
class VenueDrinksGrouper {
  VenueDrinksGrouper._();

  static String normaliseCategory(String? rawCategory) =>
      ExperienceDrinkGrouper.normaliseCategory(rawCategory);

  static int categorySortWeight(String category) =>
      ExperienceDrinkGrouper.categorySortWeight(category);

  static Map<String, List<DrinkModel>> groupByCategory(List<DrinkModel> drinks) =>
      ExperienceDrinkGrouper.groupByCategory(
        drinks,
        category: (drink) => drink.category,
        name: (drink) => drink.name,
        available: (drink) => drink.available,
      );

  static List<DrinkModel> filterDrinks({
    required List<DrinkModel> drinks,
    required String query,
    String? focusedCategory,
  }) =>
      ExperienceDrinkGrouper.filterDrinks(
        drinks: drinks,
        query: query,
        category: (drink) => drink.category,
        name: (drink) => drink.name,
        description: (drink) => drink.description,
        focusedCategory: focusedCategory,
      );

  static List<DrinkModel> trendingDrinks(List<DrinkModel> drinks) =>
      ExperienceDrinkGrouper.trendingDrinks(
        drinks,
        available: (drink) => drink.available,
      );
}
