import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/features/venue/data/models/deal_model.dart';
import 'package:nightlife_web/features/venue/data/models/event_model.dart';
import 'package:nightlife_web/features/venue/data/public_venue_content_filters.dart';
import 'package:nightlife_web/features/venue/data/venue_deals_repository.dart';
import 'package:nightlife_web/features/venue/data/venue_events_repository.dart';
import 'package:nightlife_web/features/venue/widgets/sections/venue_deals_section.dart';
import 'package:nightlife_web/features/venue/widgets/sections/venue_events_section.dart';
import 'package:nightlife_web/features/venue_management/models/deal_status.dart';
import 'package:nightlife_web/features/venue_management/models/event_status.dart';

void main() {
  final now = DateTime(2026, 7, 1, 12);

  group('computeDealStatus', () {
    test('future deals show Scheduled', () {
      final deal = DealModel(
        id: '1',
        venueId: 'v',
        title: 'Future',
        description: '',
        startDateTime: now.add(const Duration(days: 2)),
        endDateTime: now.add(const Duration(days: 10)),
        isActive: true,
      );
      expect(computeDealStatus(deal, now: now), DealStatus.scheduled);
    });

    test('current deals show Active', () {
      final deal = DealModel(
        id: '1',
        venueId: 'v',
        title: 'Current',
        description: '',
        startDateTime: now.subtract(const Duration(days: 1)),
        endDateTime: now.add(const Duration(days: 1)),
        isActive: true,
      );
      expect(computeDealStatus(deal, now: now), DealStatus.active);
    });

    test('expired deals show Expired', () {
      final deal = DealModel(
        id: '1',
        venueId: 'v',
        title: 'Expired',
        description: '',
        startDateTime: now.subtract(const Duration(days: 10)),
        endDateTime: now.subtract(const Duration(days: 1)),
        isActive: true,
      );
      expect(computeDealStatus(deal, now: now), DealStatus.expired);
    });

    test('inactive deals show Paused', () {
      final deal = DealModel(
        id: '1',
        venueId: 'v',
        title: 'Paused',
        description: '',
        startDateTime: now.subtract(const Duration(days: 1)),
        endDateTime: now.add(const Duration(days: 1)),
        isActive: false,
      );
      expect(computeDealStatus(deal, now: now), DealStatus.paused);
    });
  });

  group('computeEventStatus', () {
    test('future events show Upcoming', () {
      final event = EventModel(
        id: '1',
        venueId: 'v',
        title: 'Future',
        description: '',
        startDateTime: now.add(const Duration(days: 2)),
        endDateTime: now.add(const Duration(days: 2, hours: 4)),
        createdAt: now,
        category: 'General',
        imageUrl: '',
        isDeleted: false,
        isActive: true,
      );
      expect(computeEventStatus(event, now: now), EventStatus.upcoming);
    });

    test('current events show Live', () {
      final event = EventModel(
        id: '1',
        venueId: 'v',
        title: 'Live',
        description: '',
        startDateTime: now.subtract(const Duration(hours: 1)),
        endDateTime: now.add(const Duration(hours: 3)),
        createdAt: now,
        category: 'General',
        imageUrl: '',
        isDeleted: false,
        isActive: true,
      );
      expect(computeEventStatus(event, now: now), EventStatus.live);
    });

    test('expired events show Ended', () {
      final event = EventModel(
        id: '1',
        venueId: 'v',
        title: 'Ended',
        description: '',
        startDateTime: now.subtract(const Duration(days: 2)),
        endDateTime: now.subtract(const Duration(hours: 1)),
        createdAt: now,
        category: 'General',
        imageUrl: '',
        isDeleted: false,
        isActive: true,
      );
      expect(computeEventStatus(event, now: now), EventStatus.ended);
    });

    test('inactive events show Draft', () {
      final event = EventModel(
        id: '1',
        venueId: 'v',
        title: 'Draft',
        description: '',
        startDateTime: now.add(const Duration(days: 2)),
        endDateTime: now.add(const Duration(days: 2, hours: 4)),
        createdAt: now,
        category: 'General',
        imageUrl: '',
        isDeleted: false,
        isActive: false,
      );
      expect(computeEventStatus(event, now: now), EventStatus.draft);
    });
  });

  group('public venue content filters', () {
    test('active deals appear under Current Deals only', () {
      final deal = DealModel(
        id: '1',
        venueId: 'v',
        title: 'Current',
        description: '',
        startDateTime: now.subtract(const Duration(days: 1)),
        endDateTime: now.add(const Duration(days: 1)),
        isActive: true,
      );

      expect(isPublicCurrentDeal(deal, now: now), isTrue);
      expect(isPublicUpcomingDeal(deal, now: now), isFalse);
    });

    test('future deals appear under Upcoming Deals only', () {
      final deal = DealModel(
        id: '1',
        venueId: 'v',
        title: 'Future',
        description: '',
        startDateTime: now.add(const Duration(days: 2)),
        endDateTime: now.add(const Duration(days: 10)),
        isActive: true,
      );

      expect(isPublicCurrentDeal(deal, now: now), isFalse);
      expect(isPublicUpcomingDeal(deal, now: now), isTrue);
    });

    test('expired and paused deals are hidden from public', () {
      final expired = DealModel(
        id: '1',
        venueId: 'v',
        title: 'Expired',
        description: '',
        startDateTime: now.subtract(const Duration(days: 10)),
        endDateTime: now.subtract(const Duration(days: 1)),
        isActive: true,
      );
      final paused = DealModel(
        id: '2',
        venueId: 'v',
        title: 'Paused',
        description: '',
        startDateTime: now.subtract(const Duration(days: 1)),
        endDateTime: now.add(const Duration(days: 1)),
        isActive: false,
      );

      expect(isPublicVisibleDeal(expired, now: now), isFalse);
      expect(isPublicVisibleDeal(paused, now: now), isFalse);
    });

    test('active events appear under Current Events only', () {
      final event = EventModel(
        id: '1',
        venueId: 'v',
        title: 'Live',
        description: '',
        startDateTime: now.subtract(const Duration(hours: 1)),
        endDateTime: now.add(const Duration(hours: 3)),
        createdAt: now,
        category: 'General',
        imageUrl: '',
        isDeleted: false,
        isActive: true,
      );

      expect(isPublicCurrentEvent(event, now: now), isTrue);
      expect(isPublicUpcomingEvent(event, now: now), isFalse);
    });

    test('future events appear under Upcoming Events only', () {
      final event = EventModel(
        id: '1',
        venueId: 'v',
        title: 'Future',
        description: '',
        startDateTime: now.add(const Duration(days: 2)),
        endDateTime: now.add(const Duration(days: 2, hours: 4)),
        createdAt: now,
        category: 'General',
        imageUrl: '',
        isDeleted: false,
        isActive: true,
      );

      expect(isPublicCurrentEvent(event, now: now), isFalse);
      expect(isPublicUpcomingEvent(event, now: now), isTrue);
    });

    test('expired and draft events are hidden from public', () {
      final expired = EventModel(
        id: '1',
        venueId: 'v',
        title: 'Ended',
        description: '',
        startDateTime: now.subtract(const Duration(days: 2)),
        endDateTime: now.subtract(const Duration(hours: 1)),
        createdAt: now,
        category: 'General',
        imageUrl: '',
        isDeleted: false,
        isActive: true,
      );
      final draft = EventModel(
        id: '2',
        venueId: 'v',
        title: 'Draft',
        description: '',
        startDateTime: now.add(const Duration(days: 2)),
        endDateTime: now.add(const Duration(days: 2, hours: 4)),
        createdAt: now,
        category: 'General',
        imageUrl: '',
        isDeleted: false,
        isActive: false,
      );

      expect(isPublicVisibleEvent(expired, now: now), isFalse);
      expect(isPublicVisibleEvent(draft, now: now), isFalse);
    });
  });

  group('VenueDealsSection', () {
    testWidgets('separates Current Deals and Upcoming Deals', (tester) async {
      final repo = _FakePublicDealsRepository([
        DealModel(
          id: 'current',
          venueId: 'v',
          title: 'Current Deal',
          description: '',
          startDateTime: now.subtract(const Duration(days: 1)),
          endDateTime: now.add(const Duration(days: 1)),
          isActive: true,
        ),
        DealModel(
          id: 'upcoming',
          venueId: 'v',
          title: 'Upcoming Deal',
          description: '',
          startDateTime: now.add(const Duration(days: 3)),
          endDateTime: now.add(const Duration(days: 10)),
          isActive: true,
        ),
        DealModel(
          id: 'paused',
          venueId: 'v',
          title: 'Paused Deal',
          description: '',
          startDateTime: now.subtract(const Duration(days: 1)),
          endDateTime: now.add(const Duration(days: 1)),
          isActive: false,
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VenueDealsSection(
              venueId: 'v',
              repository: repo,
              now: now,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Current Deals'), findsOneWidget);
      expect(find.text('Upcoming Deals'), findsOneWidget);
      expect(find.text('Current Deal'), findsOneWidget);
      expect(find.text('Upcoming Deal'), findsOneWidget);
      expect(find.text('Upcoming'), findsWidgets);
      expect(find.text('Paused Deal'), findsNothing);
    });
  });

  group('VenueEventsSection', () {
    testWidgets('separates Current Events and Upcoming Events', (tester) async {
      final repo = _FakePublicEventsRepository([
        EventModel(
          id: 'current',
          venueId: 'v',
          title: 'Live Event',
          description: '',
          startDateTime: now.subtract(const Duration(hours: 1)),
          endDateTime: now.add(const Duration(hours: 3)),
          createdAt: now,
          category: 'General',
          imageUrl: '',
          isDeleted: false,
          isActive: true,
        ),
        EventModel(
          id: 'upcoming',
          venueId: 'v',
          title: 'Future Event',
          description: '',
          startDateTime: now.add(const Duration(days: 3)),
          endDateTime: now.add(const Duration(days: 3, hours: 4)),
          createdAt: now,
          category: 'General',
          imageUrl: '',
          isDeleted: false,
          isActive: true,
        ),
        EventModel(
          id: 'draft',
          venueId: 'v',
          title: 'Draft Event',
          description: '',
          startDateTime: now.add(const Duration(days: 3)),
          endDateTime: now.add(const Duration(days: 3, hours: 4)),
          createdAt: now,
          category: 'General',
          imageUrl: '',
          isDeleted: false,
          isActive: false,
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VenueEventsSection(
              venueId: 'v',
              repository: repo,
              now: now,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Current Events'), findsOneWidget);
      expect(find.text('Upcoming Events'), findsOneWidget);
      expect(find.text('Live Event'), findsOneWidget);
      expect(find.text('Future Event'), findsOneWidget);
      expect(find.text('Upcoming'), findsWidgets);
      expect(find.text('Draft Event'), findsNothing);
    });
  });
}

class _FakePublicDealsRepository extends VenueDealsRepository {
  _FakePublicDealsRepository(this._deals) : super(firestore: null);

  final List<DealModel> _deals;

  @override
  Stream<List<DealModel>> watchDeals(String venueId) async* {
    yield _deals;
  }
}

class _FakePublicEventsRepository extends VenueEventsRepository {
  _FakePublicEventsRepository(this._events) : super(firestore: null);

  final List<EventModel> _events;

  @override
  Stream<List<EventModel>> watchEvents(String venueId) async* {
    yield _events;
  }
}
