import '../domain/discovery_venue_searchable.dart';
import '../shared/venue_search_matcher.dart';

/// Orchestrates venue text matching and index merge for discovery search.
final class DiscoveryVenueSearchService {
  const DiscoveryVenueSearchService();

  /// Merges local text matches with index hits and sorts by relevance.
  List<T> composeVenueMatches<T extends DiscoveryVenueMatchable>({
    required String query,
    required List<T> catalog,
    required Set<String> indexMatchedIds,
  }) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return List<T>.from(catalog);

    final matched = <T>[];
    final seenIds = <String>{};

    for (final venue in catalog) {
      if (seenIds.contains(venue.id)) continue;

      final textMatch = VenueSearchMatcher.matches(venue, trimmed);
      final indexMatch = indexMatchedIds.contains(venue.id);
      if (!textMatch && !indexMatch) continue;

      matched.add(venue);
      seenIds.add(venue.id);
    }

    VenueSearchMatcher.sortByRelevance(matched, trimmed);
    return matched;
  }

  List<String> termsFromQuery(String query) {
    return VenueSearchMatcher.termsFromQuery(query);
  }
}
