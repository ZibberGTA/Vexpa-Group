import '../data/data_result.dart';
import 'venue_deal.dart';

/// Provider-neutral contract for public venue deal reads.
abstract interface class VenueDealRepository {
  Future<DataResult<List<VenueDeal>>> loadPublicDeals(String venueId);

  Stream<DataResult<List<VenueDeal>>> watchPublicDeals(String venueId);
}
