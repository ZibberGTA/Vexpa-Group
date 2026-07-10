import 'dart:async';

import 'package:test/test.dart';
import 'package:vex_core/vex_core.dart';

final class MockVenueRepository implements VenueRepository {
  MockVenueRepository({
    this.publicVenues = const [],
    this.searchMatches = const {},
    this.venueById,
    this.loadError,
    this.searchError,
    this.findByIdError,
    Stream<DataResult<Venue?>>? watchStream,
  }) : _watchStream = watchStream;

  List<Venue> publicVenues;
  Set<String> searchMatches;
  Venue? venueById;
  VexException? loadError;
  VexException? searchError;
  VexException? findByIdError;
  final Stream<DataResult<Venue?>>? _watchStream;

  int loadCalls = 0;
  int searchCalls = 0;
  int findByIdCalls = 0;
  int watchByIdCalls = 0;
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

  @override
  Future<DataResult<Venue?>> findById(String venueId) async {
    findByIdCalls++;
    if (venueId.trim().isEmpty) {
      return const DataSuccess(null);
    }
    if (findByIdError != null) {
      return DataFailure(findByIdError!);
    }
    return DataSuccess(venueById);
  }

  @override
  Stream<DataResult<Venue?>> watchById(String venueId) {
    watchByIdCalls++;
    if (venueId.trim().isEmpty) {
      return Stream.value(const DataSuccess(null));
    }
    if (_watchStream != null) {
      return _watchStream;
    }
    return Stream.value(DataSuccess(venueById));
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
        publicVenues: [
          _venue(id: 'v1', name: 'Alpha', latitude: 51.5, longitude: -0.1),
        ],
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

    test(
      'returns empty match for blank terms without repository call',
      () async {
        final repository = MockVenueRepository();
        final service = VenueDataService(repository: repository);

        final result = await service.searchDiscoveryVenues(
          terms: const ['', '  '],
        );

        expect(result, isA<DataSuccess<VenueSearchMatch>>());
        expect(
          (result as DataSuccess<VenueSearchMatch>).value.venueIds,
          isEmpty,
        );
        expect(repository.searchCalls, 0);
      },
    );
  });

  group('VenueDataService.loadPublicVenue', () {
    test('find existing venue', () async {
      final service = VenueDataService(
        repository: MockVenueRepository(
          venueById: _venue(id: 'venue-1', name: 'Neon Room'),
        ),
      );

      final result = await service.loadPublicVenue('venue-1');

      expect(result, isA<DataSuccess<Venue?>>());
      expect((result as DataSuccess<Venue?>).value?.name, 'Neon Room');
    });

    test('venue not found', () async {
      final service = VenueDataService(
        repository: MockVenueRepository(venueById: null),
      );

      final result = await service.loadPublicVenue('missing');

      expect(result, isA<DataSuccess<Venue?>>());
      expect((result as DataSuccess<Venue?>).value, isNull);
    });

    test('empty venue ID returns safe not-found result', () async {
      final repository = MockVenueRepository();
      final service = VenueDataService(repository: repository);

      final result = await service.loadPublicVenue('   ');

      expect(result, isA<DataSuccess<Venue?>>());
      expect((result as DataSuccess<Venue?>).value, isNull);
      expect(repository.findByIdCalls, 0);
    });

    test('repository failure', () async {
      final service = VenueDataService(
        repository: MockVenueRepository(
          findByIdError: const VexException(
            'denied',
            code: 'permission-denied',
          ),
        ),
      );

      final result = await service.loadPublicVenue('venue-1');

      expect(result, isA<DataFailure<Venue?>>());
      expect((result as DataFailure<Venue?>).error.code, 'permission-denied');
    });
  });

  group('VenueDataService.watchPublicVenue', () {
    test('watch venue updates', () async {
      final controller = StreamController<DataResult<Venue?>>();
      final service = VenueDataService(
        repository: MockVenueRepository(watchStream: controller.stream),
      );

      final values = <Venue?>[];
      final subscription = service.watchPublicVenue('venue-1').listen((result) {
        if (result case DataSuccess(:final value)) {
          values.add(value);
        }
      });

      controller.add(DataSuccess(_venue(id: 'venue-1', name: 'Alpha')));
      controller.add(DataSuccess(_venue(id: 'venue-1', name: 'Beta')));
      await Future<void>.delayed(Duration.zero);

      await subscription.cancel();
      await controller.close();

      expect(values.map((venue) => venue?.name), ['Alpha', 'Beta']);
    });

    test('watch venue not found', () async {
      final service = VenueDataService(
        repository: MockVenueRepository(venueById: null),
      );

      final result = await service.watchPublicVenue('missing').first;

      expect(result, isA<DataSuccess<Venue?>>());
      expect((result as DataSuccess<Venue?>).value, isNull);
    });

    test('watch repository error', () async {
      final controller = StreamController<DataResult<Venue?>>();
      final service = VenueDataService(
        repository: MockVenueRepository(watchStream: controller.stream),
      );

      final resultFuture = service.watchPublicVenue('venue-1').first;
      controller.add(
        DataFailure(
          const VexException('stream failed', code: 'venue-watch-failed'),
        ),
      );

      final result = await resultFuture;
      expect(result, isA<DataFailure<Venue?>>());
      await controller.close();
    });

    test('empty venue ID yields safe not-found stream value', () async {
      final repository = MockVenueRepository();
      final service = VenueDataService(repository: repository);

      final result = await service.watchPublicVenue('  ').first;

      expect(result, isA<DataSuccess<Venue?>>());
      expect((result as DataSuccess<Venue?>).value, isNull);
      expect(repository.watchByIdCalls, 0);
    });
  });
}
