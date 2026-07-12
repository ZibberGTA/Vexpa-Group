import 'package:test/test.dart';
import 'package:vex_engines/venue/application/venue_admin_health_service.dart';
import 'package:vex_engines/venue/domain/venue_admin_health.dart';
import 'package:vex_engines/venue/domain/venue_admin_health_input.dart';

void main() {
  const service = VenueAdminHealthService();

  group('VenueAdminHealthService', () {
    test('calculates full admin health checklist', () {
      final health = service.calculate(
        const VenueAdminHealthInput(
          logoUrl: 'https://logo.png',
          bannerUrl: 'https://banner.png',
          description: 'A great venue',
          address: '1 High Street',
          city: 'Leeds',
          website: 'https://venue.example',
          openingHours: {
            'monday': {'open': '12:00', 'close': '23:00'},
          },
          isVerified: true,
          isClaimed: true,
          galleryImagesCount: 3,
          drinksCount: 5,
          dealsCount: 2,
          eventsCount: 1,
        ),
      );

      expect(health.scorePercent, 100);
      expect(health.passedCount, 12);
      expect(health.totalCount, 12);
      expect(health.isComplete, isTrue);
    });

    test('table estimate ignores content counts', () {
      final input = VenueAdminHealthInput(
        logoUrl: 'logo',
        bannerUrl: '',
        description: '',
        address: '',
        city: '',
        website: '',
        openingHours: const {},
        isVerified: false,
        isClaimed: false,
        galleryImagesCount: 0,
        drinksCount: 99,
        dealsCount: 99,
        eventsCount: 99,
      );

      final full = service.calculate(input);
      final estimate = service.calculateTableEstimate(input: input);

      expect(full.passedCount, greaterThan(estimate.passedCount));
      expect(estimate.passedCount, 1);
    });

    test('accent tier thresholds match admin CRM presentation', () {
      expect(service.accentTier(80), VenueHealthAccentTier.strong);
      expect(service.accentTier(75), VenueHealthAccentTier.strong);
      expect(service.accentTier(45), VenueHealthAccentTier.moderate);
      expect(service.accentTier(44), VenueHealthAccentTier.weak);
    });

    test('missing opening hours fails checklist item', () {
      final health = service.calculate(
        const VenueAdminHealthInput(
          logoUrl: 'logo',
          bannerUrl: 'banner',
          description: 'desc',
          address: 'addr',
          city: 'city',
          website: 'site',
          openingHours: {},
          isVerified: true,
          isClaimed: true,
          galleryImagesCount: 1,
          drinksCount: 1,
          dealsCount: 1,
          eventsCount: 1,
        ),
      );

      expect(
        health.items.any(
          (item) => item.label == 'Opening hours complete' && !item.passed,
        ),
        isTrue,
      );
    });
  });
}
