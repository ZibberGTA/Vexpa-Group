import '../data/data_result.dart';
import 'venue.dart';

/// Read-only venue data access for public discovery flows.
abstract interface class VenueRepository {
  Future<DataResult<List<Venue>>> loadPublicVenues();

  Future<DataResult<VenueSearchMatch>> searchPublicVenuesByTerms({
    required List<String> terms,
  });
}
