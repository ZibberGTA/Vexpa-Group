import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/features/venue/data/models/deal_model.dart';
import 'package:nightlife_web/features/venue/data/models/event_model.dart';
import 'package:nightlife_web/features/venue/data/public_venue_content_filters.dart';
import 'package:nightlife_web/features/venue_management/models/deal_status.dart';
import 'package:nightlife_web/features/venue_management/models/event_status.dart';
import 'package:vex_engines/experience/application/experience_deal_status.dart';
import 'package:vex_engines/experience/application/experience_deal_visibility.dart';
import 'package:vex_engines/experience/application/experience_event_status.dart';
import 'package:vex_engines/experience/application/experience_event_visibility.dart';

void main() {
  group('Web experience engine delegation', () {
    test('deal model visibility delegates to ExperienceDealVisibility', () {
      final now = DateTime.now();
      final deal = DealModel(
        id: '1',
        venueId: 'v',
        title: 'Current',
        description: '',
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
      expect(isPublicVisibleDeal(deal), isTrue);
    });

    test('event model visibility delegates to ExperienceEventVisibility', () {
      final now = DateTime.now();
      final event = EventModel(
        id: '1',
        venueId: 'v',
        title: 'Live',
        description: '',
        startDateTime: now.subtract(const Duration(hours: 1)),
        endDateTime: now.add(const Duration(hours: 2)),
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

    test('deal status shims delegate to ExperienceDealStatusRules', () {
      final now = DateTime(2026, 7, 10, 12);
      final deal = DealModel(
        id: '1',
        venueId: 'v',
        title: 'Scheduled',
        description: '',
        startDateTime: now.add(const Duration(days: 2)),
        endDateTime: now.add(const Duration(days: 5)),
        isActive: true,
      );

      expect(
        computeDealStatus(deal, now: now),
        ExperienceDealStatusRules.compute(
          isActive: deal.isActive,
          startDateTime: deal.startDateTime,
          endDateTime: deal.endDateTime,
          effectiveEndDateTime: deal.effectiveEndDateTime,
          now: now,
        ),
      );
      expect(computeDealStatus(deal, now: now), DealStatus.scheduled);
    });

    test('event status shims delegate to ExperienceEventStatusRules', () {
      final now = DateTime(2026, 7, 10, 12);
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

      expect(
        computeEventStatus(event, now: now),
        ExperienceEventStatusRules.compute(
          isActive: event.isActive,
          startDateTime: event.startDateTime,
          endDateTime: event.endDateTime,
          now: now,
        ),
      );
      expect(computeEventStatus(event, now: now), EventStatus.draft);
    });
  });
}
