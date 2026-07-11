import '../domain/discovery_venue_searchable.dart';
import '../domain/search_filter_category.dart';
import 'discovery_query_normalizer.dart';
import 'search_text_utils.dart';

/// Case-insensitive venue text matching for discovery search.
class VenueSearchMatcher {
  VenueSearchMatcher._();

  static bool matches(DiscoveryVenueSearchable venue, String query) {
    final normalized = DiscoveryQueryNormalizer.normalize(query);
    if (normalized.isEmpty) return true;

    final variants = DiscoveryQueryNormalizer.expandAliases(normalized);

    if (DiscoveryQueryNormalizer.matchesAny(
      DiscoveryQueryNormalizer.normalize(venue.name),
      variants,
    )) {
      return true;
    }
    if (DiscoveryQueryNormalizer.matchesAny(
      DiscoveryQueryNormalizer.normalize(venue.city),
      variants,
    )) {
      return true;
    }
    if (DiscoveryQueryNormalizer.matchesAny(
      DiscoveryQueryNormalizer.normalize(venue.area),
      variants,
    )) {
      return true;
    }
    if (DiscoveryQueryNormalizer.matchesAny(
      DiscoveryQueryNormalizer.normalize(venue.postcode),
      variants,
    )) {
      return true;
    }
    if (DiscoveryQueryNormalizer.matchesAny(
      DiscoveryQueryNormalizer.normalize(venue.venueType),
      variants,
    )) {
      return true;
    }

    for (final tag in venue.tags) {
      if (DiscoveryQueryNormalizer.matchesAny(
        DiscoveryQueryNormalizer.normalize(tag),
        variants,
      )) {
        return true;
      }
    }

    return false;
  }

  static int compareRelevance(DiscoveryVenueSearchable venue, String query) {
    final normalized = DiscoveryQueryNormalizer.normalize(query);
    if (normalized.isEmpty) return 0;

    final name = DiscoveryQueryNormalizer.normalize(venue.name);
    final variants = DiscoveryQueryNormalizer.expandAliases(normalized);

    if (variants.any((variant) => name == variant)) return 0;
    if (variants.any((variant) => name.startsWith(variant))) return 1;
    if (variants.any((variant) => name.contains(variant))) return 2;
    return 3;
  }

  static void sortByRelevance<T extends DiscoveryVenueSearchable>(
    List<T> venues,
    String query,
  ) {
    venues.sort((a, b) {
      final rank = compareRelevance(
        a,
        query,
      ).compareTo(compareRelevance(b, query));
      if (rank != 0) return rank;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

  static List<String> termsFromQuery(String query) =>
      SearchTextUtils.termsFromQuery(query);

  static bool supportsCategory(SearchFilterCategory category) {
    return category == SearchFilterCategory.venues ||
        category == SearchFilterCategory.openNow;
  }
}
