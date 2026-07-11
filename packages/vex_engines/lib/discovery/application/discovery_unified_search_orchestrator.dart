import 'package:vex_core/discovery/searchable_content_records.dart';

import '../domain/discovery_rankable_match.dart';
import '../domain/discovery_venue_searchable.dart';
import '../domain/search_filter_category.dart';
import '../domain/search_match_models.dart';
import 'discovery_unified_search_candidate_matcher.dart';
import 'discovery_unified_search_composer.dart';
import 'discovery_unified_search_merger.dart';
import 'discovery_unified_search_query.dart';
import 'search_ranking.dart';

/// Orchestrates unified discovery search from adapter-loaded candidates.
final class DiscoveryUnifiedSearchOrchestrator {
  DiscoveryUnifiedSearchOrchestrator({
    DiscoveryUnifiedSearchQuery? queryRules,
    DiscoveryUnifiedSearchCandidateMatcher? candidateMatcher,
    DiscoveryUnifiedSearchMerger? merger,
    DiscoveryUnifiedSearchComposer? composer,
  })  : _queryRules = queryRules ?? const DiscoveryUnifiedSearchQuery(),
        _candidateMatcher =
            candidateMatcher ?? const DiscoveryUnifiedSearchCandidateMatcher(),
        _merger = merger ?? const DiscoveryUnifiedSearchMerger(),
        _composer = composer ?? const DiscoveryUnifiedSearchComposer();

  final DiscoveryUnifiedSearchQuery _queryRules;
  final DiscoveryUnifiedSearchCandidateMatcher _candidateMatcher;
  final DiscoveryUnifiedSearchMerger _merger;
  final DiscoveryUnifiedSearchComposer _composer;

  ({List<T> matches, SearchGroupCounts groupCounts}) search<
      T extends DiscoveryRankableMatch, V extends DiscoveryVenueMatchable>({
    required String query,
    required SearchFilterCategory category,
    required List<V> catalog,
    required Map<String, int> catalogById,
    required bool usingFallback,
    required DiscoveryUnifiedSearchMatchFactory<T> matchFactory,
    required T Function(T match, int rankScore) withRankScore,
    List<V>? directVenueMatches,
    UnifiedSearchCandidateBatch candidates = UnifiedSearchCandidateBatch.empty,
    DateTime? now,
  }) {
    final trimmed = query.trim();

    if (_queryRules.isEmptyQuery(trimmed)) {
      final matches = <T>[];
      for (var index = 0; index < catalog.length; index++) {
        final venue = catalog[index];
        if (category == SearchFilterCategory.openNow && !venue.isOpen) {
          continue;
        }
        matches.add(
          matchFactory.buildBase(
            catalogIndex: index,
            venue: venue,
            directVenueMatch: true,
          ),
        );
      }
      return (
        matches: matches,
        groupCounts: SearchGroupCounts(venues: matches.length),
      );
    }

    if (usingFallback) {
      return _fallbackVenueSearch(
        query: trimmed,
        category: category,
        catalog: catalog,
        catalogById: catalogById,
        directVenueMatches: directVenueMatches ?? <V>[],
        matchFactory: matchFactory,
        withRankScore: withRankScore,
      );
    }

    final cleanQuery = _queryRules.normalise(trimmed);
    if (_queryRules.shouldReturnEmptyForShortQuery(
      cleanQuery: cleanQuery,
      category: category,
    )) {
      return (matches: <T>[], groupCounts: SearchGroupCounts());
    }

    var grouped = <String, T>{};

    if (_queryRules.shouldSearchVenues(category)) {
      grouped = _mergeDirectVenues(
        grouped: grouped,
        catalog: catalog,
        catalogById: catalogById,
        directVenueMatches: directVenueMatches ?? <V>[],
        matchFactory: matchFactory,
      );
    }

    if (_queryRules.shouldSearchDrinks(category)) {
      grouped = _mergeDrinks(
        grouped: grouped,
        catalog: catalog,
        catalogById: catalogById,
        cleanQuery: cleanQuery,
        drinks: candidates.drinks,
        matchFactory: matchFactory,
      );
    }

    if (_queryRules.shouldSearchDeals(category)) {
      grouped = _mergeDeals(
        grouped: grouped,
        catalog: catalog,
        catalogById: catalogById,
        cleanQuery: cleanQuery,
        deals: candidates.deals,
        matchFactory: matchFactory,
      );
    }

    if (_queryRules.shouldSearchEvents(category)) {
      grouped = _mergeEvents(
        grouped: grouped,
        catalog: catalog,
        catalogById: catalogById,
        cleanQuery: cleanQuery,
        events: candidates.events,
        matchFactory: matchFactory,
        now: now,
      );
    }

    if (_queryRules.shouldSearchTrails(category)) {
      grouped = _mergeTrails(
        grouped: grouped,
        catalog: catalog,
        catalogById: catalogById,
        cleanQuery: cleanQuery,
        trails: candidates.trails,
        matchFactory: matchFactory,
        now: now,
      );
    }

    final composed = _composer.composeResponse(
      groupedMatches: grouped.values,
      query: trimmed,
      category: category,
      withRankScore: withRankScore,
    );

    return (matches: composed.matches, groupCounts: composed.groupCounts);
  }

  Map<String, T> _mergeDirectVenues<T extends DiscoveryRankableMatch,
      V extends DiscoveryVenueMatchable>({
    required Map<String, T> grouped,
    required List<V> catalog,
    required Map<String, int> catalogById,
    required List<V> directVenueMatches,
    required DiscoveryUnifiedSearchMatchFactory<T> matchFactory,
  }) {
    var next = grouped;
    for (final venue in directVenueMatches) {
      final index = catalogById[venue.id];
      if (index == null) continue;
      final match = matchFactory.buildBase(
        catalogIndex: index,
        venue: venue,
        directVenueMatch: true,
      );
      next = _merger.upsertDirectVenue<T>(
        grouped: next,
        venueId: venue.id,
        match: match,
        factory: matchFactory,
      );
    }
    return next;
  }

  Map<String, T> _mergeDrinks<T extends DiscoveryRankableMatch,
      V extends DiscoveryVenueMatchable>({
    required Map<String, T> grouped,
    required List<V> catalog,
    required Map<String, int> catalogById,
    required String cleanQuery,
    required List<SearchableDrinkRecord> drinks,
    required DiscoveryUnifiedSearchMatchFactory<T> matchFactory,
  }) {
    var next = grouped;
    for (final drink in drinks) {
      if (!_candidateMatcher.matchesDrink(drink, cleanQuery)) continue;
      final catalogIndex = catalogById[drink.venueId];
      if (catalogIndex == null) continue;
      final matched = _candidateMatcher.toMatchedDrink(drink);
      if (matched == null) continue;

      next = _merger.upsertEntity<T>(
        grouped: next,
        venueId: drink.venueId,
        baseMatch: matchFactory.buildBase(
          catalogIndex: catalogIndex,
          venue: catalog[catalogIndex],
        ),
        drink: matched,
        factory: matchFactory,
      );
    }
    return next;
  }

  Map<String, T> _mergeDeals<T extends DiscoveryRankableMatch,
      V extends DiscoveryVenueMatchable>({
    required Map<String, T> grouped,
    required List<V> catalog,
    required Map<String, int> catalogById,
    required String cleanQuery,
    required List<SearchableDealRecord> deals,
    required DiscoveryUnifiedSearchMatchFactory<T> matchFactory,
  }) {
    var next = grouped;
    for (final deal in deals) {
      if (!_candidateMatcher.matchesDeal(deal, cleanQuery)) continue;
      final catalogIndex = catalogById[deal.venueId];
      if (catalogIndex == null) continue;
      final matched = _candidateMatcher.toMatchedDeal(deal);
      if (matched == null) continue;

      next = _merger.upsertEntity<T>(
        grouped: next,
        venueId: deal.venueId,
        baseMatch: matchFactory.buildBase(
          catalogIndex: catalogIndex,
          venue: catalog[catalogIndex],
        ),
        deal: matched,
        factory: matchFactory,
      );
    }
    return next;
  }

  Map<String, T> _mergeEvents<T extends DiscoveryRankableMatch,
      V extends DiscoveryVenueMatchable>({
    required Map<String, T> grouped,
    required List<V> catalog,
    required Map<String, int> catalogById,
    required String cleanQuery,
    required List<SearchableEventRecord> events,
    required DiscoveryUnifiedSearchMatchFactory<T> matchFactory,
    DateTime? now,
  }) {
    var next = grouped;
    for (final event in events) {
      if (!_candidateMatcher.matchesEvent(event, cleanQuery, now: now)) continue;
      final catalogIndex = catalogById[event.venueId];
      if (catalogIndex == null) continue;
      final matched = _candidateMatcher.toMatchedEvent(event);
      if (matched == null) continue;

      next = _merger.upsertEntity<T>(
        grouped: next,
        venueId: event.venueId,
        baseMatch: matchFactory.buildBase(
          catalogIndex: catalogIndex,
          venue: catalog[catalogIndex],
        ),
        event: matched,
        factory: matchFactory,
      );
    }
    return next;
  }

  Map<String, T> _mergeTrails<T extends DiscoveryRankableMatch,
      V extends DiscoveryVenueMatchable>({
    required Map<String, T> grouped,
    required List<V> catalog,
    required Map<String, int> catalogById,
    required String cleanQuery,
    required List<SearchableTrailRecord> trails,
    required DiscoveryUnifiedSearchMatchFactory<T> matchFactory,
    DateTime? now,
  }) {
    var next = grouped;
    for (final trail in trails) {
      if (!_candidateMatcher.matchesTrail(trail, cleanQuery, now: now)) continue;
      final matchedTrail = _candidateMatcher.toMatchedTrail(trail);
      if (matchedTrail == null) continue;

      for (final venueId in trail.venueIds) {
        final catalogIndex = catalogById[venueId];
        if (catalogIndex == null) continue;

        next = _merger.upsertEntity<T>(
          grouped: next,
          venueId: venueId,
          baseMatch: matchFactory.buildBase(
            catalogIndex: catalogIndex,
            venue: catalog[catalogIndex],
          ),
          trail: matchedTrail,
          factory: matchFactory,
        );
      }
    }
    return next;
  }

  ({List<T> matches, SearchGroupCounts groupCounts}) _fallbackVenueSearch<
      T extends DiscoveryRankableMatch, V extends DiscoveryVenueMatchable>({
    required String query,
    required SearchFilterCategory category,
    required List<V> catalog,
    required Map<String, int> catalogById,
    required List<V> directVenueMatches,
    required DiscoveryUnifiedSearchMatchFactory<T> matchFactory,
    required T Function(T match, int rankScore) withRankScore,
  }) {
    if (category != SearchFilterCategory.venues &&
        category != SearchFilterCategory.openNow) {
      return (matches: <T>[], groupCounts: SearchGroupCounts());
    }

    final matches = <T>[];
    for (final venue in directVenueMatches) {
      final index = catalogById[venue.id];
      if (index == null) continue;
      if (category == SearchFilterCategory.openNow && !venue.isOpen) continue;

      final base = matchFactory.buildBase(
        catalogIndex: index,
        venue: venue,
        directVenueMatch: true,
      );
      matches.add(
        withRankScore(base, SearchRanking.score(base, query)),
      );
    }

    SearchRanking.sortMatches(matches, query);
    return (
      matches: matches,
      groupCounts: SearchGroupCounts(venues: matches.length),
    );
  }
}
