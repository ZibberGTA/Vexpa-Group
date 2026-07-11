/// Builds venue Firestore search-term sets for mobile indexing and writes.
final class DiscoveryVenueSearchTermBuilder {
  DiscoveryVenueSearchTermBuilder._();

  static void addIndexText(Set<String> terms, String value) {
    final normalized = value.toLowerCase().trim();
    if (normalized.isEmpty) return;

    terms.add(normalized);

    for (final part in normalized.split(RegExp(r'[\s\-/_,.&]+'))) {
      final cleaned = part.trim();
      if (cleaned.isNotEmpty) {
        terms.add(cleaned);
      }
    }
  }

  static void applyWhiskyAlias(Set<String> terms) {
    if (terms.contains('whisky')) terms.add('whiskey');
    if (terms.contains('whiskey')) terms.add('whisky');
  }

  /// Full venue index terms used by catalog sync and search indexing.
  static List<String> buildVenueIndexTerms({
    required String venueName,
    required String category,
    String address = '',
    String description = '',
    List<String> drinks = const [],
    List<String> deals = const [],
    List<String> events = const [],
  }) {
    final terms = <String>{};

    for (final item in <String>[
      venueName,
      category,
      address,
      description,
      ...drinks,
      ...deals,
      ...events,
    ]) {
      addIndexText(terms, item);
    }

    applyWhiskyAlias(terms);
    return terms.toList()..sort();
  }

  /// Terms written from venue create/edit forms (includes crowd level tokens).
  static List<String> buildVenueFormTerms({
    required String name,
    required String description,
    required String address,
    required String category,
    required String crowdLevel,
  }) {
    return <String>[
      name,
      description,
      address,
      category,
      crowdLevel,
      ...name.split(RegExp(r'\s+')),
      ...description.split(RegExp(r'\s+')),
      ...address.split(RegExp(r'\s+')),
      ...category.split(RegExp(r'\s+')),
    ]
        .map((term) => term.trim().toLowerCase())
        .where((term) => term.isNotEmpty)
        .toSet()
        .toList();
  }

  /// Minimal lowercased field list for quick owner venue creation.
  static List<String> buildMinimalVenueTerms({
    required String name,
    required String description,
    required String address,
    required String category,
    required String crowdLevel,
  }) {
    return [
      name.toLowerCase(),
      description.toLowerCase(),
      address.toLowerCase(),
      category.toLowerCase(),
      crowdLevel.toLowerCase(),
    ];
  }

  /// Simple normalised terms from arbitrary string fields (deleted-item archive).
  static List<String> buildFromFieldValues(Iterable<String> values) {
    return values
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
  }

  /// Venue sync path: venue fields plus related drink names.
  static List<String> buildFromFirestoreVenueSync({
    required String name,
    required String category,
    required String address,
    required String description,
    required Iterable<String> drinkNames,
  }) {
    final terms = <String>{};

    for (final value in [name, category, address, description, ...drinkNames]) {
      addIndexText(terms, value);
    }

    applyWhiskyAlias(terms);
    return terms.toList();
  }
}
