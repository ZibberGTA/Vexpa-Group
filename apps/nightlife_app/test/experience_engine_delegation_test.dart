import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_app/features/home/services/experience_content_support.dart';
import 'package:nightlife_app/features/owner/data/mobile_deal_write_payload.dart';
import 'package:nightlife_app/features/owner/data/mobile_drink_write_payload.dart';
import 'package:nightlife_app/features/owner/data/mobile_event_write_payload.dart';
import 'package:vex_engines/experience/application/experience_drink_import_validator.dart';
import 'package:vex_engines/experience/application/experience_owner_write_service.dart';

void main() {
  group('Mobile experience engine delegation', () {
    test('mobile drink write payload delegates preset create to engine', () {
      final payload = MobileDrinkWritePayload.buildPresetCreate(
        venueId: 'v1',
        venueName: 'Bar',
        drinkName: 'Guinness',
        categoryDisplayName: 'Beer',
        price: 5.5,
      );

      expect(payload['category'], 'beer');
      expect(payload['isPresetDrink'], isTrue);
      expect(payload['createdAt'], isNotNull);
      expect(
        payload['searchTerms'],
        ExperienceOwnerWriteService.mobilePresetDrinkCreateFields(
          venueId: 'v1',
          venueName: 'Bar',
          drinkName: 'Guinness',
          categoryDisplayName: 'Beer',
          price: 5.5,
        )['searchTerms'],
      );
    });

    test('mobile deal write payload delegates create to engine', () {
      final start = DateTime(2026, 7, 10, 17);
      final end = DateTime(2026, 7, 10, 20);

      final payload = MobileDealWritePayload.buildCreate(
        venueId: 'v1',
        venueName: 'Bar',
        title: 'Happy Hour',
        description: '2 for 1',
        startDateTime: start,
        endDateTime: end,
        startTime: '17:00',
        endTime: '20:00',
      );

      expect(payload['dealType'], 'drink_offer');
      expect(payload['startDateTime'], isNotNull);
      expect(payload['updatedAt'], isNotNull);
    });

    test('mobile event write payload delegates create to engine', () {
      final start = DateTime(2026, 7, 12, 20);
      final end = DateTime(2026, 7, 13);

      final payload = MobileEventWritePayload.buildCreate(
        venueId: 'v1',
        title: 'Quiz Night',
        description: 'Weekly quiz',
        startDateTime: start,
        endDateTime: end,
        category: 'Quiz Night',
      );

      expect(payload['notificationSent'], isFalse);
      expect(payload['createdAt'], isNotNull);
      expect(payload['dateTime'], isNotNull);
    });

    test('MobileExperienceContentSupport exposes owner write facade', () {
      expect(MobileExperienceContentSupport.ownerWrite,
          const ExperienceOwnerWriteService());
      expect(MobileExperienceContentSupport.drinkImport,
          const ExperienceDrinkImportValidator());
    });
  });
}
