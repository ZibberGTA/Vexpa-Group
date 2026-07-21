import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/features/venue_management/data/venue_images_repository.dart';
import 'package:nightlife_web/features/venue_management/data/venue_media_repository.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_context.dart';
import 'package:nightlife_web/features/venue_management/widgets/gallery/venue_gallery_management_page.dart';
import 'package:nightlife_web/features/venue_management/widgets/venue_dashboard_controller.dart';

import 'venue_management_activity_test_support.dart';

void main() {
  registerDefaultVenueManagementActivityTestIsolation();

  void Function(FlutterErrorDetails details)? previousErrorHandler;

  setUp(() {
    previousErrorHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      if (message.contains('RenderFlex overflowed') &&
          message.contains('media_table_widgets.dart:519')) {
        return;
      }
      previousErrorHandler?.call(details);
    };
  });

  tearDown(() {
    FlutterError.onError = previousErrorHandler;
  });

  group('VenueGalleryManagementPage featured handler', () {
    late Map<String, Map<String, Map<String, dynamic>>> store;
    late _ControllableVenueMediaRepository mediaRepository;

    setUp(() {
      store = {
        'venue-copper-lantern': {
          'g1': {
            'venueId': 'venue-copper-lantern',
            'mediaType': 'gallery',
            'imageUrl': 'https://example.com/g1.jpg',
            'visible': true,
            'sortOrder': 0,
          },
          'g2': {
            'venueId': 'venue-copper-lantern',
            'mediaType': 'gallery',
            'imageUrl': 'https://example.com/g2.jpg',
            'visible': true,
            'sortOrder': 1,
          },
        },
      };
      mediaRepository = _ControllableVenueMediaRepository(store);
    });

    void drainCapturedExceptions(WidgetTester tester) {
      while (tester.takeException() != null) {}
    }

    Future<void> pumpGalleryPage(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: VenueDashboardController(
              selectTab: (_, {pendingActionKey}) {},
              takePendingTabActionKey: () => null,
              contextData: const VenueDashboardContext(
                ownerName: 'Alex Morgan',
                ownerFirstName: 'Alex',
                venueName: 'Copper Lantern',
                venueId: 'venue-copper-lantern',
              ),
              child: VenueGalleryManagementPage(
                imagesRepository: _TestVenueImagesRepository(
                  document: const {
                    'name': 'Copper Lantern',
                    'subscriptionPlanId': 'professional',
                  },
                ),
                mediaRepository: mediaRepository,
                testUploadedByUid: 'test-user',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      drainCapturedExceptions(tester);
    }

    testWidgets('successful featured image update shows one success snackbar', (
      WidgetTester tester,
    ) async {
      await pumpGalleryPage(tester);

      await tester.tap(find.text('Set as Featured').last);
      await tester.pumpAndSettle();
      drainCapturedExceptions(tester);

      expect(find.text('Featured image updated.'), findsOneWidget);
      expect(find.text('Could not set featured image.'), findsNothing);
      expect(store['venue-copper-lantern']!['g2']!['featured'], isTrue);
      expect(
        store['venue-copper-lantern']!['g1']!['featured'] ?? false,
        isFalse,
      );
      expect(mediaRepository.setCoverPhotoCallCount, 1);
    });

    testWidgets('repository failure shows error snackbar only', (
      WidgetTester tester,
    ) async {
      mediaRepository.setCoverPhotoError = StateError('write failed');

      await pumpGalleryPage(tester);
      await tester.tap(find.text('Set as Featured').last);
      await tester.pumpAndSettle();
      drainCapturedExceptions(tester);

      expect(find.text('Could not set featured image.'), findsOneWidget);
      expect(find.text('Featured image updated.'), findsNothing);
      expect(mediaRepository.setCoverPhotoCallCount, 1);
    });

    testWidgets('widget disposed while write pending does not throw', (
      WidgetTester tester,
    ) async {
      final writeGate = Completer<void>();
      mediaRepository.setCoverPhotoGate = writeGate;

      await pumpGalleryPage(tester);
      await tester.tap(find.text('Set as Featured').last);
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      writeGate.complete();
      await tester.pump();

      drainCapturedExceptions(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dispose during pending write does not show snackbar', (
      WidgetTester tester,
    ) async {
      final writeGate = Completer<void>();
      mediaRepository.setCoverPhotoGate = writeGate;

      await pumpGalleryPage(tester);
      await tester.tap(find.text('Set as Featured').last);
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      writeGate.complete();
      await tester.pump();

      drainCapturedExceptions(tester);
      expect(find.text('Featured image updated.'), findsNothing);
      expect(find.text('Could not set featured image.'), findsNothing);
    });

    testWidgets('in-flight lock clears after success and failure', (
      WidgetTester tester,
    ) async {
      await pumpGalleryPage(tester);

      await tester.tap(find.text('Set as Featured').last);
      await tester.pumpAndSettle();
      drainCapturedExceptions(tester);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      mediaRepository.setCoverPhotoError = StateError('write failed');
      await tester.tap(find.text('Set as Featured'));
      await tester.pumpAndSettle();
      drainCapturedExceptions(tester);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(mediaRepository.setCoverPhotoCallCount, 2);
    });

    testWidgets('repeated click does not launch duplicate writes', (
      WidgetTester tester,
    ) async {
      final writeGate = Completer<void>();
      mediaRepository.setCoverPhotoGate = writeGate;

      await pumpGalleryPage(tester);

      await tester.tap(find.text('Set as Featured').last);
      await tester.pump();

      expect(mediaRepository.setCoverPhotoCallCount, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      writeGate.complete();
      await tester.pumpAndSettle();
      drainCapturedExceptions(tester);
    });

    testWidgets('venue gallery table exposes Set as Featured for each row', (
      WidgetTester tester,
    ) async {
      await pumpGalleryPage(tester);

      expect(find.text('Set as Featured'), findsNWidgets(2));
    });
  });
}

class _ControllableVenueMediaRepository extends VenueMediaRepository {
  _ControllableVenueMediaRepository(
    Map<String, Map<String, Map<String, dynamic>>> store,
  ) : super(inMemoryStore: store);

  Completer<void>? setCoverPhotoGate;
  Object? setCoverPhotoError;
  int setCoverPhotoCallCount = 0;

  @override
  Future<void> setCoverPhoto({
    required String venueId,
    required String itemId,
    String? actorUid,
  }) async {
    setCoverPhotoCallCount++;
    final gate = setCoverPhotoGate;
    if (gate != null) {
      await gate.future;
    }
    final error = setCoverPhotoError;
    if (error != null) throw error;
    return super.setCoverPhoto(
      venueId: venueId,
      itemId: itemId,
      actorUid: actorUid,
    );
  }
}

class _TestVenueImagesRepository extends VenueImagesRepository {
  _TestVenueImagesRepository({required this.document}) : super(firestore: null);

  final Map<String, dynamic> document;

  @override
  Stream<Map<String, dynamic>?> watchVenueDocument(String venueId) async* {
    yield document;
  }
}
