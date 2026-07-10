import 'package:test/test.dart';
import 'package:vex_engines/venue/shared/venue_contact_utils.dart';

void main() {
  group('VenueContactUtils', () {
    test('builds phone dial uri from formatted numbers', () {
      expect(
        VenueContactUtils.phoneDialUri('020 7946 0958'),
        'tel:02079460958',
      );
      expect(VenueContactUtils.phoneDialUri('  '), isNull);
    });

    test('normalises website urls', () {
      expect(
        VenueContactUtils.normaliseWebsiteUrl('example.com'),
        'https://example.com',
      );
      expect(
        VenueContactUtils.normaliseWebsiteUrl('https://example.com'),
        'https://example.com',
      );
    });

    test('formats display website without scheme or trailing slash', () {
      expect(
        VenueContactUtils.displayWebsite('https://example.com/'),
        'example.com',
      );
    });
  });
}
