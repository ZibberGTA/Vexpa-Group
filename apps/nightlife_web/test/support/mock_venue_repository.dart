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
