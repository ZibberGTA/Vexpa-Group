import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_app/features/home/models/deal_model.dart';
import 'package:nightlife_app/features/home/models/event_model.dart';
import 'package:nightlife_app/features/home/models/venue_model.dart';
import 'package:nightlife_app/features/home/services/experience_content_support.dart';
import 'package:nightlife_app/features/owner/data/mobile_deal_write_payload.dart';
import 'package:nightlife_app/features/owner/data/mobile_drink_write_payload.dart';
import 'package:nightlife_app/features/owner/data/mobile_event_write_payload.dart';
import 'package:nightlife_app/features/venues/models/venue_media_model.dart';
import 'package:vex_engines/experience/application/experience_deal_visibility.dart';
import 'package:vex_engines/experience/application/experience_drink_import_validator.dart';
import 'package:vex_engines/experience/application/experience_event_visibility.dart';
import 'package:vex_engines/experience/application/experience_owner_write_service.dart';
import 'package:vex_engines/experience/application/venue_content_ordering_service.dart';

void main() {
  group('Mobile experience engine delegation', () {
    test('deal model visibility delegates to ExperienceDealVisibility', () {
      final now = DateTime.now();
      final deal = DealModel(
        id: '1',
        venueId: 'v',
        title: 'Current',
        description: '',
        startTime: '',
        endTime: '',
        startDateTime: now.subtract(const Duration(hours: 1)),
        endDateTime: now.add(const Duration(hours: 2)),
        isActive: true,
      );

      expect(deal.isCurrentlyVisible, isTrue);
      expect(
        deal.isCurrentlyVisible,
        ExperienceDealVisibility.isPublicCurrent(
          isDeleted: deal.isDeleted,
          isActive: deal.isActive,
          startDateTime: deal.startDateTime,
          endDateTime: deal.endDateTime,
          effectiveEndDateTime: deal.effectiveEndDateTime,
        ),
      );
    });

    test('event model visibility delegates to ExperienceEventVisibility', () {
      final now = DateTime.now();
      final event = EventModel(
        id: '1',
        venueId: 'v',
        title: 'Upcoming',
        description: '',
        startDateTime: now.add(const Duration(days: 1)),
        endDateTime: now.add(const Duration(days: 1, hours: 3)),
        createdAt: now,
        category: 'General',
        imageUrl: '',
        isDeleted: false,
        isActive: true,
      );

      expect(event.isLiveOrUpcoming, isTrue);
      expect(
        event.isLiveOrUpcoming,
        ExperienceEventVisibility.isPublicVisible(
          isDeleted: event.isDeleted,
          isActive: event.isActive,
          startDateTime: event.startDateTime,
          endDateTime: event.endDateTime,
        ),
      );
    });

    test('gallery bundle sort delegates to VenueContentOrderingService', () {
      const ordering = VenueContentOrderingService();
      final items = [
        VenueMediaModel(
          id: '1',
          venueId: 'v',
          mediaType: VenueMediaType.gallery,
          imageUrl: 'a',
          featured: false,
          sortOrder: 1,
          uploadedAt: DateTime(2026, 1, 2),
        ),
        VenueMediaModel(
          id: '2',
          venueId: 'v',
          mediaType: VenueMediaType.gallery,
          imageUrl: 'b',
          featured: true,
          sortOrder: 0,
          uploadedAt: DateTime(2026, 1, 1),
        ),
      ];

      final bundle = VenueMediaBundle.fromItems(items);
      expect(bundle.galleryItems.first.id, '2');
      expect(
        ordering.compareGalleryMedia(
          aFeatured: false,
          bFeatured: true,
          aSortOrder: 1,
          bSortOrder: 0,
          aUploadedAt: DateTime(2026, 1, 2),
          bUploadedAt: DateTime(2026, 1, 1),
        ),
        greaterThan(0),
      );
      expect(MobileExperienceContentSupport.ordering, ordering);
    });

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

    test('mobile deal and event models delegate presentation getters', () {
      final now = DateTime.now();
      final deal = DealModel(
        id: '1',
        venueId: 'v',
        title: 'Happy Hour',
        description: '',
        startTime: '',
        endTime: '23:00',
        startDateTime: now.add(const Duration(hours: 2)),
        endDateTime: now.add(const Duration(hours: 5)),
        isActive: true,
      );

      expect(deal.expiryLabel, contains('Starts'));

      final event = EventModel(
        id: '1',
        venueId: 'v',
        title: 'Live DJ',
        description: '',
        startDateTime: DateTime(2026, 7, 13, 20),
        endDateTime: DateTime(2026, 7, 13, 23, 59),
        createdAt: now,
        category: 'Music',
        imageUrl: '',
        isDeleted: false,
      );

      expect(event.formattedDate, MobileExperienceContentSupport.presentation.formatDateOnly(event.startDateTime));
      expect(event.endDateTime.difference(event.startDateTime).inHours, 3);
    });

    test('mobile venue model parses feature tags via public presentation', () {
      final venue = VenueModel.fromMap('v1', {
        'name': 'Test',
        'featureTags': ['DJ'],
        'venueFeatures': {'liveMusic': true},
      });

      expect(venue.featureTags, contains('DJ'));
      expect(venue.featureTags, contains('Live Music'));
    });
  });
}
