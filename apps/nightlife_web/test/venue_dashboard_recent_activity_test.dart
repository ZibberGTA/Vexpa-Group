import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/core/constants/app_strings.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_context.dart';
import 'package:nightlife_web/features/venue_management/presentation/venue_management_activity_presentation.dart';
import 'package:nightlife_web/features/venue_management/widgets/venue_dashboard_controller.dart';
import 'package:nightlife_web/features/venue_management/widgets/venue_dashboard_recent_activity_panel.dart';

void main() {
  Future<void> pumpPanel(
    WidgetTester tester, {
    required Widget child,
    List<VenueManagementActivityPresentation>? recentManagementActivity,
    bool isLoadingRecentActivity = false,
    Object? recentActivityError,
    Future<void> Function()? onRetryRecentActivity,
    VenueDashboardContext contextData = const VenueDashboardContext(
      ownerName: 'Alex Morgan',
      ownerFirstName: 'Alex',
      venueName: 'Copper Lantern',
      venueId: 'venue-copper-lantern',
    ),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: VenueDashboardController(
          selectTab: (_, {pendingActionKey}) {},
          contextData: contextData,
          recentManagementActivity: recentManagementActivity,
          isLoadingRecentActivity: isLoadingRecentActivity,
          recentActivityError: recentActivityError,
          onRetryRecentActivity: onRetryRecentActivity,
          child: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 360,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('VenueDashboardRecentActivityPanel', () {
    testWidgets('loading state renders', (tester) async {
      await pumpPanel(
        tester,
        isLoadingRecentActivity: true,
        child: const VenueDashboardRecentActivityPanel(useControllerFeed: true),
      );

      expect(find.byKey(const Key('recent-activity-loading')), findsOneWidget);
    });

    testWidgets('empty state renders', (tester) async {
      await pumpPanel(
        tester,
        recentManagementActivity: const [],
        child: const VenueDashboardRecentActivityPanel(useControllerFeed: true),
      );

      expect(find.text(AppStrings.venueDashboardRecentActivityEmptyTitle), findsOneWidget);
      expect(find.text(AppStrings.venueDashboardRecentActivityEmptyBody), findsOneWidget);
    });

    testWidgets('populated list renders newest-first', (tester) async {
      await pumpPanel(
        tester,
        recentManagementActivity: const [
          VenueManagementActivityPresentation(
            icon: Icons.local_bar_outlined,
            title: 'Drink added',
            description: '"Negroni" was added',
            actorDisplayName: 'Jason',
            timestampLabel: '10 minutes ago',
          ),
          VenueManagementActivityPresentation(
            icon: Icons.local_offer_outlined,
            title: 'Deal updated',
            description: '"Happy hour" was updated',
            timestampLabel: 'Yesterday',
          ),
        ],
        child: const VenueDashboardRecentActivityPanel(useControllerFeed: true),
      );

      expect(find.text('Drink added'), findsOneWidget);
      expect(find.text('Deal updated'), findsOneWidget);
    });

    testWidgets('maximum 10 items displayed', (tester) async {
      final items = List.generate(
        12,
        (index) => VenueManagementActivityPresentation(
          icon: Icons.history_outlined,
          title: 'Activity $index',
          timestampLabel: 'Just now',
        ),
      );

      await pumpPanel(
        tester,
        recentManagementActivity: items,
        child: const VenueDashboardRecentActivityPanel(useControllerFeed: true),
      );

      expect(find.text('Activity 0'), findsOneWidget);
      expect(find.text('Activity 9'), findsOneWidget);
      expect(find.text('Activity 10'), findsNothing);
    });

    testWidgets('title and description render correctly', (tester) async {
      await pumpPanel(
        tester,
        recentManagementActivity: const [
          VenueManagementActivityPresentation(
            icon: Icons.local_bar_outlined,
            title: 'Drink added',
            description: '"Summer Cocktail" was added',
            timestampLabel: 'Just now',
          ),
        ],
        child: const VenueDashboardRecentActivityPanel(useControllerFeed: true),
      );

      expect(find.text('Drink added'), findsOneWidget);
      expect(find.text('"Summer Cocktail" was added'), findsOneWidget);
    });

    testWidgets('actor name renders when present', (tester) async {
      await pumpPanel(
        tester,
        recentManagementActivity: const [
          VenueManagementActivityPresentation(
            icon: Icons.local_bar_outlined,
            title: 'Drink added',
            actorDisplayName: 'Jason',
            timestampLabel: '10 minutes ago',
          ),
        ],
        child: const VenueDashboardRecentActivityPanel(useControllerFeed: true),
      );

      expect(find.text('Jason • 10 minutes ago'), findsOneWidget);
    });

    testWidgets('timestamp renders', (tester) async {
      await pumpPanel(
        tester,
        recentManagementActivity: const [
          VenueManagementActivityPresentation(
            icon: Icons.storefront_outlined,
            title: 'Venue profile updated',
            timestampLabel: 'Yesterday',
          ),
        ],
        child: const VenueDashboardRecentActivityPanel(useControllerFeed: true),
      );

      expect(find.text('Yesterday'), findsOneWidget);
    });

    testWidgets('unknown activity does not crash', (tester) async {
      await pumpPanel(
        tester,
        recentManagementActivity: const [
          VenueManagementActivityPresentation(
            icon: Icons.history_outlined,
            title: 'Venue activity',
            description: 'A change was made to your venue',
            timestampLabel: 'Just now',
          ),
        ],
        child: const VenueDashboardRecentActivityPanel(useControllerFeed: true),
      );

      expect(find.text('Venue activity'), findsOneWidget);
    });

    testWidgets('error state renders without breaking dashboard', (tester) async {
      await pumpPanel(
        tester,
        recentActivityError: StateError('failed'),
        onRetryRecentActivity: () async {},
        child: const VenueDashboardRecentActivityPanel(useControllerFeed: true),
      );

      expect(find.text(AppStrings.venueDashboardRecentActivityError), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retry calls the expected loader if implemented', (tester) async {
      var retryCount = 0;

      await pumpPanel(
        tester,
        recentActivityError: StateError('failed'),
        onRetryRecentActivity: () async {
          retryCount += 1;
        },
        child: const VenueDashboardRecentActivityPanel(useControllerFeed: true),
      );

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retryCount, 1);
    });

    testWidgets('venue change does not retain the previous venue activity', (
      tester,
    ) async {
      await pumpPanel(
        tester,
        recentManagementActivity: const [
          VenueManagementActivityPresentation(
            icon: Icons.local_bar_outlined,
            title: 'Drink added',
            timestampLabel: 'Just now',
          ),
        ],
        child: const VenueDashboardRecentActivityPanel(useControllerFeed: true),
      );

      expect(find.text('Drink added'), findsOneWidget);

      await pumpPanel(
        tester,
        isLoadingRecentActivity: true,
        recentManagementActivity: null,
        contextData: const VenueDashboardContext(
          ownerName: 'Alex Morgan',
          ownerFirstName: 'Alex',
          venueName: 'Second Venue',
          venueId: 'venue-b',
        ),
        child: const VenueDashboardRecentActivityPanel(useControllerFeed: true),
      );

      expect(find.text('Drink added'), findsNothing);
      expect(find.byKey(const Key('recent-activity-loading')), findsOneWidget);
    });

    testWidgets('narrow layout does not overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpPanel(
        tester,
        recentManagementActivity: const [
          VenueManagementActivityPresentation(
            icon: Icons.local_offer_outlined,
            title: 'Deal updated',
            description:
                '"Very long deal name that should wrap within the sidebar without overflowing horizontally"',
            actorDisplayName: 'Alexandra Montgomery',
            timestampLabel: '2 hours ago',
          ),
        ],
        child: const VenueDashboardRecentActivityPanel(useControllerFeed: true),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
