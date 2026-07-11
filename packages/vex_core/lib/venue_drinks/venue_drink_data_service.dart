import '../data/data_result.dart';
import 'venue_drink.dart';
import 'venue_drink_repository.dart';

/// Domain service for public venue drink reads.
final class VenueDrinkDataService {
  const VenueDrinkDataService({required VenueDrinkRepository repository})
    : _repository = repository;

  final VenueDrinkRepository _repository;

  Future<DataResult<List<VenueDrink>>> loadPublicDrinks(String venueId) async {
    final trimmedId = venueId.trim();
    if (trimmedId.isEmpty) {
      return const DataSuccess([]);
    }

    final result = await _repository.loadPublicDrinks(trimmedId);
    return switch (result) {
      DataSuccess(:final value) => DataSuccess(_publicDrinks(value)),
      DataFailure(:final error) => DataFailure(error),
    };
  }

  Stream<DataResult<List<VenueDrink>>> watchPublicDrinks(String venueId) {
    final trimmedId = venueId.trim();
    if (trimmedId.isEmpty) {
      return Stream.value(const DataSuccess([]));
    }

    return _repository.watchPublicDrinks(trimmedId).map((result) {
      return switch (result) {
        DataSuccess(:final value) => DataSuccess(_publicDrinks(value)),
        DataFailure(:final error) => DataFailure(error),
      };
    });
  }

  List<VenueDrink> _publicDrinks(List<VenueDrink> drinks) {
    final visible = drinks
        .where((drink) => !drink.isDeleted && drink.available)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return visible;
  }
}
