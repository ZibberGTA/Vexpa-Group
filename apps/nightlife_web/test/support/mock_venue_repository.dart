import 'dart:async';

import 'package:vex_core/vex_core.dart';

final class MockVenueRepository implements VenueRepository {
  MockVenueRepository({
    this.publicVenues = const [],
    this.searchMatches = const {},
    this.venueById,
    this.loadError,
    this.searchError,
    this.findByIdError,
    this.watchError,
    Stream<DataResult<Venue?>>? watchStream,
  }) : _watchStream = watchStream;

  List<Venue> publicVenues;
  Set<String> searchMatches;
  Venue? venueById;
  VexException? loadError;
  VexException? searchError;
  VexException? findByIdError;
  VexException? watchError;
  final Stream<DataResult<Venue?>>? _watchStream;

  int loadCalls = 0;
  int searchCalls = 0;
  int findByIdCalls = 0;
  int watchByIdCalls = 0;
  List<String>? lastSearchTerms;
  String? lastFindById;
  String? lastWatchById;

  @override
  Future<DataResult<List<Venue>>> loadPublicVenues() async {
    loadCalls++;
    if (loadError != null) {
      return DataFailure(loadError!);
    }
    return DataSuccess(publicVenues);
  }

  @override
  Stream<DataResult<List<Venue>>> watchPublicVenues() {
    loadCalls++;
    if (loadError != null) {
      return Stream.value(DataFailure(loadError!));
    }
    return Stream.value(DataSuccess(publicVenues));
  }

  @override
  Stream<DataResult<List<Venue>>> watchVenuesForOwner(String ownerId) {
    loadCalls++;
    if (loadError != null) {
      return Stream.value(DataFailure(loadError!));
    }
    return Stream.value(DataSuccess(publicVenues));
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
    lastFindById = venueId;
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
    lastWatchById = venueId;
    if (venueId.trim().isEmpty) {
      return Stream.value(const DataSuccess(null));
    }
    if (_watchStream != null) {
      return _watchStream!;
    }
    if (watchError != null) {
      return Stream.value(DataFailure(watchError!));
    }
    return Stream.value(DataSuccess(venueById));
  }
}

Venue mockVenue({
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
