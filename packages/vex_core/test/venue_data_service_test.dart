import 'package:test/test.dart';
import 'package:vex_core/vex_core.dart';

final class MockVenueRepository implements VenueRepository {
  MockVenueRepository({
    this.publicVenues = const [],
    this.searchMatches = const {},
    this.loadError,
    this.searchError,
  });

  List<Venue> publicVenues;
  Set<String> searchMatches;
  VexException? loadError;
  VexException? searchError;

  int loadCalls = 0;
  int searchCalls = 0;
  List<String>? lastSearchTerms;

  @override
  Future<DataResult<List<Venue>>> loadPublicVenues() async {
    loadCalls++;
    if (loadError != null) {
      return DataFailure(loadError!);
    }
    return DataSuccess(publicVenues);
  }

  @override
  Future<DataResult<VenueSearchMatch>> searchPublicVenuesByTerms({
    required List<String> terms,
  }) async {
    searchCalls++;
    lastSearchTerms = terms;
    if (searchError != null) {
      return DataFailure(searchError!);
    }
    return DataSuccess(VenueSearchMatch(venueIds: searchMatches));
  }
}

Venue _venue({
  required String id,
  required String name,
  double? latitude,
  double? longitude,
}) {
  return Venue(
    id: id,
    name: name,
    address: '1 Test Street',
    area: 'Shoreditch',
    city: 'London',
    category: 'Bar',
    venueType: 'Cocktail Bar',
    crowdLevel: 'quiet',
    latitude: latitude,
    longitude: longitude,
  );
}

void main() {
  group('VenueRepository contract', () {
    test('mock repository records load and search calls', () async {
      final repository = MockVenueRepository(
        publicVenues: [_venue(id: 'v1', name: 'Alpha', latitude: 51.5, longitude: -0.1)],
        searchMatches: {'v1'},
      );

      final load = await repository.loadPublicVenues();
      final search = await repository.searchPublicVenuesByTerms(
        terms: const ['alpha'],
      );

      expect(load, isA<DataSuccess<List<Venue>>>());
      expect(search, isA<DataSuccess<VenueSearchMatch>>());
      expect(repository.loadCalls, 1);
      expect(repository.searchCalls, 1);
      expect(repository.lastSearchTerms, ['alpha']);
    });
  });

  group('VenueDataService.loadDiscoveryCatalog', () {
    test('sorts venues case-insensitively by name', () async {
      final service = VenueDataService(
        repository: MockVenueRepository(
          publicVenues: [
            _venue(id: '2', name: 'beta'),
            _venue(id: '1', name: 'Alpha'),
          ],
        ),
      );

      final result = await service.loadDiscoveryCatalog();
      expect(result, isA<DataSuccess<VenueCatalog>>());
      final catalog = (result as DataSuccess<VenueCatalog>).value;
      expect(catalog.venues.map((venue) => venue.name), ['Alpha', 'beta']);
    });

    test('returns repository failures unchanged', () async {
      final service = VenueDataService(
        repository: MockVenueRepository(
          loadError: const VexException('load failed', code: 'test'),
        ),
      );

      final result = await service.loadDiscoveryCatalog();
      expect(result, isA<DataFailure<VenueCatalog>>());
      expect((result as DataFailure<VenueCatalog>).error.code, 'test');
    });
  });

  group('VenueDataService.searchDiscoveryVenues', () {
    test('normalizes and deduplicates search terms', () async {
      final repository = MockVenueRepository(searchMatches: {'v1'});
      final service = VenueDataService(repository: repository);

      final result = await service.searchDiscoveryVenues(
        terms: const [' Alpha ', 'alpha', ''],
      );

      expect(result, isA<DataSuccess<VenueSearchMatch>>());
      expect(repository.lastSearchTerms, ['alpha']);
    });

    test('returns empty match for blank terms without repository call', () async {
      final repository = MockVenueRepository();
      final service = VenueDataService(repository: repository);

      final result = await service.searchDiscoveryVenues(terms: const ['', '  ']);

      expect(result, isA<DataSuccess<VenueSearchMatch>>());
      expect(
        (result as DataSuccess<VenueSearchMatch>).value.venueIds,
        isEmpty,
      );
      expect(repository.searchCalls, 0);
    });
  });
}
