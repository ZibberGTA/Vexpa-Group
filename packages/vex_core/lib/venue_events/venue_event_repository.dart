import '../data/data_result.dart';
import 'venue_event.dart';

/// Provider-neutral contract for public venue event reads.
abstract interface class VenueEventRepository {
  Future<DataResult<List<VenueEvent>>> loadPublicEvents(String venueId);

  Stream<DataResult<List<VenueEvent>>> watchPublicEvents(String venueId);
}
