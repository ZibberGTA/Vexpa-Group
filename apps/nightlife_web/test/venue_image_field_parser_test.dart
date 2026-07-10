import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/features/venues/data/venue_image_field_parser.dart';
import 'package:nightlife_web/features/venues/models/venue_model.dart';

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
          'bannerImage': 'https://example.com/banner-image.jpg',
        }),
        'https://example.com/banner-image.jpg',
      );
      expect(
        VenueImageFieldParser.resolveBannerImageUrl({
          'coverImageUrl': 'https://example.com/cover.jpg',
        }),
        'https://example.com/cover.jpg',
      );
      expect(
        VenueImageFieldParser.resolveBannerImageUrl({
          'headerImageUrl': 'https://example.com/header.jpg',
        }),
        'https://example.com/header.jpg',
      );
      expect(
        VenueImageFieldParser.resolveBannerImageUrl({
          'imageUrl': 'https://example.com/image.jpg',
        }),
        'https://example.com/image.jpg',
      );
    });

    test('parses nested banner map values', () {
      final url = VenueImageFieldParser.resolveBannerImageUrl({
        'bannerImageUrl': {'url': 'https://example.com/nested.jpg'},
      });

      expect(url, 'https://example.com/nested.jpg');
    });

    test('uses mobile legacy image fields for banner fallback', () {
      expect(
        VenueImageFieldParser.resolveBannerImageUrl({
          'bannerImage': 'https://example.com/banner-image.jpg',
          'headerImageUrl': 'https://example.com/header.jpg',
          'imageUrl': 'https://example.com/gallery.jpg',
        }),
        'https://example.com/banner-image.jpg',
      );
    });

    test('accepts Firebase Storage download URLs', () {
      const storageUrl =
          'https://firebasestorage.googleapis.com/v0/b/demo/o/banner.jpg?alt=media&token=abc';
      const bucketHostUrl =
          'https://nightlife-app-19acd.firebasestorage.app/o/venues%2Fvenue%2Fmedia%2Fbanner.jpg?alt=media&token=abc';

      expect(
        VenueImageFieldParser.resolveBannerImageUrl({
          'bannerImageUrl': storageUrl,
        }),
        storageUrl,
      );
      expect(
        VenueImageFieldParser.resolveBannerImageUrl({
          'bannerImageUrl': bucketHostUrl,
        }),
        bucketHostUrl,
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
        'venueLogoUrl': 'https://example.com/logo-venue.png',
      });

      expect(url, 'https://example.com/logo-primary.png');
    });

    test('falls back through logo field names', () {
      expect(
        VenueImageFieldParser.resolveLogoUrl({
          'logoImageUrl': 'https://example.com/logo-image.png',
        }),
        'https://example.com/logo-image.png',
      );
      expect(
        VenueImageFieldParser.resolveLogoUrl({
          'venueLogoUrl': 'https://example.com/venue-logo.png',
        }),
        'https://example.com/venue-logo.png',
      );
    });
  });

  group('VenueModel banner and logo mapping', () {
    test('maps bannerUrl from Firestore into bannerImageUrl', () {
      final venue = VenueModel.fromMap('wine-central', {
        'name': 'Wine Central',
        'bannerUrl': 'https://example.com/wine-central-banner.jpg',
      });

      expect(
        venue.bannerImageUrl,
        'https://example.com/wine-central-banner.jpg',
      );
    });

    test('maps alternate logo fields from Firestore', () {
      final venue = VenueModel.fromMap('venue-1', {
        'name': 'Test Venue',
        'logoImageUrl': 'https://example.com/logo.png',
      });

      expect(venue.logoUrl, 'https://example.com/logo.png');
    });
  });
}
