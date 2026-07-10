import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/core/constants/app_strings.dart';
import 'package:nightlife_web/core/routing/app_router.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_context.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_tab.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_tab_content.dart';
import 'package:nightlife_web/features/venue_management/widgets/venue_dashboard_shell.dart';
import 'package:nightlife_web/features/venue_management/widgets/venue_dashboard_top_bar.dart';

import 'venue_dashboard_test_data.dart';

void main() {
  testWidgets('Venue dashboard shell renders top bar, sidebar tabs and real empty analytics', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: VenueDashboardShell(
          contextData: const VenueDashboardContext(
            ownerName: 'Alex Morgan',
            ownerFirstName: 'Alex',
            venueName: 'Copper Lantern',
            venueId: 'venue-copper-lantern',
            unreadNotifications: 0,
          ),
          homeData: VenueDashboardTestData.sampleHomeData(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Welcome back, Alex'), findsOneWidget);
    expect(find.text(AppStrings.venueDashboardWelcomeSubtitle), findsOneWidget);
    expect(find.text('Profile Views'), findsOneWidget);
    expect(find.text('Saves'), findsOneWidget);
    expect(find.text('Drink Views'), findsOneWidget);
    expect(find.text('Deal Views'), findsOneWidget);
    expect(find.text('Event Views'), findsOneWidget);
    expect(find.text('0'), findsWidgets);
    expect(find.text('No data yet'), findsWidgets);
    expect(find.text(AppStrings.venueDashboardProfileViewsTitle), findsOneWidget);
    expect(find.text(AppStrings.venueDashboardProfileCompletionTitle), findsOneWidget);
    expect(find.text('70%'), findsOneWidget);
    expect(find.text('7 out of 10 steps completed'), findsOneWidget);
    expect(find.text(AppStrings.venueDashboardImproveProfile), findsOneWidget);
    expect(find.text(AppStrings.venueDashboardPerformanceHighlightsTitle), findsOneWidget);
    expect(find.text(AppStrings.venueDashboardWhatsNextTitle), findsOneWidget);
    expect(find.text(AppStrings.venueDashboardWhatsNextSubtitle), findsOneWidget);
    expect(find.text('Add more photos to improve visibility.'), findsOneWidget);
    expect(find.text('Add Photos'), findsOneWidget);
    expect(find.text('Create deal'), findsOneWidget);
    expect(find.text(AppStrings.viewPublicProfile), findsOneWidget);
    expect(find.text('Alex Morgan'), findsOneWidget);
    expect(find.text('Copper Lantern'), findsWidgets);
    expect(find.text(VenueDashboardTab.map.label), findsOneWidget);
    expect(find.text(VenueDashboardTab.marketing.label), findsOneWidget);
    expect(find.text(VenueDashboardTab.support.label), findsOneWidget);
    expect(find.text(AppStrings.venueDashboardQuickActionsTitle), findsOneWidget);
    expect(find.text(AppStrings.venueDashboardRecentActivityTitle), findsOneWidget);
    expect(find.text('Venue profile updated'), findsOneWidget);
    expect(find.text(AppStrings.venueDashboardGoPremiumTitle), findsOneWidget);
    expect(find.text(AppStrings.venueDashboardUpgradePlan), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();

    expect(find.text(VenueDashboardTab.dashboard.label), findsNothing);
  });

  testWidgets('Venue header does not include global search field', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: VenueDashboardShell(
          contextData: const VenueDashboardContext(
            ownerName: 'Alex Morgan',
            ownerFirstName: 'Alex',
            venueName: 'Copper Lantern',
            venueId: 'venue-copper-lantern',
          ),
          homeData: VenueDashboardTestData.sampleHomeData(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(VenueDashboardTopBar),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.hintText ==
                  AppStrings.venueDashboardSearchPlaceholder,
        ),
      ),
      findsNothing,
    );
  });

  testWidgets('Sidebar edge toggle is attached to the navigation panel', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: VenueDashboardShell(
          contextData: VenueDashboardContext.placeholder(),
          homeData: VenueDashboardTestData.sampleHomeData(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final toggleFinder = find.byIcon(Icons.chevron_left_rounded);
    expect(toggleFinder, findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(VenueDashboardTopBar),
        matching: toggleFinder,
      ),
      findsNothing,
    );
  });

  testWidgets('Sidebar navigation switches tab content within shell', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: VenueDashboardShell(
          contextData: VenueDashboardContext.placeholder(),
          homeData: VenueDashboardTestData.sampleHomeData(),
        ),
        onGenerateRoute: (settings) {
          if (settings.name == AppRouter.map) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const Scaffold(
                body: Text('Public Map Screen'),
              ),
            );
          }
          return null;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Welcome back'), findsOneWidget);

    await tester.tap(find.text(VenueDashboardTab.map.label).last);
    await tester.pumpAndSettle();

    expect(find.text('Public Map Screen'), findsOneWidget);

    Navigator.of(tester.element(find.text('Public Map Screen'))).pop();
    await tester.pumpAndSettle();

    expect(find.textContaining('Welcome back'), findsOneWidget);

    await tester.tap(find.text(VenueDashboardTab.drinks.label).last);
    await tester.pumpAndSettle();

    expect(find.text('Drinks Menu'), findsOneWidget);
    expect(find.text('Total drinks'), findsOneWidget);
    expect(find.text('No drinks added yet.'), findsOneWidget);

    await tester.tap(find.text(VenueDashboardTab.dashboard.label).last);
    await tester.pumpAndSettle();

    expect(find.textContaining('Welcome back'), findsOneWidget);
  });

  test('Venue dashboard tabs include all required sections', () {
    expect(VenueDashboardTab.values.length, 15);
    expect(VenueDashboardTab.values.first.label, 'Dashboard');
    expect(VenueDashboardTab.values[1].label, 'Map');
    expect(VenueDashboardTab.values[12].label, 'Marketing');
    expect(VenueDashboardTab.values[13].label, 'Support');
    expect(VenueDashboardTab.values.last.label, 'Settings');
  });

  test('Tab route segments resolve for deep links', () {
    expect(
      VenueDashboardTabPageCopyX.fromRouteSegment('map'),
      VenueDashboardTab.map,
    );
    expect(
      VenueDashboardTabPageCopyX.fromRouteSegment('profile'),
      VenueDashboardTab.venueProfile,
    );
    expect(
      VenueDashboardTabPageCopyX.fromRouteSegment('support'),
      VenueDashboardTab.support,
    );
    expect(VenueDashboardTab.map.opensPublicMap, isTrue);
  });

  testWidgets('Performance highlight CTA routes to dashboard tab', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: VenueDashboardShell(
          contextData: VenueDashboardContext.placeholder(),
          homeData: VenueDashboardTestData.sampleHomeData(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Create Deal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create Deal'));
    await tester.pumpAndSettle();

    expect(find.text('Deal Pipeline'), findsOneWidget);
    expect(find.text('Deal published'), findsOneWidget);
  });

  testWidgets('What\'s Next CTA routes to dashboard tab', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: VenueDashboardShell(
          contextData: VenueDashboardContext.placeholder(),
          homeData: VenueDashboardTestData.sampleHomeData(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Create deal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create deal'));
    await tester.pumpAndSettle();

    expect(find.text('Deal Pipeline'), findsOneWidget);
  });
}
