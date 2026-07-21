import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/features/venue/data/venue_deals_repository.dart';
import 'package:nightlife_web/features/venue/data/venue_events_repository.dart';
import 'package:nightlife_web/features/venue_management/data/venue_management_activity_recording.dart';
import 'package:nightlife_web/features/venue_management/data/venue_management_activity_repository.dart';
import 'package:nightlife_web/features/venue_management/data/venue_management_activity_service.dart';
import 'package:nightlife_web/features/venue_management/models/deal_types.dart';
import 'package:nightlife_web/features/venue_management/models/venue_management_activity.dart';
import 'package:nightlife_web/features/venue_management/models/venue_management_activity_types.dart';
import 'package:nightlife_web/features/venue_management/presentation/venue_management_activity_presentation_mapper.dart';

void main() {
  group('VenueManagementActivityRecording deals', () {
    late InMemoryVenueManagementActivityRepository repository;
    late DefaultVenueManagementActivityService service;

    setUp(() {
      repository = InMemoryVenueManagementActivityRepository();
      service = DefaultVenueManagementActivityService(repository: repository);
    });

    Future<void> recordDeal({
      required String actionType,
      required String description,
      String dealId = 'deal-1',
      String dealTitle = 'Friday Happy Hour',
      String venueId = 'venue-1',
      String actorUid = 'owner-1',
    }) {
      return VenueManagementActivityRecording.recordDeal(
        service: service,
        venueId: venueId,
        dealId: dealId,
        dealTitle: dealTitle,
        actorUid: actorUid,
        actionType: actionType,
        description: description,
      );
    }

    test('creating a deal writes one canonical activity record', () async {
      await recordDeal(
        actionType: VenueManagementActivityActionTypes.created,
        description: 'Deal created',
      );

      expect(repository.records, hasLength(1));
      final record = repository.records.single;
      expect(record.sourceArea, VenueManagementActivitySourceAreas.deals);
      expect(record.actionType, VenueManagementActivityActionTypes.created);
      expect(record.entityType, VenueManagementActivityEntityTypes.deal);
      expect(record.entityId, 'deal-1');
      expect(record.entityName, 'Friday Happy Hour');
      expect(record.description, 'Deal created');
      expect(record.venueId, 'venue-1');
      expect(record.actorUid, 'owner-1');
    });

    test('updating a deal writes one canonical activity record', () async {
      await recordDeal(
        actionType: VenueManagementActivityActionTypes.updated,
        description: 'Deal updated',
      );

      expect(repository.records, hasLength(1));
      expect(repository.records.single.actionType, 'updated');
    });

    test('activating a deal writes activated activity', () async {
      await recordDeal(
        actionType: VenueManagementActivityActionTypes.activated,
        description: 'Deal activated',
      );

      expect(repository.records.single.actionType, 'activated');
    });

    test('deactivating a deal writes deactivated activity', () async {
      await recordDeal(
        actionType: VenueManagementActivityActionTypes.deactivated,
        description: 'Deal deactivated',
      );

      expect(repository.records.single.actionType, 'deactivated');
    });

    test('archiving a deal writes archived activity', () async {
      await recordDeal(
        actionType: VenueManagementActivityActionTypes.archived,
        description: 'Deal archived',
      );

      expect(repository.records.single.actionType, 'archived');
    });

    test('does not write duplicate records for a single mutation call', () async {
      await recordDeal(
        actionType: VenueManagementActivityActionTypes.created,
        description: 'Deal created',
      );

      expect(repository.records, hasLength(1));
    });

    test('scopes activity to the provided venueId', () async {
      await recordDeal(
        actionType: VenueManagementActivityActionTypes.created,
        description: 'Deal created',
        venueId: 'venue-copper-lantern',
      );

      expect(repository.records.single.venueId, 'venue-copper-lantern');
    });
  });

  group('VenueManagementActivityRecording events', () {
    late InMemoryVenueManagementActivityRepository repository;
    late DefaultVenueManagementActivityService service;

    setUp(() {
      repository = InMemoryVenueManagementActivityRepository();
      service = DefaultVenueManagementActivityService(repository: repository);
    });

    Future<void> recordEvent({
      required String actionType,
      required String description,
      String eventId = 'event-1',
      String eventTitle = 'Friday DJ Night',
      String venueId = 'venue-1',
      String actorUid = 'owner-1',
    }) {
      return VenueManagementActivityRecording.recordEvent(
        service: service,
        venueId: venueId,
        eventId: eventId,
        eventTitle: eventTitle,
        actorUid: actorUid,
        actionType: actionType,
        description: description,
      );
    }

    test('creating an event writes one canonical activity record', () async {
      await recordEvent(
        actionType: VenueManagementActivityActionTypes.created,
        description: 'Event created',
      );

      expect(repository.records, hasLength(1));
      final record = repository.records.single;
      expect(record.sourceArea, VenueManagementActivitySourceAreas.events);
      expect(record.actionType, VenueManagementActivityActionTypes.created);
      expect(record.entityType, VenueManagementActivityEntityTypes.event);
      expect(record.entityId, 'event-1');
      expect(record.entityName, 'Friday DJ Night');
      expect(record.description, 'Event created');
      expect(record.venueId, 'venue-1');
      expect(record.actorUid, 'owner-1');
    });

    test('updating an event writes one canonical activity record', () async {
      await recordEvent(
        actionType: VenueManagementActivityActionTypes.updated,
        description: 'Event updated',
      );

      expect(repository.records.single.actionType, 'updated');
    });

    test('publishing an event writes published activity', () async {
      await recordEvent(
        actionType: VenueManagementActivityActionTypes.published,
        description: 'Event published',
      );

      expect(repository.records.single.actionType, 'published');
    });

    test('unpublishing an event writes unpublished activity', () async {
      await recordEvent(
        actionType: VenueManagementActivityActionTypes.unpublished,
        description: 'Event unpublished',
      );

      expect(repository.records.single.actionType, 'unpublished');
    });

    test('archiving an event writes archived activity', () async {
      await recordEvent(
        actionType: VenueManagementActivityActionTypes.archived,
        description: 'Event archived',
      );

      expect(repository.records.single.actionType, 'archived');
    });
  });

  group('Deal and event repository mutation guards', () {
    test('addDeal records no activity when Firestore is unavailable', () async {
      final repository = InMemoryVenueManagementActivityRepository();
      final dealsRepository = VenueDealsRepository(
        activityService: DefaultVenueManagementActivityService(
          repository: repository,
        ),
      );

      await expectLater(
        dealsRepository.addDeal(
          venueId: 'venue-1',
          venueName: 'Copper Lantern',
          title: 'Happy Hour',
          description: 'Two for one',
          dealType: DealTypes.percentageOff,
          value: '20',
          startDateTime: DateTime(2026, 7, 18, 18),
          endDateTime: DateTime(2026, 7, 18, 22),
          availableDays: const ['Friday'],
          startTime: '18:00',
          endTime: '22:00',
          isActive: true,
          featured: false,
          createdBy: 'owner-1',
        ),
        throwsA(isA<StateError>()),
      );

      expect(repository.records, isEmpty);
    });

    test('addEvent records no activity when Firestore is unavailable', () async {
      final repository = InMemoryVenueManagementActivityRepository();
      final eventsRepository = VenueEventsRepository(
        activityService: DefaultVenueManagementActivityService(
          repository: repository,
        ),
      );

      await expectLater(
        eventsRepository.addEvent(
          venueId: 'venue-1',
          venueName: 'Copper Lantern',
          title: 'DJ Night',
          description: 'Live set',
          startDateTime: DateTime(2026, 7, 18, 21),
          endDateTime: DateTime(2026, 7, 19, 2),
          isActive: true,
          featured: false,
          createdBy: 'owner-1',
        ),
        throwsA(isA<StateError>()),
      );

      expect(repository.records, isEmpty);
    });
  });

  group('Dashboard activity loader integration', () {
    final referenceNow = DateTime(2026, 7, 18, 12);

    test('loadRecentActivity returns newly written deal and event activity', () async {
      final repository = InMemoryVenueManagementActivityRepository();
      final service = DefaultVenueManagementActivityService(repository: repository);
      final mapper = VenueManagementActivityPresentationMapper(
        now: referenceNow,
      );

      await VenueManagementActivityRecording.recordDeal(
        service: service,
        venueId: 'venue-1',
        dealId: 'deal-1',
        dealTitle: 'Happy Hour',
        actorUid: 'owner-1',
        actionType: VenueManagementActivityActionTypes.created,
        description: 'Deal created',
      );
      await VenueManagementActivityRecording.recordEvent(
        service: service,
        venueId: 'venue-1',
        eventId: 'event-1',
        eventTitle: 'DJ Night',
        actorUid: 'owner-1',
        actionType: VenueManagementActivityActionTypes.created,
        description: 'Event created',
      );

      final recent = await service.loadRecentActivity(venueId: 'venue-1', limit: 10);
      final presentations = recent.map(mapper.map).toList(growable: false);

      expect(recent, hasLength(2));
      expect(recent.any((record) => record.sourceArea == 'deals'), isTrue);
      expect(recent.any((record) => record.sourceArea == 'events'), isTrue);
      expect(
        presentations.any((item) => item.title == 'Deal added'),
        isTrue,
      );
      expect(
        presentations.any((item) => item.title == 'Event added'),
        isTrue,
      );
    });

    test('loadRecentActivity excludes activity from other venues', () async {
      final repository = InMemoryVenueManagementActivityRepository();
      final service = DefaultVenueManagementActivityService(repository: repository);

      await VenueManagementActivityRecording.recordDeal(
        service: service,
        venueId: 'venue-a',
        dealId: 'deal-a',
        dealTitle: 'Venue A deal',
        actorUid: 'owner-1',
        actionType: VenueManagementActivityActionTypes.created,
        description: 'Deal created',
      );
      await VenueManagementActivityRecording.recordDeal(
        service: service,
        venueId: 'venue-b',
        dealId: 'deal-b',
        dealTitle: 'Venue B deal',
        actorUid: 'owner-2',
        actionType: VenueManagementActivityActionTypes.created,
        description: 'Deal created',
      );

      final recent = await service.loadRecentActivity(venueId: 'venue-a', limit: 10);

      expect(recent, hasLength(1));
      expect(recent.single.venueId, 'venue-a');
      expect(recent.single.entityName, 'Venue A deal');
    });
  });

  group('Deal and event presentation mapping', () {
    final referenceNow = DateTime(2026, 7, 18, 12);
    final mapper = VenueManagementActivityPresentationMapper(now: referenceNow);

    test('mapper renders deal created activity', () {
      final presentation = mapper.map(
        VenueManagementActivity(
          venueId: 'venue-1',
          sourceArea: VenueManagementActivitySourceAreas.deals,
          actionType: VenueManagementActivityActionTypes.created,
          entityType: VenueManagementActivityEntityTypes.deal,
          entityId: 'deal-1',
          entityName: 'Happy Hour',
          description: 'Deal created',
          actorUid: 'owner-1',
          occurredAt: DateTime(2026, 7, 18, 11, 30),
        ),
      );

      expect(presentation.title, 'Deal added');
      expect(presentation.description, '"Happy Hour" was added');
      expect(presentation.icon, Icons.local_offer_outlined);
    });

    test('mapper renders event updated activity', () {
      final presentation = mapper.map(
        VenueManagementActivity(
          venueId: 'venue-1',
          sourceArea: VenueManagementActivitySourceAreas.events,
          actionType: VenueManagementActivityActionTypes.updated,
          entityType: VenueManagementActivityEntityTypes.event,
          entityId: 'event-1',
          entityName: 'DJ Night',
          description: 'Event updated',
          actorUid: 'owner-1',
          occurredAt: DateTime(2026, 7, 18, 11, 30),
        ),
      );

      expect(presentation.title, 'Event updated');
      expect(presentation.description, '"DJ Night" was updated');
      expect(presentation.icon, Icons.event_outlined);
    });
  });
}
