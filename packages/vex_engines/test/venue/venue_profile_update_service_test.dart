import 'package:test/test.dart';
import 'package:vex_core/vex_core.dart';
import 'package:vex_engines/venue/application/venue_profile_update_service.dart';
import 'package:vex_engines/venue/domain/venue_profile_search_context.dart';

const _context = VenueProfileSearchContext(
  name: 'Copper Lantern',
  description: 'A neighbourhood bar.',
  address: '12 High Street',
  category: 'Bar',
  crowdLevel: 'moderate',
);

void main() {
  const service = VenueProfileUpdateService();

  group('VenueProfileUpdateService.prepareNameUpdate', () {
    test('prepares name and search terms only', () {
      final result = service.prepareNameUpdate(
        venueId: 'venue-1',
        name: ' New Name ',
        context: _context,
      );

      final update = (result as DataSuccess).value;
      expect(update.fields.keys, ['name', 'searchTerms']);
      expect(update.fields['name'], 'New Name');
      expect(update.serverTimestampFields, ['updatedAt']);
    });

    test('rejects blank venue ID without preparing fields', () {
      final result = service.prepareNameUpdate(
        venueId: '  ',
        name: 'Name',
        context: _context,
      );

      expect(result, isA<DataFailure>());
      expect((result as DataFailure).error.code, 'venue-id-required');
    });
  });

  group('VenueProfileUpdateService.prepareWebsiteUpdate', () {
    test('normalises valid website urls', () {
      final result = service.prepareWebsiteUpdate(
        venueId: 'venue-1',
        website: 'example.com',
      );

      final update = (result as DataSuccess).value;
      expect(update.fields['website'], 'https://example.com');
      expect(update.fields['websiteUrl'], 'https://example.com');
    });

    test('rejects invalid website urls', () {
      final result = service.prepareWebsiteUpdate(
        venueId: 'venue-1',
        website: 'not a url',
      );

      expect(result, isA<DataFailure>());
      expect(
        (result as DataFailure).error.code,
        'venue-profile-validation-failed',
      );
    });

    test('allows empty website', () {
      final result = service.prepareWebsiteUpdate(
        venueId: 'venue-1',
        website: '',
      );

      final update = (result as DataSuccess).value;
      expect(update.fields['website'], '');
    });
  });

  group('VenueProfileUpdateService.prepareOpeningHoursUpdate', () {
    test('rejects invalid opening hours', () {
      final result = service.prepareOpeningHoursUpdate(
        venueId: 'venue-1',
        openingHours: {
          'monday': {'closed': false, 'open': 'bad', 'close': '02:00'},
          'tuesday': {'closed': true, 'open': '', 'close': ''},
          'wednesday': {'closed': true, 'open': '', 'close': ''},
          'thursday': {'closed': true, 'open': '', 'close': ''},
          'friday': {'closed': true, 'open': '', 'close': ''},
          'saturday': {'closed': true, 'open': '', 'close': ''},
          'sunday': {'closed': true, 'open': '', 'close': ''},
        },
      );

      expect(result, isA<DataFailure>());
    });

    test('builds opening hours map for valid draft', () {
      final result = service.prepareOpeningHoursUpdate(
        venueId: 'venue-1',
        openingHours: {
          'monday': {'closed': false, 'open': '18:00', 'close': '02:00'},
          'tuesday': {'closed': true, 'open': '', 'close': ''},
          'wednesday': {'closed': true, 'open': '', 'close': ''},
          'thursday': {'closed': true, 'open': '', 'close': ''},
          'friday': {'closed': true, 'open': '', 'close': ''},
          'saturday': {'closed': true, 'open': '', 'close': ''},
          'sunday': {'closed': true, 'open': '', 'close': ''},
        },
      );

      final update = (result as DataSuccess).value;
      expect(update.fields.containsKey('openingHours'), isTrue);
    });
  });

  group('VenueProfileUpdateService.prepareFeatureTagsUpdate', () {
    test('normalises feature tags to three labels', () {
      final result = service.prepareFeatureTagsUpdate(
        venueId: 'venue-1',
        selectedKeys: {'liveMusic', 'dj', 'sports', 'karaoke'},
        ageRestricted: true,
      );

      final update = (result as DataSuccess).value;
      expect(update.fields['featureTags'], ['Live Music', 'DJ', 'Sports']);
    });
  });

  group('VenueProfileUpdateService.prepareCrowdLevelUpdate', () {
    test('includes crowd metadata and both timestamp fields', () {
      final result = service.prepareCrowdLevelUpdate(
        venueId: 'venue-1',
        crowdLevel: 'busy',
        context: _context,
      );

      final update = (result as DataSuccess).value;
      expect(update.fields['crowdLevel'], 'busy');
      expect(update.fields['currentCrowdScore'], 4);
      expect(update.fields['crowdSource'], 'owner');
      expect(update.serverTimestampFields, ['updatedAt', 'crowdUpdatedAt']);
    });
  });
}
