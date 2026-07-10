import '../domain/discovery_rankable_match.dart';
import '../domain/discovery_venue_searchable.dart';
import '../domain/search_filter_category.dart';
import '../domain/search_match_models.dart';
import 'search_ranking.dart';

/// Pure discovery response composition — ranking, filtering, and group counts.
final class DiscoveryUnifiedSearchComposer {
  const DiscoveryUnifiedSearchComposer();

  /// Builds the all-venues response for an empty query.
  List<T> composeAllVenueMatches<T extends DiscoveryVenueMatchable>({
    required List<T> catalog,
    required SearchFilterCategory category,
    required T Function(int catalogIndex, T venue) buildMatch,
  }) {
    final matches = <T>[];
    for (var index = 0; index < catalog.length; index++) {
      final venue = catalog[index];
      if (category == SearchFilterCategory.openNow && !venue.isOpen) {
        continue;
      }
      matches.add(buildMatch(index, venue));
    }
    return matches;
  }

  SearchGroupCounts countGroups(List<DiscoveryRankableMatch> matches) {
    var venueCount = 0;
    var drinkCount = 0;
    var dealCount = 0;
    var eventCount = 0;
    var trailCount = 0;

    for (final match in matches) {
      if (match.directVenueMatch) venueCount++;
      drinkCount += match.matchedDrinks.length;
      dealCount += match.matchedDeals.length;
      eventCount += match.matchedEvents.length;
      trailCount += match.matchedTrails.length;
    }

    return SearchGroupCounts(
      venues: venueCount,
      drinks: drinkCount,
      deals: dealCount,
      events: eventCount,
      trails: trailCount,
    );
  }

  /// Applies ranking, category filters, and group counts to unified matches.
  ({List<T> matches, SearchGroupCounts groupCounts})
  composeResponse<T extends DiscoveryRankableMatch>({
    required Iterable<T> groupedMatches,
    required String query,
    required SearchFilterCategory category,
    required T Function(T match, int rankScore) withRankScore,
  }) {
    final matches = groupedMatches.toList();

    for (var index = 0; index < matches.length; index++) {
      final match = matches[index];
      matches[index] = withRankScore(match, SearchRanking.score(match, query));
    }

    SearchRanking.sortMatches(matches, query);

    final filtered = matches.where((match) {
      if (category == SearchFilterCategory.openNow && !match.venue.isOpen) {
        return false;
      }
      return switch (category) {
        SearchFilterCategory.drinks => match.hasDrinkMatches,
        SearchFilterCategory.deals => match.hasDealMatches,
        SearchFilterCategory.events => match.hasEventMatches,
        SearchFilterCategory.trails => match.hasTrailMatches,
        SearchFilterCategory.openNow || SearchFilterCategory.venues =>
          match.directVenueMatch ||
              match.hasDrinkMatches ||
              match.hasDealMatches ||
              match.hasEventMatches ||
              match.hasTrailMatches,
      };
    }).toList();

    return (matches: filtered, groupCounts: countGroups(filtered));
  }
}
