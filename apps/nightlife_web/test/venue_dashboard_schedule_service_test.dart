import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/core/constants/app_strings.dart';
import 'package:nightlife_web/features/venue/data/models/deal_model.dart';
import 'package:nightlife_web/features/venue/data/models/event_model.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_context.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_schedule.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_tab.dart';
import 'package:nightlife_web/features/venue_management/presentation/venue_dashboard_schedule_presentation.dart';
import 'package:nightlife_web/features/venue_management/services/venue_dashboard_schedule_service.dart';
import 'package:nightlife_web/features/venue_management/widgets/venue_dashboard_controller.dart';
import 'package:nightlife_web/features/venue_management/widgets/venue_dashboard_next_seven_days_section.dart';

import 'venue_dashboard_test_data.dart';

void main() {
  final service = VenueDashboardScheduleService();
  final now = DateTime(2026, 7, 16, 12); // Thursday

  EventModel buildEvent({
    required String id,
    required String title,
    required DateTime start,
    DateTime? end,
    bool isActive = true,
    bool isDeleted = false,
  }) {
    return EventModel(
      id: id,
      venueId: 'venue-1',
      title: title,
      description: '',
      startDateTime: start,
      endDateTime: end ?? start.add(const Duration(hours: 4)),
      createdAt: now,
      category: 'General',
      imageUrl: '',
      isDeleted: isDeleted,
      isActive: isActive,
    );
  }

  DealModel buildDeal({
    required String id,
    required String title,
    List<String> availableDays = const [],
    String startTime = '',
    String endTime = '',
    DateTime? startDateTime,
    DateTime? endDateTime,
    bool isActive = true,
    bool isDeleted = false,
  }) {
    return DealModel(
      id: id,
      venueId: 'venue-1',
      title: title,
      description: '',
      availableDays: availableDays,
      startTime: startTime,
      endTime: endTime,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      isActive: isActive,
      isDeleted: isDeleted,
    );
  }

  group('VenueDashboardScheduleService', () {
    test('always renders seven rolling days beginning today', () {
      final schedule = service.compose(events: const [], deals: const [], now: now);

      expect(schedule.days, hasLength(7));
      expect(schedule.days.first.dayName, 'Thursday');
      expect(schedule.days.first.isToday, isTrue);
      expect(schedule.days[1].isToday, isFalse);
      expect(schedule.days.last.dayName, 'Wednesday');
    });

    test('renders published events with title and 24-hour range', () {
      final schedule = service.compose(
        events: [
          buildEvent(
            id: 'event-1',
            title: 'Live DJ Night',
            start: DateTime(2026, 7, 16, 20),
            end: DateTime(2026, 7, 17),
          ),
        ],
        deals: const [],
        now: now,
      );

      final item = schedule.days.first.items.single;
      expect(item.title, 'Live DJ Night');
      expect(item.timeLabel, '20:00 – 00:00');
      expect(item.activityType, VenueDashboardScheduleActivityType.event);
    });

    test('renders active deals with 24-hour time ranges', () {
      final schedule = service.compose(
        events: const [],
        deals: [
          buildDeal(
            id: 'deal-1',
            title: 'Happy Hour',
            availableDays: const ['Thursday'],
            startTime: '17:00',
            endTime: '19:00',
          ),
        ],
        now: now,
      );

      final item = schedule.days.first.items.single;
      expect(item.title, 'Happy Hour');
      expect(item.timeLabel, '17:00 – 19:00');
    });

    test('sorts activities by start time within a day', () {
      final schedule = service.compose(
        events: [
          buildEvent(
            id: 'late',
            title: 'Late Set',
            start: DateTime(2026, 7, 16, 21),
          ),
          buildEvent(
            id: 'early',
            title: 'Early Set',
            start: DateTime(2026, 7, 16, 18),
          ),
        ],
        deals: const [],
        now: now,
      );

      expect(
        schedule.days.first.items.map((item) => item.title).toList(),
        ['Early Set', 'Late Set'],
      );
    });

    test('excludes draft events and inactive deals', () {
      final schedule = service.compose(
        events: [
          buildEvent(
            id: 'draft',
            title: 'Draft Event',
            start: DateTime(2026, 7, 16, 20),
            isActive: false,
          ),
        ],
        deals: [
          buildDeal(
            id: 'paused',
            title: 'Paused Deal',
            availableDays: const ['Thursday'],
            startTime: '17:00',
            endTime: '19:00',
            isActive: false,
          ),
        ],
        now: now,
      );

      expect(schedule.days.first.items, isEmpty);
    });

    test('uses All Day when event has no explicit start time', () {
      final schedule = service.compose(
        events: [
          buildEvent(
            id: 'all-day',
            title: 'Summer Party',
            start: DateTime(2026, 7, 17),
          ),
        ],
        deals: const [],
        now: now,
      );

      final friday = schedule.days[1];
      expect(friday.items.single.title, 'Summer Party');
      expect(friday.items.single.timeLabel, 'All Day');
    });
  });

  group('VenueDashboardSchedulePresentation', () {
    test('bullet colour selection is deterministic', () {
      final item = VenueDashboardScheduleItem(
        id: 'deal-1',
        activityType: VenueDashboardScheduleActivityType.deal,
        title: 'Happy Hour',
        timeLabel: '17:00 – 19:00',
        sortAt: DateTime(2026, 7, 16, 17),
      );

      final first = VenueDashboardSchedulePresentation.bulletColorForItem(item);
      final second = VenueDashboardSchedulePresentation.bulletColorForItem(item);

      expect(first, second);
    });
  });

  group('VenueDashboardNextSevenDaysSection', () {
    VenueDashboardTab? selectedTab;

    Future<void> pumpSection(
      WidgetTester tester, {
      required VenueDashboardSchedule schedule,
      double width = 1440,
      bool loading = false,
    }) async {
      selectedTab = null;
      tester.view.physicalSize = Size(width, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: VenueDashboardController(
            selectTab: (tab, {pendingActionKey}) {
              selectedTab = tab;
            },
            contextData: const VenueDashboardContext(
              ownerName: 'Alex Morgan',
              ownerFirstName: 'Alex',
              venueName: 'Copper Lantern',
              venueId: 'venue-1',
            ),
            homeData: VenueDashboardTestData.sampleHomeData(now: now),
            child: Scaffold(
              body: SingleChildScrollView(
                child: VenueDashboardNextSevenDaysSection(
                  schedule: schedule,
                  loading: loading,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders header, seven cards, divider and empty state', (
      tester,
    ) async {
      final schedule = service.compose(events: const [], deals: const [], now: now);

      await pumpSection(tester, schedule: schedule);

      expect(find.text(AppStrings.venueDashboardNextSevenDaysTitle), findsOneWidget);
      expect(find.text(AppStrings.venueDashboardNextSevenDaysSubtitle), findsOneWidget);
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('THURSDAY'), findsOneWidget);
      expect(find.text('WEDNESDAY'), findsOneWidget);
      expect(find.byType(Divider), findsWidgets);
      expect(find.text(VenueDashboardSchedule.emptyDayMessage), findsNWidgets(7));
    });

    testWidgets('renders multiple activities and start/end times', (tester) async {
      final schedule = service.compose(
        events: [
          buildEvent(
            id: 'dj',
            title: 'Live DJ Night',
            start: DateTime(2026, 7, 16, 20),
            end: DateTime(2026, 7, 17),
          ),
        ],
        deals: [
          buildDeal(
            id: 'happy-hour',
            title: 'Happy Hour',
            availableDays: const ['Thursday'],
            startTime: '17:00',
            endTime: '19:00',
          ),
          buildDeal(
            id: 'cocktails',
            title: 'Cocktail Promotion',
            availableDays: const ['Thursday'],
            startTime: '21:00',
            endTime: '23:00',
          ),
        ],
        now: now,
      );

      await pumpSection(tester, schedule: schedule);

      expect(find.text('Happy Hour'), findsOneWidget);
      expect(find.text('Live DJ Night'), findsOneWidget);
      expect(find.text('Cocktail Promotion'), findsOneWidget);
      expect(find.text('17:00 – 19:00'), findsOneWidget);
      expect(find.text('20:00 – 00:00'), findsOneWidget);
      expect(find.text('21:00 – 23:00'), findsOneWidget);
    });

    testWidgets('View Full Calendar navigates to events tab', (tester) async {
      final schedule = service.compose(events: const [], deals: const [], now: now);
      await pumpSection(tester, schedule: schedule);

      await tester.tap(find.text(AppStrings.venueDashboardViewFullCalendar));
      await tester.pumpAndSettle();

      expect(selectedTab, VenueDashboardTab.events);
    });

    testWidgets('wraps cards on narrower layouts without horizontal overflow', (
      tester,
    ) async {
      final schedule = service.compose(
        events: [
          buildEvent(
            id: 'event-1',
            title: 'Summer Party',
            start: DateTime(2026, 7, 17, 19),
          ),
        ],
        deals: const [],
        now: now,
      );

      await pumpSection(tester, schedule: schedule, width: 640);

      expect(tester.takeException(), isNull);
      expect(find.text('FRIDAY'), findsOneWidget);
      expect(find.text('Summer Party'), findsOneWidget);
    });

    testWidgets('long titles wrap without overflow', (tester) async {
      final schedule = service.compose(
        events: [
          buildEvent(
            id: 'long-title',
            title:
                'An exceptionally long venue promotion title that should wrap cleanly',
            start: DateTime(2026, 7, 16, 18),
          ),
        ],
        deals: const [],
        now: now,
      );

      await pumpSection(tester, schedule: schedule, width: 360);

      expect(tester.takeException(), isNull);
      expect(
        find.textContaining('exceptionally long venue promotion'),
        findsOneWidget,
      );
    });
  });
}
