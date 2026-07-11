import 'dart:async';

import 'package:test/test.dart';
import 'package:vex_core/vex_core.dart';

final class MockVenueEventRepository implements VenueEventRepository {
  MockVenueEventRepository({
    this.publicEvents = const [],
    this.loadError,
    Stream<DataResult<List<VenueEvent>>>? watchStream,
  }) : _watchStream = watchStream;

  List<VenueEvent> publicEvents;
  VexException? loadError;
  final Stream<DataResult<List<VenueEvent>>>? _watchStream;

  int loadCalls = 0;
  int watchCalls = 0;
  String? lastVenueId;

  @override
  Future<DataResult<List<VenueEvent>>> loadPublicEvents(String venueId) async {
    loadCalls++;
    lastVenueId = venueId;
    if (venueId.trim().isEmpty) {
      return const DataSuccess([]);
    }
    if (loadError != null) {
      return DataFailure(loadError!);
    }
    return DataSuccess(publicEvents);
  }

  @override
  Stream<DataResult<List<VenueEvent>>> watchPublicEvents(String venueId) {
    watchCalls++;
    lastVenueId = venueId;
    if (venueId.trim().isEmpty) {
      return Stream.value(const DataSuccess([]));
    }
    if (_watchStream != null) {
      return _watchStream;
    }
    return Stream.value(DataSuccess(publicEvents));
  }
}

VenueEvent _event({
  required String id,
  required String title,
  String venueId = 'venue-1',
  DateTime? startDateTime,
  DateTime? endDateTime,
  bool isActive = true,
  bool featured = false,
  bool isDeleted = false,
}) {
  final start = startDateTime ?? DateTime.now();
  final end = endDateTime ?? start.add(const Duration(hours: 4));
  return VenueEvent(
    id: id,
    venueId: venueId,
    title: title,
    description: '',
    startDateTime: start,
    endDateTime: end,
    category: 'General',
    imageUrl: '',
    artist: '',
    isActive: isActive,
    featured: featured,
    isDeleted: isDeleted,
  );
}

void main() {
  group('VenueEvent visibility', () {
    test('current and upcoming events are visible', () {
      final now = DateTime.now();
      final current = _event(
        id: '1',
        title: 'Current',
        startDateTime: now.subtract(const Duration(hours: 1)),
        endDateTime: now.add(const Duration(hours: 3)),
      );
      final upcoming = _event(
        id: '2',
        title: 'Upcoming',
        startDateTime: now.add(const Duration(days: 3)),
        endDateTime: now.add(const Duration(days: 3, hours: 4)),
      );

      expect(isPublicVisibleVenueEvent(current, now: now), isTrue);
      expect(isPublicVisibleVenueEvent(upcoming, now: now), isTrue);
    });

    test('draft and expired events are hidden', () {
      final now = DateTime.now();
      final draft = _event(
        id: '1',
        title: 'Draft',
        startDateTime: now.add(const Duration(days: 3)),
        endDateTime: now.add(const Duration(days: 3, hours: 4)),
        isActive: false,
      );
      final expired = _event(
        id: '2',
        title: 'Expired',
        startDateTime: now.subtract(const Duration(days: 2)),
        endDateTime: now.subtract(const Duration(hours: 1)),
      );

      expect(isPublicVisibleVenueEvent(draft, now: now), isFalse);
      expect(isPublicVisibleVenueEvent(expired, now: now), isFalse);
    });
  });

  group('VenueEventDataService.loadPublicEvents', () {
    test('valid venue returns events sorted by start date', () async {
      final now = DateTime.now();
      final repository = MockVenueEventRepository(
        publicEvents: [
          _event(
            id: '2',
            title: 'Upcoming',
            startDateTime: now.add(const Duration(days: 3)),
            endDateTime: now.add(const Duration(days: 3, hours: 4)),
          ),
          _event(
            id: '1',
            title: 'Current',
            startDateTime: now.subtract(const Duration(hours: 1)),
            endDateTime: now.add(const Duration(hours: 3)),
          ),
          _event(
            id: '3',
            title: 'Draft',
            startDateTime: now.add(const Duration(days: 3)),
            endDateTime: now.add(const Duration(days: 3, hours: 4)),
            isActive: false,
          ),
        ],
      );
      final service = VenueEventDataService(repository: repository);

      final result = await service.loadPublicEvents('venue-1');
      final events = (result as DataSuccess<List<VenueEvent>>).value;

      expect(events.first.title, 'Current');
      expect(events.map((event) => event.title), containsAll(['Upcoming', 'Draft']));
      expect(events.length, 3);
      expect(repository.loadCalls, 1);
    });

    test('no events returns an empty list', () async {
      final service = VenueEventDataService(
        repository: MockVenueEventRepository(publicEvents: const []),
      );

      final result = await service.loadPublicEvents('venue-1');

      expect(result, isA<DataSuccess<List<VenueEvent>>>());
      expect((result as DataSuccess<List<VenueEvent>>).value, isEmpty);
    });

    test('empty venue ID does not call repository', () async {
      final repository = MockVenueEventRepository();
      final service = VenueEventDataService(repository: repository);

      final result = await service.loadPublicEvents('   ');

      expect(result, isA<DataSuccess<List<VenueEvent>>>());
      expect((result as DataSuccess<List<VenueEvent>>).value, isEmpty);
      expect(repository.loadCalls, 0);
    });

    test('repository failure is preserved', () async {
      final service = VenueEventDataService(
        repository: MockVenueEventRepository(
          loadError: const VexException('denied', code: 'permission-denied'),
        ),
      );

      final result = await service.loadPublicEvents('venue-1');

      expect(result, isA<DataFailure<List<VenueEvent>>>());
      expect((result as DataFailure).error.code, 'permission-denied');
    });
  });

  group('VenueEventDataService.watchPublicEvents', () {
    test('watch venue updates', () async {
      final now = DateTime.now();
      final controller = StreamController<DataResult<List<VenueEvent>>>();
      final service = VenueEventDataService(
        repository: MockVenueEventRepository(watchStream: controller.stream),
      );

      final results = <List<VenueEvent>>[];
      final subscription = service.watchPublicEvents('venue-1').listen((
        result,
      ) {
        if (result case DataSuccess(:final value)) {
          results.add(value);
        }
      });

      controller.add(
        DataSuccess([
          _event(
            id: '1',
            title: 'Current',
            startDateTime: now.subtract(const Duration(hours: 1)),
            endDateTime: now.add(const Duration(hours: 3)),
          ),
        ]),
      );
      await Future<void>.delayed(Duration.zero);

      await subscription.cancel();
      await controller.close();

      expect(results.single.single.title, 'Current');
    });

    test('empty venue ID yields safe empty stream value', () async {
      final repository = MockVenueEventRepository();
      final service = VenueEventDataService(repository: repository);

      final result = await service.watchPublicEvents('  ').first;

      expect(result, isA<DataSuccess<List<VenueEvent>>>());
      expect((result as DataSuccess<List<VenueEvent>>).value, isEmpty);
      expect(repository.watchCalls, 0);
    });

    test('watch repository error is preserved', () async {
      final controller = StreamController<DataResult<List<VenueEvent>>>();
      final service = VenueEventDataService(
        repository: MockVenueEventRepository(watchStream: controller.stream),
      );

      final resultFuture = service.watchPublicEvents('venue-1').first;
      controller.add(
        DataFailure(const VexException('denied', code: 'permission-denied')),
      );

      final result = await resultFuture;
      expect(result, isA<DataFailure<List<VenueEvent>>>());
      await controller.close();
    });
  });
}
