import 'dart:async';

import 'package:test/test.dart';
import 'package:vex_core/vex_core.dart';

final class MockVenueDealRepository implements VenueDealRepository {
  MockVenueDealRepository({
    this.publicDeals = const [],
    this.loadError,
    Stream<DataResult<List<VenueDeal>>>? watchStream,
  }) : _watchStream = watchStream;

  List<VenueDeal> publicDeals;
  VexException? loadError;
  final Stream<DataResult<List<VenueDeal>>>? _watchStream;

  int loadCalls = 0;
  int watchCalls = 0;
  String? lastVenueId;

  @override
  Future<DataResult<List<VenueDeal>>> loadPublicDeals(String venueId) async {
    loadCalls++;
    lastVenueId = venueId;
    if (venueId.trim().isEmpty) {
      return const DataSuccess([]);
    }
    if (loadError != null) {
      return DataFailure(loadError!);
    }
    return DataSuccess(publicDeals);
  }

  @override
  Stream<DataResult<List<VenueDeal>>> watchPublicDeals(String venueId) {
    watchCalls++;
    lastVenueId = venueId;
    if (venueId.trim().isEmpty) {
      return Stream.value(const DataSuccess([]));
    }
    if (_watchStream != null) {
      return _watchStream;
    }
    return Stream.value(DataSuccess(publicDeals));
  }
}

VenueDeal _deal({
  required String id,
  required String title,
  String venueId = 'venue-1',
  DateTime? startDateTime,
  DateTime? endDateTime,
  bool isActive = true,
  bool featured = false,
  bool isDeleted = false,
}) {
  return VenueDeal(
    id: id,
    venueId: venueId,
    title: title,
    description: '',
    dealType: 'other',
    value: '10% off',
    startTime: '',
    endTime: '',
    startDateTime: startDateTime,
    endDateTime: endDateTime,
    isActive: isActive,
    featured: featured,
    isDeleted: isDeleted,
  );
}

void main() {
  group('VenueDeal visibility', () {
    test('current and upcoming deals are visible', () {
      final now = DateTime.now();
      final current = _deal(
        id: '1',
        title: 'Current',
        startDateTime: now.subtract(const Duration(days: 1)),
        endDateTime: now.add(const Duration(days: 1)),
      );
      final upcoming = _deal(
        id: '2',
        title: 'Upcoming',
        startDateTime: now.add(const Duration(days: 3)),
        endDateTime: now.add(const Duration(days: 10)),
      );

      expect(isPublicVisibleVenueDeal(current, now: now), isTrue);
      expect(isPublicVisibleVenueDeal(upcoming, now: now), isTrue);
    });

    test('paused and expired deals are hidden', () {
      final now = DateTime.now();
      final paused = _deal(
        id: '1',
        title: 'Paused',
        startDateTime: now.subtract(const Duration(days: 1)),
        endDateTime: now.add(const Duration(days: 1)),
        isActive: false,
      );
      final expired = _deal(
        id: '2',
        title: 'Expired',
        startDateTime: now.subtract(const Duration(days: 10)),
        endDateTime: now.subtract(const Duration(days: 1)),
      );

      expect(isPublicVisibleVenueDeal(paused, now: now), isFalse);
      expect(isPublicVisibleVenueDeal(expired, now: now), isFalse);
    });
  });

  group('VenueDealDataService.loadPublicDeals', () {
    test('valid venue returns deals sorted by start date', () async {
        final now = DateTime.now();
        final repository = MockVenueDealRepository(
          publicDeals: [
            _deal(
              id: '2',
              title: 'Upcoming',
              startDateTime: now.add(const Duration(days: 3)),
              endDateTime: now.add(const Duration(days: 10)),
            ),
            _deal(
              id: '1',
              title: 'Current',
              startDateTime: now.subtract(const Duration(days: 1)),
              endDateTime: now.add(const Duration(days: 1)),
            ),
            _deal(
              id: '3',
              title: 'Paused',
              startDateTime: now.subtract(const Duration(days: 1)),
              endDateTime: now.add(const Duration(days: 1)),
              isActive: false,
            ),
          ],
        );
        final service = VenueDealDataService(repository: repository);

        final result = await service.loadPublicDeals('venue-1');
        final deals = (result as DataSuccess<List<VenueDeal>>).value;

        expect(deals.map((deal) => deal.title), ['Current', 'Paused', 'Upcoming']);
        expect(repository.loadCalls, 1);
      },
    );

    test('no deals returns an empty list', () async {
      final service = VenueDealDataService(
        repository: MockVenueDealRepository(publicDeals: const []),
      );

      final result = await service.loadPublicDeals('venue-1');

      expect(result, isA<DataSuccess<List<VenueDeal>>>());
      expect((result as DataSuccess<List<VenueDeal>>).value, isEmpty);
    });

    test('empty venue ID does not call repository', () async {
      final repository = MockVenueDealRepository();
      final service = VenueDealDataService(repository: repository);

      final result = await service.loadPublicDeals('   ');

      expect(result, isA<DataSuccess<List<VenueDeal>>>());
      expect((result as DataSuccess<List<VenueDeal>>).value, isEmpty);
      expect(repository.loadCalls, 0);
    });

    test('repository failure is preserved', () async {
      final service = VenueDealDataService(
        repository: MockVenueDealRepository(
          loadError: const VexException('denied', code: 'permission-denied'),
        ),
      );

      final result = await service.loadPublicDeals('venue-1');

      expect(result, isA<DataFailure<List<VenueDeal>>>());
      expect((result as DataFailure).error.code, 'permission-denied');
    });
  });

  group('VenueDealDataService.watchPublicDeals', () {
    test('watch venue updates', () async {
      final now = DateTime.now();
      final controller = StreamController<DataResult<List<VenueDeal>>>();
      final service = VenueDealDataService(
        repository: MockVenueDealRepository(watchStream: controller.stream),
      );

      final results = <List<VenueDeal>>[];
      final subscription = service.watchPublicDeals('venue-1').listen((result) {
        if (result case DataSuccess(:final value)) {
          results.add(value);
        }
      });

      controller.add(
        DataSuccess([
          _deal(
            id: '1',
            title: 'Current',
            startDateTime: now.subtract(const Duration(days: 1)),
            endDateTime: now.add(const Duration(days: 1)),
          ),
        ]),
      );
      await Future<void>.delayed(Duration.zero);

      await subscription.cancel();
      await controller.close();

      expect(results.single.single.title, 'Current');
    });

    test('empty venue ID yields safe empty stream value', () async {
      final repository = MockVenueDealRepository();
      final service = VenueDealDataService(repository: repository);

      final result = await service.watchPublicDeals('  ').first;

      expect(result, isA<DataSuccess<List<VenueDeal>>>());
      expect((result as DataSuccess<List<VenueDeal>>).value, isEmpty);
      expect(repository.watchCalls, 0);
    });

    test('watch repository error is preserved', () async {
      final controller = StreamController<DataResult<List<VenueDeal>>>();
      final service = VenueDealDataService(
        repository: MockVenueDealRepository(watchStream: controller.stream),
      );

      final resultFuture = service.watchPublicDeals('venue-1').first;
      controller.add(
        DataFailure(const VexException('denied', code: 'permission-denied')),
      );

      final result = await resultFuture;
      expect(result, isA<DataFailure<List<VenueDeal>>>());
      await controller.close();
    });
  });
}
