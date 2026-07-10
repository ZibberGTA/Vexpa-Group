import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/features/venue/data/models/event_model.dart';
import 'package:nightlife_web/features/venue/data/venue_events_repository.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_context.dart';
import 'package:nightlife_web/features/venue_management/widgets/events/venue_events_management_page.dart';
import 'package:nightlife_web/features/venue_management/widgets/venue_dashboard_controller.dart';

class FakeVenueEventsRepository extends VenueEventsRepository {
  FakeVenueEventsRepository({List<EventModel>? initial})
      : _events = List.of(initial ?? []),
        _controller = StreamController<List<EventModel>>.broadcast(),
        super(firestore: null);

  final List<EventModel> _events;
  final StreamController<List<EventModel>> _controller;

  void seedEvent({
    required String title,
    String id = 'seed-event',
    bool isActive = true,
  }) {
    final now = DateTime.now();
    _events.add(
      EventModel(
        id: id,
        venueId: 'venue-test',
        title: title,
        description: '',
        startDateTime: now.add(const Duration(days: 2)),
        endDateTime: now.add(const Duration(days: 2, hours: 4)),
        createdAt: now,
        category: 'General',
        imageUrl: '',
        isDeleted: false,
        isActive: isActive,
      ),
    );
    _controller.add(List.unmodifiable(_events));
  }

  @override
  Stream<List<EventModel>> watchManagementEvents(String venueId) async* {
    yield List.unmodifiable(_events);
    yield* _controller.stream;
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  group('VenueEventsManagementPage quick actions', () {
    late FakeVenueEventsRepository repository;

    setUp(() {
      repository = FakeVenueEventsRepository();
    });

    tearDown(() {
      repository.dispose();
    });

    Future<void> pumpEventsPage(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 1100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: VenueDashboardController(
              selectTab: (_) {},
              contextData: const VenueDashboardContext(
                ownerName: 'Alex Morgan',
                ownerFirstName: 'Alex',
                venueName: 'Copper Lantern',
                venueId: 'venue-test',
              ),
              child: VenueEventsManagementPage(
                repository: repository,
                testUpdatedBy: 'owner-test',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows updated quick action labels', (WidgetTester tester) async {
      await pumpEventsPage(tester);

      expect(find.text('Add Event'), findsWidgets);
      expect(find.text('Duplicate Event'), findsOneWidget);
      expect(find.text('Export Events'), findsOneWidget);
      expect(find.text('Upload Event Banner'), findsOneWidget);
      expect(find.text('View Event Performance'), findsOneWidget);
      expect(find.text('Publish Event'), findsNothing);
      expect(find.text('Schedule Event'), findsNothing);
    });

    testWidgets('Upload Event Banner requires selection', (WidgetTester tester) async {
      await pumpEventsPage(tester);

      await tester.tap(find.text('Upload Event Banner'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Select an event to upload a banner.'), findsOneWidget);
    });
  });
}
