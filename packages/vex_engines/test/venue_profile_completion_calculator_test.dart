import 'package:test/test.dart';
import 'package:vex_engines/venue/application/venue_profile_completion_calculator.dart';
import 'package:vex_engines/venue/domain/venue_profile_completion_input.dart';

void main() {
  group('VenueProfileCompletionCalculator', () {
    test('calculates completion from profile fields and drink count', () {
      final completion = VenueProfileCompletionCalculator.calculate(
        const VenueProfileCompletionInput(
          name: 'Copper Lantern',
          address: '12 High Street',
          area: 'City Centre',
          city: 'London',
          category: 'Bar',
          venueType: 'Bar',
          logoUrl: 'https://example.com/logo.png',
          bannerImageUrl: 'https://example.com/banner.png',
          phone: '02070000000',
          website: 'https://example.com',
          featureTags: ['liveMusic'],
          features: const [],
          openingHours: {
            'monday': {'open': '17:00', 'close': '23:00'},
          },
          drinkCount: 2,
        ),
      );

      expect(completion.completedSteps, 10);
      expect(completion.percentage, 100);
    });

    test('returns zero completion for empty profile', () {
      final completion = VenueProfileCompletionCalculator.calculate(
        const VenueProfileCompletionInput(
          name: '',
          address: '',
          area: '',
          city: '',
          category: '',
          venueType: '',
          logoUrl: '',
          bannerImageUrl: '',
          phone: '',
          website: '',
          featureTags: [],
          features: [],
          openingHours: {},
          drinkCount: 0,
        ),
      );

      expect(completion.completedSteps, 0);
      expect(completion.percentage, 0);
    });
  });
}
