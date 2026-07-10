import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/core/vexcore/firebase_venue_profile_write_repository.dart';
import 'package:vex_engines/venue/application/venue_profile_update.dart';

void main() {
  group('FirebaseVenueProfileWriteRepository payload mapping', () {
    test('adds server timestamp fields to prepared update', () {
      final payload = FirebaseVenueProfileWriteRepository.buildFirestorePayload(
        const VenueProfileUpdate(
          fields: {
            'name': 'Copper Lantern',
            'searchTerms': ['copper', 'lantern'],
          },
        ),
      );

      expect(payload['name'], 'Copper Lantern');
      expect(payload['updatedAt'], isA<FieldValue>());
    });

    test('preserves crowd update timestamp fields', () {
      final payload = FirebaseVenueProfileWriteRepository.buildFirestorePayload(
        const VenueProfileUpdate(
          fields: {'crowdLevel': 'busy', 'currentCrowdLevel': 'busy'},
          serverTimestampFields: ['updatedAt', 'crowdUpdatedAt'],
        ),
      );

      expect(payload['crowdLevel'], 'busy');
      expect(payload['updatedAt'], isA<FieldValue>());
      expect(payload['crowdUpdatedAt'], isA<FieldValue>());
    });
  });
}
