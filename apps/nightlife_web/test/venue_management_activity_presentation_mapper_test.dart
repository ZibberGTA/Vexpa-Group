import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/features/venue_management/models/venue_management_activity.dart';
import 'package:nightlife_web/features/venue_management/models/venue_management_activity_types.dart';
import 'package:nightlife_web/features/venue_management/presentation/venue_management_activity_presentation_mapper.dart';
import 'package:nightlife_web/features/venue_management/utils/venue_management_activity_relative_time.dart';

void main() {
  final referenceNow = DateTime(2026, 7, 18, 12, 0);
  final mapper = VenueManagementActivityPresentationMapper(now: referenceNow);

  VenueManagementActivity activity({
    required String sourceArea,
    required String actionType,
    String entityName = 'Espresso Martini',
    String? actorDisplayName,
    String description = 'Activity recorded',
    DateTime? occurredAt,
  }) {
    return VenueManagementActivity(
      venueId: 'venue-1',
      sourceArea: sourceArea,
      actionType: actionType,
      entityType: VenueManagementActivityEntityTypes.drink,
      entityId: 'entity-1',
      entityName: entityName,
      description: description,
      actorUid: 'user-1',
      actorDisplayName: actorDisplayName,
      occurredAt: occurredAt ?? referenceNow,
    );
  }

  group('VenueManagementActivityPresentationMapper', () {
    test('known drink create maps to Drink added title', () {
      final presentation = mapper.map(
        activity(
          sourceArea: VenueManagementActivitySourceAreas.drinks,
          actionType: VenueManagementActivityActionTypes.created,
        ),
      );

      expect(presentation.title, 'Drink added');
      expect(presentation.description, '"Espresso Martini" was added');
      expect(presentation.icon, Icons.local_bar_outlined);
    });

    test('update action maps correctly', () {
      final presentation = mapper.map(
        activity(
          sourceArea: VenueManagementActivitySourceAreas.deals,
          actionType: VenueManagementActivityActionTypes.updated,
          entityName: 'Friday Happy Hour',
        ),
      );

      expect(presentation.title, 'Deal updated');
      expect(presentation.description, '"Friday Happy Hour" was updated');
    });

    test('delete/remove action maps correctly', () {
      final presentation = mapper.map(
        activity(
          sourceArea: VenueManagementActivitySourceAreas.drinks,
          actionType: VenueManagementActivityActionTypes.archived,
        ),
      );

      expect(presentation.title, 'Drink removed');
      expect(presentation.description, '"Espresso Martini" was removed');
    });

    test('entity name appears when provided', () {
      final presentation = mapper.map(
        activity(
          sourceArea: VenueManagementActivitySourceAreas.events,
          actionType: VenueManagementActivityActionTypes.created,
          entityName: 'Friday DJ Night',
        ),
      );

      expect(presentation.description, '"Friday DJ Night" was added');
    });

    test('missing entity name uses safe fallback', () {
      final presentation = mapper.map(
        activity(
          sourceArea: VenueManagementActivitySourceAreas.drinks,
          actionType: VenueManagementActivityActionTypes.created,
          entityName: '',
        ),
      );

      expect(presentation.description, 'A drink was added');
    });

    test('actor display name appears when provided', () {
      final presentation = mapper.map(
        activity(
          sourceArea: VenueManagementActivitySourceAreas.drinks,
          actionType: VenueManagementActivityActionTypes.created,
          actorDisplayName: 'Jason',
        ),
      );

      expect(presentation.actorDisplayName, 'Jason');
      expect(presentation.metadataLine, 'Jason • Just now');
    });

    test('missing actor display name does not leave broken separators', () {
      final presentation = mapper.map(
        activity(
          sourceArea: VenueManagementActivitySourceAreas.venueProfile,
          actionType: VenueManagementActivityActionTypes.updated,
          entityName: 'Venue profile',
        ),
      );

      expect(presentation.actorDisplayName, isNull);
      expect(presentation.metadataLine, 'Just now');
      expect(presentation.metadataLine.contains('•'), isFalse);
    });

    test('unknown activity type uses generic fallback', () {
      final presentation = mapper.map(
        activity(
          sourceArea: 'unsupported_area',
          actionType: 'unsupported_action',
        ),
      );

      expect(presentation.title, 'Venue activity');
      expect(presentation.icon, Icons.history_outlined);
      expect(presentation.description, isNotNull);
    });
  });

  group('VenueManagementActivityRelativeTime', () {
    test('formats just now', () {
      expect(
        VenueManagementActivityRelativeTime.format(
          referenceNow.subtract(const Duration(seconds: 20)),
          now: referenceNow,
        ),
        'Just now',
      );
    });

    test('formats minutes', () {
      expect(
        VenueManagementActivityRelativeTime.format(
          referenceNow.subtract(const Duration(minutes: 10)),
          now: referenceNow,
        ),
        '10 minutes ago',
      );
    });

    test('formats hours', () {
      expect(
        VenueManagementActivityRelativeTime.format(
          referenceNow.subtract(const Duration(hours: 3)),
          now: referenceNow,
        ),
        '3 hours ago',
      );
    });

    test('formats yesterday', () {
      expect(
        VenueManagementActivityRelativeTime.format(
          referenceNow.subtract(const Duration(days: 1, hours: 2)),
          now: referenceNow,
        ),
        'Yesterday',
      );
    });

    test('formats weekday within seven days', () {
      expect(
        VenueManagementActivityRelativeTime.format(
          DateTime(2026, 7, 15, 9, 0),
          now: referenceNow,
        ),
        'Wednesday',
      );
    });

    test('formats older UK-style date', () {
      expect(
        VenueManagementActivityRelativeTime.format(
          DateTime(2026, 6, 12, 9, 0),
          now: referenceNow,
        ),
        '12 Jun 2026',
      );
    });
  });
}
