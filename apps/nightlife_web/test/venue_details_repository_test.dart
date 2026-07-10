import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/core/vexcore/firebase_venue_repository.dart';
import 'package:nightlife_web/features/venue/data/venue_details_repository.dart';
import 'package:nightlife_web/features/venue/models/venue_details_view.dart';
import 'package:vex_core/vex_core.dart';

import 'support/mock_venue_repository.dart';

void main() {
  group('FirebaseVenueRepository public venue mapping', () {
    test('one-time read maps a public venue document', () {
      final venue = FirebaseVenueRepository.mapVenueEntry('venue-1', {
        'name': 'Neon Room',
        'category': 'Cocktail Bar',
        'venueType': 'Cocktail Bar',
        'address': {
          'line1': '1 Brick Lane',
          'area': 'Shoreditch',
          'city': 'London',
        },
        'lat': 51.52,
        'lng': -0.08,
        'searchablePublic': true,
      });

      expect(venue, isNotNull);
      expect(venue!.id, 'venue-1');
      expect(venue.name, 'Neon Room');
    });

    test('hidden venue is not returned', () {
      final venue = FirebaseVenueRepository.mapVenueEntry('venue-1', {
        'name': 'Hidden Room',
        'category': 'Bar',
        'venueType': 'Bar',
        'isHidden': true,
        'searchablePublic': true,
      });

      expect(venue, isNull);
    });

    test('deleted venue is not returned', () {
      final venue = FirebaseVenueRepository.mapVenueEntry('venue-1', {
        'name': 'Deleted Room',
        'category': 'Bar',
        'venueType': 'Bar',
        'isDeleted': true,
      });

      expect(venue, isNull);
    });

    test('suspended venue is not returned', () {
      final venue = FirebaseVenueRepository.mapVenueEntry('venue-1', {
        'name': 'Suspended Room',
        'category': 'Bar',
        'venueType': 'Bar',
        'status': 'suspended',
      });

      expect(venue, isNull);
    });

    test('malformed venue data is denied safely', () {
      expect(FirebaseVenueRepository.mapVenueEntry('venue-1', null), isNull);
      expect(
        FirebaseVenueRepository.mapVenueEntry('venue-1', {
          'name': 'Unpublished Room',
          'category': 'Bar',
          'venueType': 'Bar',
          'searchablePublic': false,
        }),
        isNull,
      );
    });

    test('stream mapping removes venue when it becomes hidden', () {
      final visible = FirebaseVenueRepository.mapVenueEntry('venue-1', {
        'name': 'Visible Room',
        'category': 'Bar',
        'venueType': 'Bar',
        'searchablePublic': true,
      });
      final hidden = FirebaseVenueRepository.mapVenueEntry('venue-1', {
        'name': 'Visible Room',
        'category': 'Bar',
        'venueType': 'Bar',
        'searchablePublic': true,
        'isHidden': true,
      });

      expect(visible, isNotNull);
      expect(hidden, isNull);
    });
  });

  group('VenueDetailsRepository via VexCore', () {
    test('loads venue details through VenueDataService', () async {
      final mockRepository = MockVenueRepository(
        venueById: mockVenue(
          id: 'venue-1',
          name: 'Neon Room',
          latitude: 51.52,
          longitude: -0.08,
        ),
      );
      final repository = VenueDetailsRepository(
        venueDataService: VenueDataService(repository: mockRepository),
      );

      final view = await repository.loadVenue('venue-1');

      expect(mockRepository.findByIdCalls, 1);
      expect(mockRepository.lastFindById, 'venue-1');
      expect(view, isNotNull);
      expect(view!.name, 'Neon Room');
      expect(view.city, 'London');
    });

    test('returns null for missing venue', () async {
      final repository = VenueDetailsRepository(
        venueDataService: VenueDataService(
          repository: MockVenueRepository(venueById: null),
        ),
      );

      expect(await repository.loadVenue('missing'), isNull);
    });

    test('rethrows repository failures for error state parity', () async {
      final repository = VenueDetailsRepository(
        venueDataService: VenueDataService(
          repository: MockVenueRepository(
            findByIdError: const VexException(
              'denied',
              code: 'permission-denied',
            ),
          ),
        ),
      );

      expect(
        () => repository.loadVenue('venue-1'),
        throwsA(isA<VexException>()),
      );
    });

    test('watchVenue streams live updates through VexCore', () async {
      final controller = StreamController<DataResult<Venue?>>();
      final repository = VenueDetailsRepository(
        venueDataService: VenueDataService(
          repository: MockVenueRepository(watchStream: controller.stream),
        ),
      );

      final views = <VenueDetailsView?>[];
      final subscription = repository.watchVenue('venue-1').listen(views.add);

      controller.add(DataSuccess(mockVenue(id: 'venue-1', name: 'Alpha')));
      controller.add(DataSuccess(mockVenue(id: 'venue-1', name: 'Beta')));
      controller.add(const DataSuccess(null));
      await Future<void>.delayed(Duration.zero);

      await subscription.cancel();
      await controller.close();

      expect(views.map((view) => view?.name), ['Alpha', 'Beta', null]);
    });
  });
}
