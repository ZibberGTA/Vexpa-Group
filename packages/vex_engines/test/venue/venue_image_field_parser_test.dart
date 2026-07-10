import 'package:test/test.dart';
import 'package:vex_engines/venue/shared/venue_image_field_parser.dart';

void main() {
  group('VenueImageFieldParser', () {
    test('prioritises bannerImageUrl over other banner fields', () {
      final url = VenueImageFieldParser.resolveBannerImageUrl({
        'bannerImageUrl': 'https://example.com/primary.jpg',
        'bannerUrl': 'https://example.com/fallback.jpg',
        'imageUrl': 'https://example.com/other.jpg',
      });

      expect(url, 'https://example.com/primary.jpg');
    });

    test('falls back through mobile banner field names', () {
      expect(
        VenueImageFieldParser.resolveBannerImageUrl({
          'bannerUrl': 'https://example.com/banner-url.jpg',
        }),
        'https://example.com/banner-url.jpg',
      );
      expect(
        VenueImageFieldParser.resolveBannerImageUrl({
          'coverImageUrl': 'https://example.com/cover.jpg',
        }),
        'https://example.com/cover.jpg',
      );
    });

    test('parses nested banner map values', () {
      final url = VenueImageFieldParser.resolveBannerImageUrl({
        'bannerImageUrl': {'url': 'https://example.com/nested.jpg'},
      });

      expect(url, 'https://example.com/nested.jpg');
    });

    test('accepts Firebase Storage download URLs', () {
      const storageUrl =
          'https://firebasestorage.googleapis.com/v0/b/demo/o/banner.jpg?alt=media&token=abc';

      expect(
        VenueImageFieldParser.resolveBannerImageUrl({
          'bannerImageUrl': storageUrl,
        }),
        storageUrl,
      );
    });

    test('rejects null, empty, and invalid banner values', () {
      expect(
        VenueImageFieldParser.resolveBannerImageUrl({
          'bannerImageUrl': null,
          'bannerUrl': '',
          'imageUrl': 'not-a-url',
        }),
        '',
      );
      expect(VenueImageFieldParser.resolveBannerImageUrl({}), '');
    });

    test('prioritises logoUrl over alternate logo fields', () {
      final url = VenueImageFieldParser.resolveLogoUrl({
        'logoUrl': 'https://example.com/logo-primary.png',
        'logoImageUrl': 'https://example.com/logo-alt.png',
      });

      expect(url, 'https://example.com/logo-primary.png');
    });

    test('resolves gallery image positions', () {
      final positions = VenueImageFieldParser.resolveGalleryImagePositions({
        'galleryImagePositions': {
          '0': {'focalPointX': 0.3, 'focalPointY': 0.7, 'scale': 1.5},
        },
      });

      expect(positions['0']?.focalPointX, 0.3);
      expect(positions['0']?.scale, 1.5);
    });
  });
}
