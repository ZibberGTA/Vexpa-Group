import '../models/venue_search_result.dart';
import 'search_venue_filter.dart';

/// Case-insensitive venue text matching for Firestore-backed search.
class VenueSearchMatcher {
  VenueSearchMatcher._();

  static bool matches(VenueSearchResult venue, String query) {
    final normalized = _normalize(query);
    if (normalized.isEmpty) return true;

    final variants = _expandAliases(normalized);

    if (_matchesAny(_normalize(venue.name), variants)) return true;
    if (_matchesAny(_normalize(venue.city), variants)) return true;
    if (_matchesAny(_normalize(venue.area), variants)) return true;
    if (_matchesAny(_normalize(venue.postcode), variants)) return true;
    if (_matchesAny(_normalize(venue.venueType), variants)) return true;

    for (final tag in venue.tags) {
      if (_matchesAny(_normalize(tag), variants)) return true;
    }

    return false;
  }

  static bool _matchesAny(String value, List<String> variants) {
    if (value.isEmpty) return false;
    for (final variant in variants) {
      if (value == variant || value.contains(variant)) {
        return true;
      }
    }
    return false;
  }

  static String _normalize(String input) => input.toLowerCase().trim();

  static List<String> _expandAliases(String input) {
    final variants = <String>{input};
    if (input == 'whisky') {
      variants.add('whiskey');
    } else if (input == 'whiskey') {
      variants.add('whisky');
    }
    return variants.toList();
  }

  static int compareRelevance(VenueSearchResult venue, String query) {
    final normalized = _normalize(query);
    if (normalized.isEmpty) return 0;

    final name = _normalize(venue.name);
    final variants = _expandAliases(normalized);

    if (variants.any((variant) => name == variant)) return 0;
    if (variants.any((variant) => name.startsWith(variant))) return 1;
    if (variants.any((variant) => name.contains(variant))) return 2;
    return 3;
  }

  static void sortByRelevance(List<VenueSearchResult> venues, String query) {
    venues.sort((a, b) {
      final rank = compareRelevance(a, query).compareTo(
        compareRelevance(b, query),
      );
      if (rank != 0) return rank;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

  static List<String> termsFromQuery(String query) {
    return query
        .trim()
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((term) => term.isNotEmpty)
        .take(10)
        .toList();
  }

  static bool supportsCategory(SearchFilterCategory category) {
    return category == SearchFilterCategory.venues ||
        category == SearchFilterCategory.openNow;
  }
}
