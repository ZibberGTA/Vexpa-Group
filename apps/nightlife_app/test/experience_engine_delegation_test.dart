import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_app/features/home/models/deal_model.dart';
import 'package:nightlife_app/features/home/models/event_model.dart';
import 'package:vex_engines/experience/application/experience_deal_visibility.dart';
import 'package:vex_engines/experience/application/experience_event_visibility.dart';

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
  });
}
