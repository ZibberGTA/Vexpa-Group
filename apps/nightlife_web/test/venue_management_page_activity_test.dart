import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/core/constants/app_strings.dart';
import 'package:nightlife_web/features/venue_management/data/venue_management_activity_repository.dart';
import 'package:nightlife_web/features/venue_management/data/venue_management_activity_service.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_context.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_tab.dart';
import 'package:nightlife_web/features/venue_management/models/venue_management_activity.dart';
import 'package:nightlife_web/features/venue_management/models/venue_management_activity_types.dart';
import 'package:nightlife_web/features/venue_management/presentation/venue_management_activity_presentation_mapper.dart';
import 'package:nightlife_web/features/venue_management/widgets/page/venue_dashboard_page_scaffold.dart';
import 'package:nightlife_web/features/venue_management/widgets/venue_dashboard_controller.dart';

void main() {
  const contextData = VenueDashboardContext(
    ownerName: 'Alex Morgan',
    ownerFirstName: 'Alex',
    venueName: 'Copper Lantern',
    venueId: 'venue-copper-lantern',
  );

  group('VenueDashboardPageScaffold canonical activity', () {
    Future<void> pumpScaffold(
      WidgetTester tester, {
      required Widget child,
    }) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: SingleChildScrollView(
            child: child,
          ),
        ),
      );
    }

    testWidgets('loads source-scoped activity for drinks page', (tester) async {
      final repository = InMemoryVenueManagementActivityRepository();
      final service = DefaultVenueManagementActivityService(
        repository: repository,
      );

      await repository.append(
        VenueManagementActivity(
          venueId: contextData.venueId,
          sourceArea: VenueManagementActivitySourceAreas.drinks,
          actionType: VenueManagementActivityActionTypes.created,
          entityType: VenueManagementActivityEntityTypes.drink,
          entityId: 'drink-1',
          entityName: 'Negroni',
          description: 'Drink created',
          actorUid: 'owner-1',
          occurredAt: DateTime(2026, 7, 18, 12),
        ),
      );

      await pumpScaffold(
        tester,
        child: VenueDashboardController(
          selectTab: (_, {pendingActionKey}) {},
          contextData: contextData,
          child: VenueDashboardPageScaffold(
            tab: VenueDashboardTab.drinks,
            activityService: service,
            activityPresentationMapper:
                VenueManagementActivityPresentationMapper(
              now: DateTime(2026, 7, 18, 12, 5),
            ),
            mainContent: const SizedBox(height: 400),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Drink added'), findsOneWidget);
      expect(find.text('"Negroni" was added'), findsOneWidget);
    });

    testWidgets('shows empty state when no canonical drinks activity exists', (
      tester,
    ) async {
      final service = DefaultVenueManagementActivityService(
        repository: InMemoryVenueManagementActivityRepository(),
      );

      await pumpScaffold(
        tester,
        child: VenueDashboardController(
          selectTab: (_, {pendingActionKey}) {},
          contextData: contextData,
          child: VenueDashboardPageScaffold(
            tab: VenueDashboardTab.drinks,
            activityService: service,
            mainContent: const SizedBox(height: 400),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.venueDashboardRecentActivityEmptyTitle),
        findsOneWidget,
      );
    });

    testWidgets('shows loading state before source activity resolves', (
      tester,
    ) async {
      final repository = _DelayedActivityRepository();
      final service = DefaultVenueManagementActivityService(
        repository: repository,
      );

      await pumpScaffold(
        tester,
        child: VenueDashboardController(
          selectTab: (_, {pendingActionKey}) {},
          contextData: contextData,
          child: VenueDashboardPageScaffold(
            tab: VenueDashboardTab.deals,
            activityService: service,
            mainContent: const SizedBox(height: 400),
          ),
        ),
      );

      await tester.pump();

      expect(find.byKey(const Key('recent-activity-loading')), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 600));
    });
  });
}

class _DelayedActivityRepository extends InMemoryVenueManagementActivityRepository {
  @override
  Future<List<VenueManagementActivity>> fetchRecentForSourceArea({
    required String venueId,
    required String sourceArea,
    int limit = 10,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return super.fetchRecentForSourceArea(
      venueId: venueId,
      sourceArea: sourceArea,
      limit: limit,
    );
  }
}
