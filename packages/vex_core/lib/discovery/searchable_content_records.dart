/// Firebase-independent drink row for unified discovery search.
final class SearchableDrinkRecord {
  const SearchableDrinkRecord({
    required this.id,
    required this.venueId,
    required this.name,
    this.category = '',
    this.priceLabel = '',
    this.brand = '',
    this.ingredients = '',
    this.available = false,
    this.isDeleted = false,
    this.searchTerms = const [],
    this.searchKeywords = const [],
  });

  final String id;
  final String venueId;
  final String name;
  final String category;
  final String priceLabel;
  final String brand;
  final String ingredients;
  final bool available;
  final bool isDeleted;
  final List<String> searchTerms;
  final List<String> searchKeywords;
}

/// Firebase-independent deal row for unified discovery search.
final class SearchableDealRecord {
  const SearchableDealRecord({
    required this.id,
    required this.venueId,
    required this.title,
    this.description = '',
    this.category = '',
    this.isActive = false,
    this.isDeleted = false,
    this.searchTerms = const [],
    this.searchKeywords = const [],
  });

  final String id;
  final String venueId;
  final String title;
  final String description;
  final String category;
  final bool isActive;
  final bool isDeleted;
  final List<String> searchTerms;
  final List<String> searchKeywords;
}

/// Firebase-independent event row for unified discovery search.
final class SearchableEventRecord {
  const SearchableEventRecord({
    required this.id,
    required this.venueId,
    required this.title,
    this.description = '',
    this.category = '',
    this.isActive = true,
    this.isDeleted = false,
    this.startDateTime,
    this.endDateTime,
    this.searchTerms = const [],
    this.searchKeywords = const [],
  });

  final String id;
  final String venueId;
  final String title;
  final String description;
  final String category;
  final bool isActive;
  final bool isDeleted;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final List<String> searchTerms;
  final List<String> searchKeywords;
}

/// Firebase-independent trail row for unified discovery search.
final class SearchableTrailRecord {
  const SearchableTrailRecord({
    required this.id,
    required this.name,
    this.description = '',
    this.area = '',
    this.published = false,
    this.availabilityEnd,
    this.searchTerms = const [],
    this.venueIds = const [],
  });

  final String id;
  final String name;
  final String description;
  final String area;
  final bool published;
  final DateTime? availabilityEnd;
  final List<String> searchTerms;
  final List<String> venueIds;
}

/// Batch of searchable entity rows loaded by app adapters.
final class UnifiedSearchCandidateBatch {
  const UnifiedSearchCandidateBatch({
    this.drinks = const [],
    this.deals = const [],
    this.events = const [],
    this.trails = const [],
  });

  final List<SearchableDrinkRecord> drinks;
  final List<SearchableDealRecord> deals;
  final List<SearchableEventRecord> events;
  final List<SearchableTrailRecord> trails;

  static const empty = UnifiedSearchCandidateBatch();
}
