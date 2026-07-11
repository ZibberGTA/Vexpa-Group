import 'package:vex_core/discovery/searchable_content_records.dart';
import 'package:vex_engines/discovery/application/discovery_unified_search_orchestrator.dart';
import 'package:vex_engines/discovery/application/discovery_unified_search_query.dart';

import '../models/search_match_models.dart';
import '../models/venue_search_result.dart';
import 'search_venue_filter.dart';
import 'sources/unified_search_firestore_adapter.dart';
import 'sources/venue_search_data_source.dart';
import 'web_search_venue_match_factory.dart';

/// Unified search facade — Firestore adapters + Discovery Engine orchestration.
class UnifiedSearchService {
  UnifiedSearchService({
    VenueSearchDataSource? venueSearchDataSource,
    UnifiedSearchFirestoreAdapter? firestoreAdapter,
    DiscoveryUnifiedSearchOrchestrator? orchestrator,
    DiscoveryUnifiedSearchQuery? queryRules,
    WebSearchVenueMatchFactory? matchFactory,
  })  : _venueSearch = venueSearchDataSource ?? VenueSearchDataSource(),
        _firestoreAdapter = firestoreAdapter ?? UnifiedSearchFirestoreAdapter(),
        _orchestrator = orchestrator ?? DiscoveryUnifiedSearchOrchestrator(),
        _queryRules = queryRules ?? const DiscoveryUnifiedSearchQuery(),
        _matchFactory = matchFactory ?? const WebSearchVenueMatchFactory();

  final VenueSearchDataSource _venueSearch;
  final UnifiedSearchFirestoreAdapter _firestoreAdapter;
  final DiscoveryUnifiedSearchOrchestrator _orchestrator;
  final DiscoveryUnifiedSearchQuery _queryRules;
  final WebSearchVenueMatchFactory _matchFactory;

  Future<UnifiedSearchResponse> search({
    required String query,
    required List<VenueSearchResult> catalog,
    required SearchFilterCategory category,
    required bool usingFallback,
  }) async {
    final trimmed = query.trim();
    final catalogById = {
      for (var index = 0; index < catalog.length; index++)
        catalog[index].id: index,
    };

    final cleanQuery = _queryRules.normalise(trimmed);
    final includeVenues = _queryRules.shouldSearchVenues(category);
    final includeDrinks = !usingFallback && _queryRules.shouldSearchDrinks(category);
    final includeDeals = !usingFallback && _queryRules.shouldSearchDeals(category);
    final includeEvents = !usingFallback && _queryRules.shouldSearchEvents(category);
    final includeTrails = !usingFallback && _queryRules.shouldSearchTrails(category);

    final venueMatchesFuture = includeVenues
        ? _venueSearch.search(query: trimmed, catalog: catalog)
        : Future<List<VenueSearchResult>>.value(const []);

    final candidatesFuture = (!usingFallback &&
            (includeDrinks || includeDeals || includeEvents || includeTrails))
        ? _firestoreAdapter.loadCandidates(
            cleanQuery: cleanQuery,
            includeDrinks: includeDrinks,
            includeDeals: includeDeals,
            includeEvents: includeEvents,
            includeTrails: includeTrails,
          )
        : Future.value(UnifiedSearchCandidateBatch.empty);

    final results = await Future.wait([venueMatchesFuture, candidatesFuture]);
    final directVenueMatches = results[0] as List<VenueSearchResult>;
    final candidates = results[1] as UnifiedSearchCandidateBatch;

    final composed = _orchestrator.search(
      query: trimmed,
      category: category,
      catalog: catalog,
      catalogById: catalogById,
      usingFallback: usingFallback,
      matchFactory: _matchFactory,
      withRankScore: (match, rankScore) => match.copyWith(rankScore: rankScore),
      directVenueMatches: directVenueMatches,
      candidates: candidates,
    );

    return UnifiedSearchResponse(
      matches: composed.matches,
      groupCounts: composed.groupCounts,
    );
  }
}
