import '../domain/discovery_venue_catalog_entry.dart';
import '../shared/discovery_query_normalizer.dart';

/// Mobile-style venue list matching with match reasons and relevance sorting.
final class DiscoveryVenueClientMatcher {
  DiscoveryVenueClientMatcher._();

  static List<String> matchReasons({
    required DiscoveryVenueCatalogEntry venue,
    required String query,
  }) {
    final search = DiscoveryQueryNormalizer.normalize(query);
    if (search.isEmpty) return const [];

    final searchVariants = DiscoveryQueryNormalizer.expandAliases(search);
    final searchParts = DiscoveryQueryNormalizer.tokenize(search);

    return _getMatchReasons(venue, searchVariants, searchParts);
  }

  static List<T> filterWithReasons<T>({
    required List<T> items,
    required String query,
    required DiscoveryVenueCatalogEntry Function(T item) toEntry,
    required T Function(T item, List<String> reasons) withReasons,
  }) {
    final search = DiscoveryQueryNormalizer.normalize(query);
    if (search.isEmpty) return items;

    final searchVariants = DiscoveryQueryNormalizer.expandAliases(search);
    final searchParts = DiscoveryQueryNormalizer.tokenize(search);
    final matched = <T>[];

    for (final item in items) {
      final reasons = _getMatchReasons(toEntry(item), searchVariants, searchParts);
      if (reasons.isNotEmpty) {
        matched.add(withReasons(item, reasons));
      }
    }

    sortByMobileRelevance(
      items: matched,
      query: query,
      readName: (item) => toEntry(item).name,
    );

    return matched;
  }

  static void sortByMobileRelevance<T>({
    required List<T> items,
    required String query,
    required String Function(T item) readName,
  }) {
    items.sort((a, b) {
      final aExact = _isExactNameMatch(readName(a), query) ? 1 : 0;
      final bExact = _isExactNameMatch(readName(b), query) ? 1 : 0;
      if (aExact != bExact) return bExact.compareTo(aExact);

      final aStarts = _nameStartsWithQuery(readName(a), query) ? 1 : 0;
      final bStarts = _nameStartsWithQuery(readName(b), query) ? 1 : 0;
      if (aStarts != bStarts) return bStarts.compareTo(aStarts);

      return readName(a).toLowerCase().compareTo(readName(b).toLowerCase());
    });
  }

  static bool _isExactNameMatch(String venueName, String query) {
    final normalizedName = DiscoveryQueryNormalizer.normalize(venueName);
    final variants = DiscoveryQueryNormalizer.expandAliases(
      DiscoveryQueryNormalizer.normalize(query),
    );
    return variants.any((variant) => normalizedName == variant);
  }

  static bool _nameStartsWithQuery(String venueName, String query) {
    final normalizedName = DiscoveryQueryNormalizer.normalize(venueName);
    final variants = DiscoveryQueryNormalizer.expandAliases(
      DiscoveryQueryNormalizer.normalize(query),
    );
    return variants.any((variant) => normalizedName.startsWith(variant));
  }

  static List<String> _getMatchReasons(
    DiscoveryVenueCatalogEntry venue,
    List<String> searchVariants,
    List<String> searchParts,
  ) {
    final reasons = <String>{};

    final venueName = DiscoveryQueryNormalizer.normalize(venue.name);
    final category = DiscoveryQueryNormalizer.normalize(venue.category);
    final crowdLevel = DiscoveryQueryNormalizer.normalize(venue.crowdLevel);
    final address = DiscoveryQueryNormalizer.normalize(venue.address);

    if (DiscoveryQueryNormalizer.matchesAny(venueName, searchVariants)) {
      reasons.add('Venue name');
    }

    if (DiscoveryQueryNormalizer.matchesAny(category, searchVariants)) {
      reasons.add('Category');
    }

    if (DiscoveryQueryNormalizer.matchesAny(crowdLevel, searchVariants)) {
      reasons.add('Crowd level');
    }

    if (address.isNotEmpty &&
        DiscoveryQueryNormalizer.matchesAny(address, searchVariants)) {
      reasons.add('Address');
    }

    for (final term in venue.searchTerms) {
      final normalizedTerm = DiscoveryQueryNormalizer.normalize(term);

      final exactOrContains = DiscoveryQueryNormalizer.matchesAny(
        normalizedTerm,
        searchVariants,
      );
      final multiWordMatch =
          searchParts.isNotEmpty &&
          searchParts.every((part) => normalizedTerm.contains(part));

      if ((exactOrContains || multiWordMatch) &&
          !_isGenericFieldMatch(term, venue)) {
        reasons.add(term);
      }
    }

    return reasons.take(3).toList();
  }

  static bool _isGenericFieldMatch(
    String term,
    DiscoveryVenueCatalogEntry venue,
  ) {
    final normalizedTerm = DiscoveryQueryNormalizer.normalize(term);

    return normalizedTerm == DiscoveryQueryNormalizer.normalize(venue.name) ||
        normalizedTerm == DiscoveryQueryNormalizer.normalize(venue.category) ||
        normalizedTerm ==
            DiscoveryQueryNormalizer.normalize(venue.crowdLevel) ||
        normalizedTerm == DiscoveryQueryNormalizer.normalize(venue.address);
  }
}
