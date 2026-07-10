import 'package:test/test.dart';
import 'package:vex_engines/venue/domain/venue_profile_constants.dart';
import 'package:vex_engines/venue/domain/venue_profile_field_codec.dart';

void main() {
  group('VenueProfileFieldCodec', () {
    test('buildFeatureTagsUpdate trims to three tags', () {
      final update = VenueProfileFieldCodec.buildFeatureTagsUpdate(
        selectedKeys: {'liveMusic', 'dj', 'sports', 'karaoke'},
        ageRestricted: true,
      );

      expect(update['featureTags'], ['Live Music', 'DJ', 'Sports']);
      final features = update['venueFeatures'] as Map<String, dynamic>;
      expect(features['liveMusic'], isTrue);
      expect(features['karaoke'], isFalse);
      expect(features['age18'], isTrue);
    });

    test('displayFeatureTags returns at most three tags', () {
      expect(
        VenueProfileFieldCodec.displayFeatureTags(
          featureTags: const ['Live Music', 'DJ', 'Sports', 'Karaoke'],
          features: const [],
        ),
        ['Live Music', 'DJ', 'Sports'],
      );
    });

    test('validateWebsite accepts empty and normalises valid urls', () {
      expect(VenueProfileFieldCodec.validateWebsite(''), isNull);
      expect(
        VenueProfileFieldCodec.normaliseWebsite('example.com'),
        'https://example.com',
      );
      expect(VenueProfileFieldCodec.validateWebsite('not a url'), isNotNull);
    });

    test('validateOpeningHours requires 24-hour times for open days', () {
      final error = VenueProfileFieldCodec.validateOpeningHours({
        'monday': {'closed': false, 'open': '18:00', 'close': '02:00'},
        'tuesday': {'closed': true, 'open': '', 'close': ''},
        'wednesday': {'closed': true, 'open': '', 'close': ''},
        'thursday': {'closed': true, 'open': '', 'close': ''},
        'friday': {'closed': true, 'open': '', 'close': ''},
        'saturday': {'closed': true, 'open': '', 'close': ''},
        'sunday': {'closed': true, 'open': '', 'close': ''},
      });

      expect(error, isNull);
    });

    test(
      'detects age-restricted venues from feature tags and raw document',
      () {
        expect(
          VenueProfileFieldCodec.isAgeRestrictedVenue(
            featureTags: const ['Over 21'],
            rawDocument: null,
          ),
          isTrue,
        );
        expect(
          VenueProfileFieldCodec.isAgeRestrictedVenue(
            featureTags: const [],
            rawDocument: {
              'venueFeatures': {'age18': true},
            },
          ),
          isTrue,
        );
      },
    );
  });

  test('max feature tag constant is three', () {
    expect(VenueProfileConstants.maxFeatureTags, 3);
  });
}
