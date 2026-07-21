import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/core/constants/app_strings.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_context.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_tab.dart';
import 'package:nightlife_web/features/venue_management/models/venue_profile_completion.dart';
import 'package:nightlife_web/features/venue_management/widgets/trails/venue_trails_management_page.dart';
import 'package:nightlife_web/features/venue_management/widgets/trails/venue_trails_presentation.dart';
import 'package:nightlife_web/features/venue_management/widgets/venue_dashboard_controller.dart';
import 'package:nightlife_web/features/venue_management/widgets/venue_dashboard_shell.dart';

import 'venue_dashboard_test_data.dart';
import 'venue_management_activity_test_support.dart';

void main() {
  registerDefaultVenueManagementActivityTestIsolation();

  group('VenueTrailActionResolver', () {
    test('already included trails do not expose an active join action', () {
      final action = VenueTrailActionResolver.discoveryJoinAction(
        VenueTrailVenueState.alreadyIncluded,
      );

      expect(action.label, 'Already Included');
      expect(action.enabled, isFalse);
    });

    test('eligible trails expose join action', () {
      final discovery = VenueTrailActionResolver.discoveryJoinAction(
        VenueTrailVenueState.eligible,
      );
      final opportunity = VenueTrailActionResolver.opportunityAction(
        VenueTrailVenueState.eligible,
      );

      expect(discovery.label, 'Join Trail');
      expect(discovery.enabled, isTrue);
      expect(discovery.useFilledStyle, isTrue);
      expect(opportunity.label, 'Request to Join');
      expect(opportunity.enabled, isTrue);
    });

    test('ineligible trails do not expose an active join action', () {
      final action = VenueTrailActionResolver.discoveryJoinAction(
        VenueTrailVenueState.notEligible,
      );

      expect(action.label, 'Not Eligible');
      expect(action.enabled, isFalse);
    });

    test('pending requests expose view request instead of a new request', () {
      final action = VenueTrailActionResolver.opportunityAction(
        VenueTrailVenueState.requestPending,
      );

      expect(action.label, 'View Request');
      expect(action.enabled, isTrue);
    });
  });

  group('VenueTrailsPresentation', () {
    test('profile callout shows only for incomplete profiles', () {
      expect(
        VenueTrailsPresentation.shouldShowProfileReadinessCallout(
          const VenueProfileCompletion(completedSteps: 10, totalSteps: 10),
        ),
        isFalse,
      );
      expect(
        VenueTrailsPresentation.shouldShowProfileReadinessCallout(
          const VenueProfileCompletion(completedSteps: 7, totalSteps: 10),
        ),
        isTrue,
      );
    });
  });

  group('VenueTrailsManagementPage', () {
    Future<void> pumpTrailsShell(
      WidgetTester tester, {
      VenueProfileCompletion? profileCompletion,
      Size size = const Size(1440, 2400),
    }) async {
      tester.view.physicalSize = size;
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
            homeData: VenueDashboardTestData.sampleHomeData(
              completion: profileCompletion,
            ),
            initialTab: VenueDashboardTab.trails,
            trailsTabOverride: VenueTrailsManagementPage(
              profileCompletion: profileCompletion,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> pumpTrailsPage(
      WidgetTester tester, {
      List<VenueTrailDiscoveryItem>? discoveryTrails,
      List<VenueTrailParticipationItem>? participationTrails,
      List<VenueTrailOpportunityItem>? opportunityTrails,
      VenueProfileCompletion? profileCompletion,
      Size size = const Size(1440, 2400),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: SingleChildScrollView(
            child: VenueDashboardController(
              selectTab: (_, {pendingActionKey}) {},
              contextData: const VenueDashboardContext(
                ownerName: 'Alex Morgan',
                ownerFirstName: 'Alex',
                venueName: 'Copper Lantern',
                venueId: 'venue-copper-lantern',
              ),
              homeData: VenueDashboardTestData.sampleHomeData(
                completion: profileCompletion,
              ),
              child: VenueTrailsManagementPage(
                discoveryTrails: discoveryTrails,
                participationTrails: participationTrails,
                opportunityTrails: opportunityTrails,
                profileCompletion: profileCompletion,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders redesigned sections from existing sample data', (
      WidgetTester tester,
    ) async {
      await pumpTrailsShell(tester);

      expect(find.text('Trails Near You'), findsOneWidget);
      expect(find.text('My Trail Participation'), findsOneWidget);
      expect(find.text('Trail Opportunities'), findsOneWidget);
      expect(find.text('Manchester Cocktail Trail'), findsWidgets);
      expect(find.text('Northern Quarter Night Out'), findsWidgets);
      expect(
        find.text(
          'Join local trails, increase exposure and attract more customers.',
        ),
        findsOneWidget,
      );
      expect(find.text('Learn about Trails'), findsOneWidget);
      expect(find.text('Trail Readiness Checklist'), findsNothing);
    });

    testWidgets('already included discovery card disables join action', (
      WidgetTester tester,
    ) async {
      await pumpTrailsShell(tester);

      expect(find.text('Already Included'), findsOneWidget);
      final joinButton = find.widgetWithText(
        OutlinedButton,
        'Already Included',
      );
      final button = tester.widget<OutlinedButton>(joinButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('eligible discovery card exposes join trail action', (
      WidgetTester tester,
    ) async {
      await pumpTrailsShell(tester);

      expect(find.text('Join Trail'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is InkWell && widget.onTap != null,
        ),
        findsWidgets,
      );
    });

    testWidgets('participation empty state renders when no items exist', (
      WidgetTester tester,
    ) async {
      await pumpTrailsPage(tester, participationTrails: const []);

      expect(
        find.text(
          'Joined and approved trails will appear here once your venue is part of a route.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('profile callout routes to venue profile tab', (
      WidgetTester tester,
    ) async {
      await pumpTrailsShell(
        tester,
        profileCompletion: const VenueProfileCompletion(
          completedSteps: 6,
          totalSteps: 10,
        ),
      );

      expect(
        find.text(
          'Complete your venue profile to improve your trail eligibility.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text(AppStrings.venueDashboardImproveProfile));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Venue Profile'), findsWidgets);
    });

    testWidgets('hides profile callout when profile is complete', (
      WidgetTester tester,
    ) async {
      await pumpTrailsShell(
        tester,
        profileCompletion: const VenueProfileCompletion(
          completedSteps: 10,
          totalSteps: 10,
        ),
      );

      expect(
        find.text(
          'Complete your venue profile to improve your trail eligibility.',
        ),
        findsNothing,
      );
    });

    testWidgets('opportunity rows show state-specific actions', (
      WidgetTester tester,
    ) async {
      await pumpTrailsShell(tester);

      expect(
        find.widgetWithText(OutlinedButton, 'Request to Join'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(OutlinedButton, 'Request Access'),
        findsWidgets,
      );
      expect(
        find.widgetWithText(OutlinedButton, 'View Request'),
        findsOneWidget,
      );

      final notEligibleButtons = find.widgetWithText(
        OutlinedButton,
        'Not Eligible',
      );
      expect(notEligibleButtons, findsWidgets);
      for (final element in notEligibleButtons.evaluate()) {
        final button = element.widget as OutlinedButton;
        expect(button.onPressed, isNull);
      }
    });

    testWidgets('mobile layout keeps trails content readable', (
      WidgetTester tester,
    ) async {
      await pumpTrailsPage(tester, size: const Size(390, 2400));

      expect(find.text('Trails Near You'), findsOneWidget);
      expect(find.text('My Trail Participation'), findsOneWidget);
      expect(
        find.byKey(const Key('venue-trails-near-you-list')),
        findsOneWidget,
      );
    });

    testWidgets('sidebar and quick actions remain present on trails tab', (
      WidgetTester tester,
    ) async {
      await pumpTrailsShell(tester);

      expect(find.text(VenueDashboardTab.trails.label), findsWidgets);
      expect(
        find.text(AppStrings.venueDashboardQuickActionsTitle),
        findsOneWidget,
      );
      expect(find.text('View Public Profile'), findsWidgets);
      expect(find.text('Improve Venue Profile'), findsOneWidget);
      expect(find.text('Contact Support'), findsWidgets);
    });
  });
}
