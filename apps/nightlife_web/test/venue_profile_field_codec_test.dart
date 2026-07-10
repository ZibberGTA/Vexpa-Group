import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/features/venue_management/data/venue_profile_constants.dart';
import 'package:nightlife_web/features/venue_management/data/venue_profile_field_codec.dart';
import 'package:nightlife_web/features/venues/models/venue_model.dart';

void main() {
  group('VenueProfileFieldCodec', () {
    test('buildFeatureTagsUpdate trims to three tags', () {
      final update = VenueProfileFieldCodec.buildFeatureTagsUpdate(
        selectedKeys: {
          'liveMusic',
          'dj',
          'sports',
          'karaoke',
        },
        ageRestricted: true,
      );

      expect(update['featureTags'], ['Live Music', 'DJ', 'Sports']);
      final features = update['venueFeatures'] as Map<String, dynamic>;
      expect(features['liveMusic'], isTrue);
      expect(features['karaoke'], isFalse);
      expect(features['age18'], isTrue);
    });

    test('displayFeatureTags returns at most three tags', () {
      final venue = VenueModel(
        id: 'v1',
        name: 'Test',
        address: '1 Street',
        area: 'Centre',
        city: 'City',
        category: 'Bar',
        venueType: 'Bar',
        crowdLevel: 'quiet',
        featureTags: const ['Live Music', 'DJ', 'Sports', 'Karaoke'],
      );

      expect(
        VenueProfileFieldCodec.displayFeatureTags(venue),
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
        'monday': {
          'closed': false,
          'open': '18:00',
          'close': '02:00',
        },
        'tuesday': {'closed': true, 'open': '', 'close': ''},
        'wednesday': {'closed': true, 'open': '', 'close': ''},
        'thursday': {'closed': true, 'open': '', 'close': ''},
        'friday': {'closed': true, 'open': '', 'close': ''},
        'saturday': {'closed': true, 'open': '', 'close': ''},
        'sunday': {'closed': true, 'open': '', 'close': ''},
      });

      expect(error, isNull);
    });
  });

  test('max feature tag constant is three', () {
    expect(VenueProfileConstants.maxFeatureTags, 3);
  });
}
