import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vex_core/vex_core.dart';
import 'package:vex_engines/discovery/application/discovery_venue_search_service.dart';

import 'package:nightlife_web/features/search/data/search_repository.dart';
import 'package:nightlife_web/features/search/data/search_venue_catalog.dart';
import 'package:nightlife_web/features/search/data/search_venue_filter.dart';
import 'package:nightlife_web/features/search/data/search_venue_repository.dart';
import 'package:nightlife_web/features/search/data/sources/venue_search_data_source.dart';
import 'package:nightlife_web/features/search/data/unified_search_service.dart';
import 'package:nightlife_web/features/search/models/venue_search_result.dart';

VenueSearchResult _venue({
  required String id,
  required String name,
  bool isOpen = true,
}) {
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
    isOpen: isOpen,
    latitude: 51.52,
    longitude: -0.08,
  );
}

void main() {
  group('Discovery Engine web integration', () {
    test('VenueSearchDataSource delegates merge logic to Discovery Engine', () async {
      final countingRepository = _CountingVenueRepository();
      final dataSource = VenueSearchDataSource(
        venueDataService: VenueDataService(repository: countingRepository),
        discoverySearchService: const DiscoveryVenueSearchService(),
      );

      final catalog = [
        _venue(id: '1', name: 'Neon Room'),
        _venue(id: '2', name: 'Pulse Bar'),
      ];

      final results = await dataSource.search(query: 'neon', catalog: catalog);

      expect(results.map((venue) => venue.id).toList(), ['1']);
      expect(countingRepository.indexCalls, 1);
    });

    test('SearchRepository preserves fallback venue filtering', () async {
      final repository = SearchRepository(
        venueRepository: _FakeVenueRepository([
          _venue(id: '1', name: 'Neon Room'),
          _venue(id: '2', name: 'Pulse Bar'),
        ]),
        unifiedSearchService: UnifiedSearchService(
          venueSearchDataSource: VenueSearchDataSource(
            venueDataService: VenueDataService(
              repository: _EmptyIndexVenueRepository(),
            ),
          ),
        ),
      );

      await repository.loadCatalog();
      final response = await repository.search(
        query: 'neon',
        category: SearchFilterCategory.venues,
      );

      expect(response.catalogIndices, [0]);
    });

    test('does not duplicate index lookups for repeated venue searches', () async {
      final countingRepository = _CountingVenueRepository();
      final dataSource = VenueSearchDataSource(
        venueDataService: VenueDataService(repository: countingRepository),
      );
      final catalog = [_venue(id: '1', name: 'Neon Room')];

      await dataSource.search(query: 'neon', catalog: catalog);
      await dataSource.search(query: 'neon', catalog: catalog);

      expect(countingRepository.indexCalls, 2);
    });
  });
}

class _FakeVenueRepository extends SearchVenueRepository {
  _FakeVenueRepository(this.venues);

  final List<VenueSearchResult> venues;

  @override
  Future<SearchVenueCatalog> loadVenues() async {
    return SearchVenueCatalog(venues: venues, usingFallback: true);
  }
}

class _CountingVenueRepository implements VenueRepository {
  int indexCalls = 0;

  @override
  Future<DataResult<List<Venue>>> loadPublicVenues() async {
    return const DataSuccess([]);
  }

  @override
  Future<DataResult<VenueSearchMatch>> searchPublicVenuesByTerms({
    required List<String> terms,
  }) async {
    indexCalls++;
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
