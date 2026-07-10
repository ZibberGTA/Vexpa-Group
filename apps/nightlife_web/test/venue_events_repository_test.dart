import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/core/vexcore/firebase_venue_event_repository.dart';
import 'package:nightlife_web/core/vexcore/vex_venue_event_mapper.dart';
import 'package:nightlife_web/features/venue/data/public_venue_content_filters.dart';
import 'package:nightlife_web/features/venue/data/venue_events_repository.dart';
import 'package:vex_core/vex_core.dart';

import 'support/mock_venue_event_repository.dart';

void main() {
  final now = DateTime(2026, 7, 1, 12);

  group('FirebaseVenueEventRepository public event mapping', () {
    test('maps valid event documents', () {
      final event = FirebaseVenueEventRepository.mapEventEntry('event-1', {
        'venueId': 'venue-1',
        'title': 'Live Night',
        'description': 'DJ set all night',
        'startDateTime': now.toIso8601String(),
        'endDateTime': now.add(const Duration(hours: 4)).toIso8601String(),
        'category': 'Music',
        'imageUrl': 'https://example.com/event.jpg',
        'artist': 'DJ Example',
        'isActive': true,
        'featured': true,
        'isDeleted': false,
      });

      expect(event, isNotNull);
      expect(event!.id, 'event-1');
      expect(event.title, 'Live Night');
      expect(event.featured, isTrue);
      expect(event.imageUrl, 'https://example.com/event.jpg');
      expect(event.artist, 'DJ Example');
    });

    test('maps legacy dateTime and artistName fields', () {
      final event = FirebaseVenueEventRepository.mapEventEntry('event-1', {
        'venueId': 'venue-1',
        'title': 'Legacy Event',
        'dateTime': now.toIso8601String(),
        'artistName': 'Legacy Artist',
        'isActive': true,
      });

      expect(event, isNotNull);
      expect(event!.startDateTime, now);
      expect(event.endDateTime, now.add(const Duration(hours: 4)));
      expect(event.artist, 'Legacy Artist');
    });

    test('malformed event is denied safely', () {
      expect(
        FirebaseVenueEventRepository.mapEventEntry('event-1', null),
        isNull,
      );
    });

    test('preserves start-date ordering behaviour', () {
      final events =
          FirebaseVenueEventRepository.mapEventData([
                MapEntry('2', {
                  'venueId': 'venue-1',
                  'title': 'Upcoming Event',
                  'startDateTime': now
                      .add(const Duration(days: 3))
                      .toIso8601String(),
                  'endDateTime': now
                      .add(const Duration(days: 3, hours: 4))
                      .toIso8601String(),
                  'isActive': true,
                }),
                MapEntry('1', {
                  'venueId': 'venue-1',
                  'title': 'Current Event',
                  'startDateTime': now
                      .subtract(const Duration(hours: 1))
                      .toIso8601String(),
                  'endDateTime': now
                      .add(const Duration(hours: 3))
                      .toIso8601String(),
                  'isActive': true,
                }),
              ])
              .map(eventModelFromVexVenueEvent)
              .where((event) => isPublicVisibleEvent(event, now: now))
              .toList()
            ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

      expect(events.map((event) => event.title), [
        'Current Event',
        'Upcoming Event',
      ]);
    });
  });

  group('VenueEventsRepository via VexCore', () {
    test('watchEvents streams events through VenueEventDataService', () async {
      final clock = DateTime.now();
      final repository = VenueEventsRepository(
        venueEventDataService: VenueEventDataService(
          repository: MockVenueEventRepository(
            publicEvents: [
              mockVenueEvent(
                id: '1',
                title: 'Current',
                startDateTime: clock.subtract(const Duration(hours: 1)),
                endDateTime: clock.add(const Duration(hours: 3)),
              ),
            ],
          ),
        ),
      );

      final events = await repository.watchEvents('venue-1').first;

      expect(events.single.title, 'Current');
    });

    test('returns empty list for blank venue ID', () async {
      final repository = VenueEventsRepository(
        venueEventDataService: VenueEventDataService(
          repository: MockVenueEventRepository(),
        ),
      );

      expect(await repository.watchEvents('  ').first, isEmpty);
    });

    test('rethrows repository failures for error state parity', () async {
      final repository = VenueEventsRepository(
        venueEventDataService: VenueEventDataService(
          repository: MockVenueEventRepository(
            watchStream: Stream.value(
              DataFailure(
                const VexException('denied', code: 'permission-denied'),
              ),
            ),
          ),
        ),
      );

      expect(
        () => repository.watchEvents('venue-1').first,
        throwsA(isA<VexException>()),
      );
    });
  });
}
