import 'models/drink_model.dart';

/// Groups and normalises venue drinks using mobile category logic.
class VenueDrinksGrouper {
  VenueDrinksGrouper._();

  static String normaliseCategory(String? rawCategory) {
    final category = rawCategory?.trim() ?? '';
    if (category.isEmpty) return 'Other Drinks';

    final lower = category.toLowerCase();
    return switch (lower) {
      'beer' || 'beers' => 'Beers',
      'lager' || 'lagers' => 'Lagers',
      'ale' || 'ales' => 'Ales',
      'wine' || 'wines' => 'Wine',
      'red wine' => 'Red Wine',
      'white wine' => 'White Wine',
      'rose' || 'rosé' || 'rose wine' || 'rosé wine' => 'Rosé Wine',
      'cocktail' || 'cocktails' => 'Cocktails',
      'mocktail' || 'mocktails' => 'Mocktails',
      'spirit' || 'spirits' => 'Spirits',
      'whisky' || 'whiskey' => 'Whisky',
      'vodka' => 'Vodka',
      'gin' => 'Gin',
      'rum' => 'Rum',
      'tequila' => 'Tequila',
      'shots' || 'shot' => 'Shots',
      'champagne' || 'prosecco' || 'sparkling wine' => 'Sparkling',
      'soft drink' || 'soft drinks' || 'softs' => 'Soft Drinks',
      'cider' || 'ciders' => 'Cider',
      _ => category
          .split(' ')
          .where((part) => part.trim().isNotEmpty)
          .map(
            (part) =>
                '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
          )
          .join(' '),
    };
  }

  static int categorySortWeight(String category) {
    const order = <String, int>{
      'Cocktails': 0,
      'Mocktails': 1,
      'Beers': 2,
      'Lagers': 3,
      'Ales': 4,
      'Cider': 5,
      'Wine': 6,
      'Red Wine': 7,
      'White Wine': 8,
      'Rosé Wine': 9,
      'Sparkling': 10,
      'Spirits': 12,
      'Whisky': 13,
      'Vodka': 14,
      'Gin': 15,
      'Rum': 16,
      'Tequila': 17,
      'Shots': 18,
      'Soft Drinks': 19,
      'Other Drinks': 999,
    };
    return order[category] ?? 500;
  }

  static Map<String, List<DrinkModel>> groupByCategory(List<DrinkModel> drinks) {
    final grouped = <String, List<DrinkModel>>{};

    for (final drink in drinks) {
      final category = normaliseCategory(drink.category);
      grouped.putIfAbsent(category, () => []).add(drink);
    }

    for (final entries in grouped.values) {
      entries.sort((a, b) {
        if (a.available != b.available) return a.available ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    }

    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) {
        final weightCompare =
            categorySortWeight(a.key).compareTo(categorySortWeight(b.key));
        if (weightCompare != 0) return weightCompare;
        return a.key.compareTo(b.key);
      });

    return Map.fromEntries(sortedEntries);
  }

  static List<DrinkModel> filterDrinks({
    required List<DrinkModel> drinks,
    required String query,
    String? focusedCategory,
  }) {
    final normalisedQuery = query.trim().toLowerCase();
    return drinks.where((drink) {
      final category = normaliseCategory(drink.category);
      if (focusedCategory != null && category != focusedCategory) {
        return false;
      }
      if (normalisedQuery.isEmpty) return true;
      return drink.name.toLowerCase().contains(normalisedQuery) ||
          drink.description.toLowerCase().contains(normalisedQuery) ||
          category.toLowerCase().contains(normalisedQuery);
    }).toList();
  }

  static List<DrinkModel> trendingDrinks(List<DrinkModel> drinks) {
    return drinks.where((drink) => drink.available).take(4).toList();
  }
}
