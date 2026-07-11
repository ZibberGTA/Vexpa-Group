import '../data/data_result.dart';
import 'venue.dart';

/// Read-only venue data access for public discovery flows.
abstract interface class VenueRepository {
  Future<DataResult<List<Venue>>> loadPublicVenues();

  Stream<DataResult<List<Venue>>> watchPublicVenues();

  Future<DataResult<VenueSearchMatch>> searchPublicVenuesByTerms({
    required List<String> terms,
  });

  Future<DataResult<Venue?>> findById(String venueId);

  Stream<DataResult<Venue?>> watchById(String venueId);
}
