import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/features/venue_management/models/venue_media_item.dart';
import 'package:nightlife_web/features/venue_management/models/venue_media_type.dart';
import 'package:nightlife_web/features/venue_management/widgets/gallery/venue_gallery_preview_carousel.dart';

void main() {
  group('orderGalleryPreviewItems', () {
    VenueMediaItem item({
      required String id,
      int sortOrder = 0,
      bool featured = false,
      String status = 'active',
      bool visible = true,
    }) {
      return VenueMediaItem(
        id: id,
        venueId: 'venue-1',
        mediaType: VenueMediaType.gallery,
        imageUrl: 'https://example.com/$id.jpg',
        sortOrder: sortOrder,
        featured: featured,
        status: status,
        visible: visible,
      );
    }

    test('places featured image first without duplication', () {
      final ordered = orderGalleryPreviewItems([
        item(id: 'g1', sortOrder: 1),
        item(id: 'g2', sortOrder: 0, featured: true),
        item(id: 'g3', sortOrder: 2),
      ]);

      expect(ordered.map((entry) => entry.id), ['g2', 'g1', 'g3']);
      expect(ordered.where((entry) => entry.isCover), hasLength(1));
    });

    test('preserves relative order for non-featured images', () {
      final ordered = orderGalleryPreviewItems([
        item(id: 'g1', sortOrder: 0, featured: true),
        item(id: 'g2', sortOrder: 1),
        item(id: 'g3', sortOrder: 2),
      ]);

      expect(ordered.map((entry) => entry.id), ['g1', 'g2', 'g3']);
    });

    test('deduplicates repeated ids', () {
      final first = item(id: 'g1', sortOrder: 0, featured: true);
      final duplicate = item(id: 'g1', sortOrder: 0, featured: true);

      final ordered = orderGalleryPreviewItems([
        first,
        duplicate,
        item(id: 'g2'),
      ]);

      expect(ordered, hasLength(2));
      expect(ordered.first.id, 'g1');
    });
  });

  group('VenueGalleryPreviewCarousel', () {
    VenueMediaItem previewItem({
      required String id,
      int sortOrder = 0,
      bool featured = false,
      String imageUrl = 'https://example.com/photo.jpg',
    }) {
      return VenueMediaItem(
        id: id,
        venueId: 'venue-1',
        mediaType: VenueMediaType.gallery,
        imageUrl: imageUrl,
        sortOrder: sortOrder,
        featured: featured,
      );
    }

    Future<void> pumpCarousel(
      WidgetTester tester, {
      required List<VenueMediaItem> items,
      Size viewport = const Size(1280, 900),
    }) async {
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: viewport.width,
                child: VenueGalleryPreviewCarousel(items: items),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    double animatedOpacity(WidgetTester tester, Key key) {
      final opacityWidget = tester.widget<AnimatedOpacity>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      return opacityWidget.opacity;
    }

    testWidgets(
      'uses Venue Gallery Preview title and removes Featured Image panel',
      (WidgetTester tester) async {
        await pumpCarousel(
          tester,
          items: [previewItem(id: 'g1', featured: true)],
        );

        expect(find.text('Venue Gallery Preview'), findsOneWidget);
        expect(find.text('Featured Image'), findsNothing);
        expect(find.text('No featured image selected'), findsNothing);
      },
    );

    testWidgets('renders compact empty state when there are no images', (
      WidgetTester tester,
    ) async {
      await pumpCarousel(tester, items: const []);

      expect(
        find.text('Uploaded Venue Gallery images will appear here.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('venue-gallery-preview-list')), findsNothing);
    });

    testWidgets('renders separate horizontal cards for multiple images', (
      WidgetTester tester,
    ) async {
      await pumpCarousel(
        tester,
        items: [
          previewItem(id: 'g1', sortOrder: 0, featured: true),
          previewItem(id: 'g2', sortOrder: 1),
          previewItem(id: 'g3', sortOrder: 2),
          previewItem(id: 'g4', sortOrder: 3),
        ],
      );

      expect(find.byKey(const Key('gallery-preview-g1')), findsOneWidget);
      expect(find.byKey(const Key('gallery-preview-g2')), findsOneWidget);
      expect(find.byKey(const Key('gallery-preview-g3')), findsOneWidget);
      expect(find.byKey(const Key('gallery-preview-g4')), findsOneWidget);
      expect(find.text('Featured'), findsOneWidget);
    });

    testWidgets('featured card renders first and is labelled', (
      WidgetTester tester,
    ) async {
      await pumpCarousel(
        tester,
        items: [
          previewItem(id: 'g1', sortOrder: 1),
          previewItem(id: 'g2', sortOrder: 0, featured: true),
        ],
      );

      final g2Position = tester.getTopLeft(find.byKey(const Key('gallery-preview-g2')));
      final g1Position = tester.getTopLeft(find.byKey(const Key('gallery-preview-g1')));
      expect(g2Position.dx, lessThan(g1Position.dx));
      expect(find.text('Featured'), findsOneWidget);
    });

    testWidgets('single image keeps a normal card width', (
      WidgetTester tester,
    ) async {
      const viewport = Size(1280, 900);
      await pumpCarousel(
        tester,
        items: [previewItem(id: 'g1', featured: true)],
        viewport: viewport,
      );

      final cardSize = tester.getSize(
        find.byKey(const Key('gallery-preview-g1')),
      );
      expect(cardSize.width, lessThan(viewport.width * 0.5));
      expect(find.byKey(const Key('carousel-edge-fade-left')), findsNothing);
    });

    testWidgets('enables horizontal scrolling when content exceeds viewport', (
      WidgetTester tester,
    ) async {
      await pumpCarousel(
        tester,
        items: List.generate(
          6,
          (index) => previewItem(
            id: 'g$index',
            sortOrder: index,
            featured: index == 0,
          ),
        ),
        viewport: const Size(420, 900),
      );

      final controller = tester
          .widget<ListView>(find.byKey(const Key('venue-gallery-preview-list')))
          .controller!;
      expect(controller.position.maxScrollExtent, greaterThan(0));
    });

    testWidgets('updates edge fade visibility while scrolling', (
      WidgetTester tester,
    ) async {
      await pumpCarousel(
        tester,
        items: List.generate(
          6,
          (index) => previewItem(
            id: 'g$index',
            sortOrder: index,
            featured: index == 0,
          ),
        ),
        viewport: const Size(420, 900),
      );

      expect(animatedOpacity(tester, const Key('carousel-edge-fade-left')), 0);
      expect(animatedOpacity(tester, const Key('carousel-edge-fade-right')), 1);

      final controller = tester
          .widget<ListView>(find.byKey(const Key('venue-gallery-preview-list')))
          .controller!;
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pumpAndSettle();

      expect(animatedOpacity(tester, const Key('carousel-edge-fade-left')), 1);
      expect(animatedOpacity(tester, const Key('carousel-edge-fade-right')), 0);
    });

    testWidgets('edge fade overlays ignore pointer events', (
      WidgetTester tester,
    ) async {
      await pumpCarousel(
        tester,
        items: List.generate(
          5,
          (index) => previewItem(id: 'g$index', sortOrder: index),
        ),
        viewport: const Size(420, 900),
      );

      for (final key in [
        const Key('carousel-edge-fade-left'),
        const Key('carousel-edge-fade-right'),
      ]) {
        final ignorePointer = tester.widget<IgnorePointer>(
          find.descendant(
            of: find.byKey(key),
            matching: find.byType(IgnorePointer),
          ),
        );
        expect(ignorePointer.ignoring, isTrue);
      }
    });
  });
}
