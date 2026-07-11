import 'dart:async';

import 'package:test/test.dart';
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

VenueDrink _drink({
  required String id,
  required String name,
  String venueId = 'venue-1',
  String category = 'Cocktails',
  double price = 12,
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
    description: '',
    available: available,
    featured: featured,
    isDeleted: isDeleted,
  );
}

void main() {
  group('VenueDrinkDataService.loadPublicDrinks', () {
    test('valid venue returns drinks sorted by name', () async {
      final repository = MockVenueDrinkRepository(
        publicDrinks: [
          _drink(id: '2', name: 'Zeta'),
          _drink(id: '1', name: 'Alpha'),
        ],
      );
      final service = VenueDrinkDataService(repository: repository);

      final result = await service.loadPublicDrinks('venue-1');

      expect(result, isA<DataSuccess<List<VenueDrink>>>());
      final drinks = (result as DataSuccess<List<VenueDrink>>).value;
      expect(drinks.map((drink) => drink.name), ['Alpha', 'Zeta']);
      expect(repository.loadCalls, 1);
      expect(repository.lastVenueId, 'venue-1');
    });

    test('no drinks returns an empty list', () async {
      final service = VenueDrinkDataService(
        repository: MockVenueDrinkRepository(publicDrinks: const []),
      );

      final result = await service.loadPublicDrinks('venue-1');

      expect(result, isA<DataSuccess<List<VenueDrink>>>());
      expect((result as DataSuccess<List<VenueDrink>>).value, isEmpty);
    });

    test('empty venue ID does not call repository', () async {
      final repository = MockVenueDrinkRepository();
      final service = VenueDrinkDataService(repository: repository);

      final result = await service.loadPublicDrinks('   ');

      expect(result, isA<DataSuccess<List<VenueDrink>>>());
      expect((result as DataSuccess<List<VenueDrink>>).value, isEmpty);
      expect(repository.loadCalls, 0);
    });

    test('repository failure is preserved', () async {
      final service = VenueDrinkDataService(
        repository: MockVenueDrinkRepository(
          loadError: const VexException('denied', code: 'permission-denied'),
        ),
      );

      final result = await service.loadPublicDrinks('venue-1');

      expect(result, isA<DataFailure<List<VenueDrink>>>());
      expect((result as DataFailure).error.code, 'permission-denied');
    });

    test('filters deleted and unavailable drinks and sorts case-insensitively', () async {
      final service = VenueDrinkDataService(
        repository: MockVenueDrinkRepository(
          publicDrinks: [
            _drink(id: '1', name: 'bravo'),
            _drink(id: '2', name: 'Alpha', isDeleted: true),
            _drink(id: '3', name: 'alpha'),
            _drink(id: '4', name: 'Hidden', available: false),
          ],
        ),
      );

      final result = await service.loadPublicDrinks('venue-1');
      final drinks = (result as DataSuccess<List<VenueDrink>>).value;

      expect(drinks.map((drink) => drink.name), ['alpha', 'bravo']);
    });
  });

  group('VenueDrinkDataService.watchPublicDrinks', () {
    test('watch venue updates', () async {
      final controller = StreamController<DataResult<List<VenueDrink>>>();
      final service = VenueDrinkDataService(
        repository: MockVenueDrinkRepository(watchStream: controller.stream),
      );

      final results = <List<VenueDrink>>[];
      final subscription = service.watchPublicDrinks('venue-1').listen((
        result,
      ) {
        if (result case DataSuccess(:final value)) {
          results.add(value);
        }
      });

      controller.add(DataSuccess([_drink(id: '1', name: 'Alpha')]));
      controller.add(
        DataSuccess([
          _drink(id: '1', name: 'Alpha'),
          _drink(id: '2', name: 'Beta'),
        ]),
      );
      await Future<void>.delayed(Duration.zero);

      await subscription.cancel();
      await controller.close();

      expect(results.length, 2);
      expect(results.last.map((drink) => drink.name), ['Alpha', 'Beta']);
    });

    test('empty venue ID yields safe empty stream value', () async {
      final repository = MockVenueDrinkRepository();
      final service = VenueDrinkDataService(repository: repository);

      final result = await service.watchPublicDrinks('  ').first;

      expect(result, isA<DataSuccess<List<VenueDrink>>>());
      expect((result as DataSuccess<List<VenueDrink>>).value, isEmpty);
      expect(repository.watchCalls, 0);
    });

    test('watch repository error is preserved', () async {
      final controller = StreamController<DataResult<List<VenueDrink>>>();
      final service = VenueDrinkDataService(
        repository: MockVenueDrinkRepository(watchStream: controller.stream),
      );

      final resultFuture = service.watchPublicDrinks('venue-1').first;
      controller.add(
        DataFailure(const VexException('denied', code: 'permission-denied')),
      );

      final result = await resultFuture;
      expect(result, isA<DataFailure<List<VenueDrink>>>());
      await controller.close();
    });
  });
}
