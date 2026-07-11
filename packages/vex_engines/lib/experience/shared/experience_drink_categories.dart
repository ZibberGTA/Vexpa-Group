/// Fixed drink categories for venue-published menus.
final class ExperienceDrinkCategories {
  ExperienceDrinkCategories._();

  static const List<String> all = [
    'Cocktails',
    'Beer',
    'Cider',
    'Wine',
    'Sparkling Wine',
    'Spirits',
    'Whisky',
    'Gin',
    'Vodka',
    'Rum',
    'Tequila',
    'Brandy',
    'Liqueurs',
    'Shots',
    'Soft Drinks',
    'Mocktails',
    'Hot Drinks',
    'Low & No Alcohol',
    'Bottles',
    'Draught',
    'Other',
  ];

  static String normalize(String category) => category.trim().toLowerCase();

  static String displayName(String storedCategory) {
    final normalized = normalize(storedCategory);
    for (final category in all) {
      if (normalize(category) == normalized) {
        return category;
      }
    }
    if (storedCategory.trim().isEmpty) return 'Other';
    return _titleCase(storedCategory);
  }

  static bool isAllowed(String category) {
    return all.any((item) => normalize(item) == normalize(category));
  }

  static String _titleCase(String value) {
    return value
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              part.substring(0, 1).toUpperCase() + part.substring(1).toLowerCase(),
        )
        .join(' ');
  }
}
