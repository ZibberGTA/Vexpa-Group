import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/core/vexcore/firebase_venue_repository.dart';

void main() {
  group('FirebaseVenueRepository public venue visibility', () {
    test('includes venue when searchablePublic is true', () {
      final data = {
        'isDeleted': false,
        'searchablePublic': true,
        'status': 'active',
        'name': 'Visible Pub',
        'category': 'Bar',
        'venueType': 'Bar',
        'address': {'city': 'London'},
        'lat': 51.5,
        'lng': -0.1,
      };

      expect(FirebaseVenueRepository.isPublicVenueData(data), isTrue);
      expect(
        FirebaseVenueRepository.mapVenueEntry('visible-1', data),
        isNotNull,
      );
    });

    test('includes venue when searchablePublic is missing (legacy public)', () {
      final data = {
        'isDeleted': false,
        'status': 'active',
        'name': 'Legacy Pub',
        'category': 'Bar',
        'venueType': 'Bar',
        'address': {'city': 'London'},
        'lat': 51.5,
        'lng': -0.1,
      };

      expect(FirebaseVenueRepository.isPublicVenueData(data), isTrue);
      expect(
        FirebaseVenueRepository.mapVenueEntry('legacy-1', data),
        isNotNull,
      );
    });

    test('excludes venue when searchablePublic is false', () {
      final data = {
        'isDeleted': false,
        'searchablePublic': false,
        'status': 'active',
        'name': 'Hidden Pub',
        'category': 'Bar',
        'venueType': 'Bar',
        'address': {'city': 'London'},
        'lat': 51.5,
        'lng': -0.1,
      };

      expect(FirebaseVenueRepository.isPublicVenueData(data), isFalse);
      expect(FirebaseVenueRepository.mapVenueEntry('hidden-1', data), isNull);
    });

    test('excludes deleted venues', () {
      final data = {
        'isDeleted': true,
        'searchablePublic': true,
        'status': 'active',
      };

      expect(FirebaseVenueRepository.isPublicVenueData(data), isFalse);
    });

    test('excludes hidden venues', () {
      final data = {
        'isDeleted': false,
        'searchablePublic': true,
        'isHidden': true,
        'status': 'active',
      };

      expect(FirebaseVenueRepository.isPublicVenueData(data), isFalse);
    });

    test('excludes suspended venues', () {
      final data = {
        'isDeleted': false,
        'searchablePublic': true,
        'status': 'suspended',
      };

      expect(FirebaseVenueRepository.isPublicVenueData(data), isFalse);
    });

    test('mapVenueData keeps legacy public venues and drops hidden ones', () {
      final venues = FirebaseVenueRepository.mapVenueData([
        MapEntry('legacy-1', {
          'isDeleted': false,
          'status': 'active',
          'name': 'Legacy Pub',
          'category': 'Bar',
          'venueType': 'Bar',
          'address': {'city': 'London'},
          'lat': 51.5,
          'lng': -0.1,
        }),
        MapEntry('hidden-1', {
          'isDeleted': false,
          'searchablePublic': false,
          'status': 'active',
          'name': 'Hidden Pub',
          'category': 'Bar',
          'venueType': 'Bar',
          'address': {'city': 'London'},
          'lat': 51.5,
          'lng': -0.1,
        }),
      ]);

      expect(venues.map((venue) => venue.id), ['legacy-1']);
    });
  });
}
