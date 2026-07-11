import 'package:test/test.dart';
import 'package:vex_engines/venue/application/venue_active_venue_selector.dart';
import 'package:vex_engines/venue/application/venue_activity_interpreter.dart';
import 'package:vex_engines/venue/application/venue_dashboard_composer.dart';
import 'package:vex_engines/venue/domain/venue_dashboard_models.dart';
import 'package:vex_engines/venue/domain/venue_profile_completion.dart';

void main() {
  const selector = VenueActiveVenueSelector();
  const whatsNextComposer = VenueWhatsNextComposer();
  const highlightComposer = VenueDashboardHighlightComposer();
  const setupHighlights = VenueDashboardSetupHighlights();
  const activityInterpreter = VenueActivityInterpreter();

  group('VenueActiveVenueSelector', () {
    test('prefers explicit preferred venue when accessible', () {
      expect(
        selector.selectVenueId(
          accessibleVenueIds: const ['a', 'b', 'c'],
          roleVenueIds: const ['b'],
          preferredVenueId: 'c',
        ),
        'c',
      );
    });

    test('falls back to role venue order', () {
      expect(
        selector.selectVenueId(
          accessibleVenueIds: const ['a', 'b'],
          roleVenueIds: const ['b', 'a'],
          preferredVenueId: 'missing',
        ),
        'b',
      );
    });

    test('returns null for empty venue list', () {
      expect(
        selector.selectVenueId(
          accessibleVenueIds: const [],
          roleVenueIds: const ['a'],
        ),
        isNull,
      );
    });
  });

  group('VenueWhatsNextComposer', () {
    test('orders setup guidance deterministically', () {
      final actions = whatsNextComposer.compose(
        venue: const VenueDashboardVenueSnapshot(
          venueId: 'venue-1',
          galleryImageCount: 0,
        ),
        profileCompletion: const VenueProfileCompletion(
          completedSteps: 7,
          totalSteps: 10,
        ),
        counts: const VenueDashboardContentCounts(
          drinkCount: 0,
          dealCount: 0,
          eventCount: 0,
          hasUpcomingEvent: false,
        ),
      );

      expect(actions, hasLength(4));
      expect(actions.first.title, 'Add more photos');
      expect(actions[1].title, 'Create a new deal');
      expect(actions[2].title, 'Add an upcoming event');
      expect(actions.last.title, 'Complete your profile');
    });

    test('omits completed setup steps', () {
      final actions = whatsNextComposer.compose(
        venue: const VenueDashboardVenueSnapshot(
          venueId: 'venue-1',
          galleryImageCount: 3,
        ),
        profileCompletion: const VenueProfileCompletion(
          completedSteps: 10,
          totalSteps: 10,
        ),
        counts: const VenueDashboardContentCounts(
          drinkCount: 2,
          dealCount: 1,
          eventCount: 1,
          hasUpcomingEvent: true,
        ),
      );

      expect(actions, isEmpty);
    });
  });

  group('VenueDashboardHighlightComposer', () {
    test('returns setup highlights when analytics unavailable', () {
      final highlights = highlightComposer.compose(analyticsAvailable: false);
      expect(highlights, setupHighlights.build());
    });

    test('fills remaining slots with setup guidance', () {
      final highlights = highlightComposer.compose(
        analyticsAvailable: true,
        analyticsHighlights: const [
          VenueDashboardHighlight(
            message: 'Analytics insight',
            buttonLabel: 'View Analytics',
            targetTabKey: VenueDashboardTabKey.analytics,
            accentKey: 'blue',
            iconKey: 'visibility_outlined',
          ),
        ],
      );

      expect(highlights, hasLength(4));
      expect(highlights.first.message, 'Analytics insight');
      expect(highlights[1].message, contains('photos'));
    });
  });

  group('VenueActivityInterpreter', () {
    test('interprets analytics drink view payload', () {
      final item = activityInterpreter.interpret(
        VenueActivitySourceEntry(
          occurredAt: DateTime(2026, 7, 10),
          source: 'analytics',
          timestampLabel: 'Yesterday',
          eventType: 'drink_view',
          payload: {'drinkName': 'Espresso Martini'},
        ),
      );

      expect(item?.title, 'Drink viewed: Espresso Martini');
      expect(item?.iconKey, 'local_bar_outlined');
    });

    test('interprets content event titles', () {
      final item = activityInterpreter.interpret(
        VenueActivitySourceEntry(
          occurredAt: DateTime(2026, 7, 10),
          source: 'content_event',
          timestampLabel: 'Yesterday',
          contentTitle: 'DJ Night',
        ),
      );

      expect(item?.title, 'Event added: DJ Night');
    });

    test('ignores unsupported analytics events', () {
      expect(
        activityInterpreter.interpret(
          VenueActivitySourceEntry(
            occurredAt: DateTime(2026, 7, 10),
            source: 'analytics',
            timestampLabel: 'Yesterday',
            eventType: 'unknown_event',
          ),
        ),
        isNull,
      );
    });
  });
}
