import 'package:test/test.dart';
import 'package:vex_core/vex_core.dart';

void main() {
  test('watchDiscoveryCatalog emits sorted catalog snapshots', () async {
    final repository = _WatchMockVenueRepository(
      publicVenues: [
        _venue(id: 'b', name: 'Beta Bar'),
        _venue(id: 'a', name: 'Alpha Bar'),
      ],
    );
    final service = VenueDataService(repository: repository);

    final result = await service.watchDiscoveryCatalog().first;

    expect(result, isA<DataSuccess<VenueCatalog>>());
    final catalog = (result as DataSuccess<VenueCatalog>).value;
    expect(catalog.venues.map((venue) => venue.name), ['Alpha Bar', 'Beta Bar']);
    expect(repository.watchCalls, 1);
  });
}

final class _WatchMockVenueRepository implements VenueRepository {
  _WatchMockVenueRepository({required this.publicVenues});

  final List<Venue> publicVenues;
  int watchCalls = 0;

  @override
  Future<DataResult<List<Venue>>> loadPublicVenues() async {
    return DataSuccess(publicVenues);
  }

  @override
  Stream<DataResult<List<Venue>>> watchPublicVenues() {
    watchCalls++;
    return Stream.value(DataSuccess(publicVenues));
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

  @override
  Stream<DataResult<List<Venue>>> watchVenuesForOwner(String ownerId) {
    watchCalls++;
    return Stream.value(DataSuccess(publicVenues));
  }
}

Venue _venue({required String id, required String name}) {
  return Venue(
    id: id,
    name: name,
    address: '1 Test Street',
    area: 'Shoreditch',
    city: 'London',
    category: 'Bar',
    venueType: 'Bar',
    crowdLevel: 'quiet',
  );
}
