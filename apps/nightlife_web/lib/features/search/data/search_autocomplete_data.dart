/// Hardcoded autocomplete suggestions — UI preview only.
class SearchAutocompleteData {
  SearchAutocompleteData._();

  static const List<String> suggestions = [
    'Beer',
    'Beer Garden',
    'Belgian Beer',
    'Becks',
    'Bermondsey',
    'Cocktail',
    'Cocktail Bar',
    'Cocktail Trail',
    'London',
    'London Bridge',
    'London Fields',
    'Live Music',
    'Late Night',
    'Rooftop',
    'Shoreditch',
    'Manchester',
    'Happy Hour',
    'Whisky',
    'DJ Set',
    'Trail',
  ];

  static List<String> match(String query, {int limit = 5}) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final lower = trimmed.toLowerCase();
    return suggestions
        .where((item) => item.toLowerCase().contains(lower))
        .take(limit)
        .toList();
  }
}
