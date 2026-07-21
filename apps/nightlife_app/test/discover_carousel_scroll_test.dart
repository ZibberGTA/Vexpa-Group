import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_app/features/discover/models/discover_models.dart';
import 'package:nightlife_app/features/discover/utils/discover_carousel_scroll.dart';

void main() {
  group('DiscoverCarouselScroll', () {
    const results = [
      DiscoverVenueResult(venueId: 'v1', venueName: 'One', venueData: {}),
      DiscoverVenueResult(venueId: 'v2', venueName: 'Two', venueData: {}),
      DiscoverVenueResult(venueId: 'v3', venueName: 'Three', venueData: {}),
    ];

    test('indexForVenueId resolves matching index', () {
      expect(DiscoverCarouselScroll.indexForVenueId(results, 'v2'), 1);
    });

    test('indexForVenueId returns null for missing venue', () {
      expect(
        DiscoverCarouselScroll.indexForVenueId(results, 'missing'),
        isNull,
      );
    });

    test('scrollOffsetForIndex excludes outer viewport inset', () {
      const cardWidth = 176.0;
      expect(
        DiscoverCarouselScroll.scrollOffsetForIndex(
          index: 0,
          cardWidth: cardWidth,
        ),
        0,
      );
      expect(
        DiscoverCarouselScroll.scrollOffsetForIndex(
          index: 1,
          cardWidth: cardWidth,
        ),
        cardWidth + DiscoverCarouselScroll.cardSpacing,
      );
      expect(
        DiscoverCarouselScroll.scrollOffsetForIndex(
          index: 2,
          cardWidth: cardWidth,
        ),
        2 * (cardWidth + DiscoverCarouselScroll.cardSpacing),
      );
    });

    test('panelContentPadding matches shared gutter token', () {
      expect(DiscoverCarouselScroll.panelContentPadding, 16);
      expect(
        DiscoverCarouselScroll.listPadding,
        DiscoverCarouselScroll.panelContentPadding,
      );
    });

    test('clampIndex and clampScrollOffset stay within bounds', () {
      expect(DiscoverCarouselScroll.clampIndex(4, results.length), 2);
      expect(
        DiscoverCarouselScroll.clampScrollOffset(
          offset: 500,
          maxScrollExtent: 120,
        ),
        120,
      );
    });
  });
}
