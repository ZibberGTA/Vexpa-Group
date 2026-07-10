import '../data/data_result.dart';
import 'venue_drink.dart';

/// Provider-neutral contract for public venue drink reads.
abstract interface class VenueDrinkRepository {
  Future<DataResult<List<VenueDrink>>> loadPublicDrinks(String venueId);

  Stream<DataResult<List<VenueDrink>>> watchPublicDrinks(String venueId);
}
