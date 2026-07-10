import '../models/venue_search_result.dart';

/// Loaded venue catalog for the search page.
class SearchVenueCatalog {
  const SearchVenueCatalog({
    required this.venues,
    required this.usingFallback,
  });

  final List<VenueSearchResult> venues;
  final bool usingFallback;
}
