/// Groups and filters venue drinks for customer menu surfaces.
final class ExperienceDrinkGrouper {
  ExperienceDrinkGrouper._();

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

  static Map<String, List<T>> groupByCategory<T>(
    List<T> drinks, {
    required String Function(T drink) category,
    required String Function(T drink) name,
    required bool Function(T drink) available,
  }) {
    final grouped = <String, List<T>>{};

    for (final drink in drinks) {
      final key = normaliseCategory(category(drink));
      grouped.putIfAbsent(key, () => []).add(drink);
    }

    for (final entries in grouped.values) {
      entries.sort((a, b) {
        if (available(a) != available(b)) return available(a) ? -1 : 1;
        return name(a).toLowerCase().compareTo(name(b).toLowerCase());
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

  static List<T> filterDrinks<T>({
    required List<T> drinks,
    required String query,
    required String Function(T drink) category,
    required String Function(T drink) name,
    required String Function(T drink) description,
    String? focusedCategory,
  }) {
    final normalisedQuery = query.trim().toLowerCase();
    return drinks.where((drink) {
      final normalisedCategory = normaliseCategory(category(drink));
      if (focusedCategory != null && normalisedCategory != focusedCategory) {
        return false;
      }
      if (normalisedQuery.isEmpty) return true;
      return name(drink).toLowerCase().contains(normalisedQuery) ||
          description(drink).toLowerCase().contains(normalisedQuery) ||
          normalisedCategory.toLowerCase().contains(normalisedQuery);
    }).toList();
  }

  static List<T> trendingDrinks<T>(
    List<T> drinks, {
    required bool Function(T drink) available,
    int limit = 4,
  }) =>
      drinks.where(available).take(limit).toList();
}
