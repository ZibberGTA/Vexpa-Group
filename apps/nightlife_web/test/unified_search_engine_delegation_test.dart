import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vex_core/discovery/searchable_content_records.dart';
import 'package:vex_core/vex_core.dart';
import 'package:vex_engines/discovery/application/discovery_unified_search_orchestrator.dart';

import 'package:nightlife_web/features/search/data/search_venue_filter.dart';
import 'package:nightlife_web/features/search/data/sources/unified_search_firestore_adapter.dart';
import 'package:nightlife_web/features/search/data/sources/venue_search_data_source.dart';
import 'package:nightlife_web/features/search/data/unified_search_service.dart';
import 'package:nightlife_web/features/search/data/web_search_venue_match_factory.dart';
import 'package:nightlife_web/features/search/models/venue_search_result.dart';

VenueSearchResult _venue({required String id, required String name}) {
  return VenueSearchResult(
    id: id,
    name: name,
    area: 'Shoreditch',
    city: 'London',
    venueType: 'Bar',
    rating: 4.5,
    tags: const ['Cocktails'],
    bannerGradient: const [Color(0xFF3D1054), Color(0xFFFF2D95)],
    logoGradient: const [Color(0xFF2A1538), Color(0xFFFF2D95)],
    resultReason: 'Open until late',
    isOpen: true,
    latitude: 51.52,
    longitude: -0.08,
  );
}

void main() {
  test('UnifiedSearchService delegates composition to Discovery Engine', () async {
    final service = UnifiedSearchService(
      venueSearchDataSource: VenueSearchDataSource(
        venueDataService: VenueDataService(repository: _EmptyIndexVenueRepository()),
      ),
      firestoreAdapter: _FakeFirestoreAdapter(),
      orchestrator: DiscoveryUnifiedSearchOrchestrator(),
      matchFactory: const WebSearchVenueMatchFactory(),
    );

    final response = await service.search(
      query: 'martini',
      catalog: [_venue(id: 'v1', name: 'Neon Room')],
      category: SearchFilterCategory.venues,
      usingFallback: false,
    );

    expect(response.matches, hasLength(1));
    expect(response.matches.first.matchedDrinks.first.name, 'Espresso Martini');
  });

  test('UnifiedSearchService keeps single entity adapter round-trip', () async {
    final adapter = _CountingFirestoreAdapter();
    final service = UnifiedSearchService(
      venueSearchDataSource: VenueSearchDataSource(
        venueDataService: VenueDataService(repository: _EmptyIndexVenueRepository()),
      ),
      firestoreAdapter: adapter,
    );

    await service.search(
      query: 'martini',
      catalog: [_venue(id: 'v1', name: 'Neon Room')],
      category: SearchFilterCategory.drinks,
      usingFallback: false,
    );

    expect(adapter.loadCalls, 1);
  });
}

class _FakeFirestoreAdapter extends UnifiedSearchFirestoreAdapter {
  @override
  Future<UnifiedSearchCandidateBatch> loadCandidates({
    required String cleanQuery,
    required bool includeDrinks,
    required bool includeDeals,
    required bool includeEvents,
    required bool includeTrails,
  }) async {
    return const UnifiedSearchCandidateBatch(
      drinks: [
        SearchableDrinkRecord(
          id: 'd1',
          venueId: 'v1',
          name: 'Espresso Martini',
          available: true,
        ),
      ],
    );
  }
}

class _CountingFirestoreAdapter extends UnifiedSearchFirestoreAdapter {
  int loadCalls = 0;

  @override
  Future<UnifiedSearchCandidateBatch> loadCandidates({
    required String cleanQuery,
    required bool includeDrinks,
    required bool includeDeals,
    required bool includeEvents,
    required bool includeTrails,
  }) async {
    loadCalls++;
    return UnifiedSearchCandidateBatch.empty;
  }
}

class _EmptyIndexVenueRepository implements VenueRepository {
  @override
  Future<DataResult<List<Venue>>> loadPublicVenues() async {
    return const DataSuccess([]);
  }

  @override
  Future<DataResult<VenueSearchMatch>> searchPublicVenuesByTerms({
    required List<String> terms,
  }) async {
    return const DataSuccess(VenueSearchMatch(venueIds: {}));
  }

  @override
  Future<DataResult<Venue?>> findById(String venueId) async {
    return const DataSuccess(null);
  }

  @override
  Stream<DataResult<Venue?>> watchById(String venueId) {
    return Stream.value(const DataSuccess(null));
  }
}
