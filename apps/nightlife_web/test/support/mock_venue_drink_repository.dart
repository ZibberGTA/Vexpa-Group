import 'dart:async';

import 'package:vex_core/vex_core.dart';

final class MockVenueDrinkRepository implements VenueDrinkRepository {
  MockVenueDrinkRepository({
    this.publicDrinks = const [],
    this.loadError,
    Stream<DataResult<List<VenueDrink>>>? watchStream,
  }) : _watchStream = watchStream;

  List<VenueDrink> publicDrinks;
  VexException? loadError;
  final Stream<DataResult<List<VenueDrink>>>? _watchStream;

  int loadCalls = 0;
  int watchCalls = 0;
  String? lastVenueId;

  @override
  Future<DataResult<List<VenueDrink>>> loadPublicDrinks(String venueId) async {
    loadCalls++;
    lastVenueId = venueId;
    if (venueId.trim().isEmpty) {
      return const DataSuccess([]);
    }
    if (loadError != null) {
      return DataFailure(loadError!);
    }
    return DataSuccess(publicDrinks);
  }

  @override
  Stream<DataResult<List<VenueDrink>>> watchPublicDrinks(String venueId) {
    watchCalls++;
    lastVenueId = venueId;
    if (venueId.trim().isEmpty) {
      return Stream.value(const DataSuccess([]));
    }
    if (_watchStream != null) {
      return _watchStream;
    }
    return Stream.value(DataSuccess(publicDrinks));
  }
}

VenueDrink mockVenueDrink({
  required String id,
  required String name,
  String venueId = 'venue-1',
  String category = 'Cocktails',
  double price = 12,
  String description = '',
  bool available = true,
  bool featured = false,
  bool isDeleted = false,
}) {
  return VenueDrink(
    id: id,
    venueId: venueId,
    name: name,
    category: category,
    price: price,
    description: description,
    available: available,
    featured: featured,
    isDeleted: isDeleted,
  );
}
