import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_app/core/vexcore/firebase_venue_repository.dart';
import 'package:nightlife_app/core/vexcore/firebase_venue_write_repository.dart';
import 'package:nightlife_app/core/vexcore/mobile_vexcore.dart';
import 'package:nightlife_app/features/home/models/venue_model.dart';
import 'package:nightlife_app/features/home/services/venue_service.dart';
import 'package:nightlife_app/features/owner/services/owner_venue_service.dart';
import 'package:vex_core/vex_core.dart';
import 'package:vex_engines/venue/application/venue_owner_profile_service.dart';

import 'support/mock_venue_write_repository.dart';

void main() {
  group('OwnerVenueService', () {
    tearDown(() {
      MobileVexCore.resetTestOverrides();
    });

    test('owner venue list delegates to repository once', () async {
      final repository = _OwnerListRepository();
      MobileVexCore.overrideVenueRepository(repository);

      await OwnerVenueService.watchVenuesForOwner('owner-1').first;

      expect(repository.watchOwnerCalls, 1);
    });

    test('VenueService.getVenuesForOwner uses owner repository stream', () async {
      final repository = _OwnerListRepository();
      MobileVexCore.overrideVenueRepository(repository);

      await VenueService.getVenuesForOwner('owner-1').first;

      expect(repository.watchOwnerCalls, 1);
    });

    test('create venue performs one write on valid payload', () async {
      final writeRepository = MockVenueWriteRepository();
      MobileVexCore.overrideVenueWriteRepository(writeRepository);

      final result = await OwnerVenueService.createVenue(
        ownerId: 'owner-1',
        draft: _validDraft(),
      );

      expect(result, isA<DataSuccess<String>>());
      expect(writeRepository.createCalls, 1);
    });

    test('update venue performs one write on valid payload', () async {
      final writeRepository = MockVenueWriteRepository();
      MobileVexCore.overrideVenueWriteRepository(writeRepository);

      final result = await OwnerVenueService.updateVenue(
        venueId: 'venue-1',
        draft: _validDraft(),
      );

      expect(result, isA<DataSuccess<void>>());
      expect(writeRepository.updateCalls, 1);
      expect(writeRepository.lastUpdateVenueId, 'venue-1');
    });

    test('does not write when validation fails', () async {
      final writeRepository = MockVenueWriteRepository();
      MobileVexCore.overrideVenueWriteRepository(writeRepository);

      final result = await OwnerVenueService.createVenue(
        ownerId: 'owner-1',
        draft: _validDraft(websiteUrl: 'not-a-url'),
      );

      expect(result, isA<DataFailure>());
      expect(writeRepository.createCalls, 0);
    });

    test('repository failure is preserved', () async {
      MobileVexCore.overrideVenueWriteRepository(
        MockVenueWriteRepository(
          createError: const VexException('Write failed', code: 'write-failed'),
        ),
      );

      final result = await OwnerVenueService.createVenue(
        ownerId: 'owner-1',
        draft: _validDraft(),
      );

      expect(result, isA<DataFailure>());
      expect((result as DataFailure).error.code, 'write-failed');
    });
  });

  group('FirebaseVenueWriteRepository payload mapping', () {
    test('preserves server timestamp field names', () {
      final repository = FirebaseVenueWriteRepository();
      final payload = VenueWritePayload(
        fields: {'name': 'Neon Room'},
        serverTimestampFields: const ['createdAt', 'updatedAt'],
      );

      final firestorePayload = repository.buildFirestorePayload(payload);

      expect(firestorePayload.containsKey('createdAt'), isTrue);
      expect(firestorePayload.containsKey('updatedAt'), isTrue);
      expect(firestorePayload['location'], isNull);
    });
  });
}

VenueOwnerProfileDraft _validDraft({String websiteUrl = ''}) {
  return VenueOwnerProfileDraft(
    name: 'Neon Room',
    description: 'Late-night cocktails',
    address: '1 Brick Lane',
    category: 'Bar',
    crowdLevel: 'busy',
    bannerImageUrl: 'https://cdn.example.com/banner.jpg',
    logoUrl: 'https://cdn.example.com/logo.jpg',
    websiteUrl: websiteUrl,
    openingHours: {
      for (final day in const [
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday',
      ])
        day: {'closed': false, 'open': '18:00', 'close': '02:00'},
    },
  );
}

class _OwnerListRepository extends FirebaseVenueRepository {
  int watchOwnerCalls = 0;

  @override
  Stream<List<VenueModel>> watchOwnerHomeVenues(String ownerId) {
    watchOwnerCalls++;
    return Stream.value(const []);
  }
}
