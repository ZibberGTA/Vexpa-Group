import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_app/core/utils/venue_branding_parser.dart';

void main() {
  group('VenueBrandingParser', () {
    test('resolveLogoUrl prefers logoUrl over legacy fields', () {
      final map = {
        'logoUrl': 'https://cdn/logo.png',
        'logoImageUrl': 'https://legacy/logo.png',
      };

      expect(
        VenueBrandingParser.resolveLogoUrl(map),
        'https://cdn/logo.png',
      );
    });

    test('resolveLogoUrl falls back to logoImageUrl', () {
      final map = {
        'logoImageUrl': 'https://legacy/logo.png',
      };

      expect(
        VenueBrandingParser.resolveLogoUrl(map),
        'https://legacy/logo.png',
      );
    });

    test('resolveBannerImageUrl prefers bannerImageUrl over legacy fields', () {
      final map = {
        'bannerImageUrl': 'https://cdn/banner.png',
        'coverImageUrl': 'https://legacy/cover.png',
        'bannerUrl': 'https://legacy/banner.png',
      };

      expect(
        VenueBrandingParser.resolveBannerImageUrl(map),
        'https://cdn/banner.png',
      );
    });

    test('resolveBannerImageUrl falls back through legacy banner fields', () {
      expect(
        VenueBrandingParser.resolveBannerImageUrl({
          'coverImageUrl': 'https://legacy/cover.png',
        }),
        'https://legacy/cover.png',
      );

      expect(
        VenueBrandingParser.resolveBannerImageUrl({
          'bannerUrl': 'https://legacy/banner.png',
        }),
        'https://legacy/banner.png',
      );
    });

    test('parseImageField supports nested url maps', () {
      expect(
        VenueBrandingParser.parseImageField({
          'url': 'https://cdn/nested.png',
        }),
        'https://cdn/nested.png',
      );
    });

    test('isValidImageUrl rejects invalid values', () {
      expect(VenueBrandingParser.isValidImageUrl(''), isFalse);
      expect(VenueBrandingParser.isValidImageUrl('not-a-url'), isFalse);
      expect(VenueBrandingParser.isValidImageUrl('https://cdn/ok.png'), isTrue);
    });
  });
}
