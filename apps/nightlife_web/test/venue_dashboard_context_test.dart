import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_context.dart';

void main() {
  group('VenueDashboardContext', () {
    test('withVenueDocument updates logo and banner from live venue doc', () {
      const base = VenueDashboardContext(
        ownerName: 'Alex',
        ownerFirstName: 'Alex',
        venueName: 'Wine Central',
        venueId: 'wine-central',
        logoUrl: null,
        bannerImageUrl: null,
      );

      final updated = base.withVenueDocument({
        'name': 'Wine Central',
        'logoUrl': 'https://storage.example.com/logo.png',
        'bannerImageUrl': 'https://storage.example.com/banner.png',
      });

      expect(updated.logoUrl, 'https://storage.example.com/logo.png');
      expect(updated.bannerImageUrl, 'https://storage.example.com/banner.png');
      expect(updated.venueName, 'Wine Central');
    });

    test('withVenueDocument clears logo when field is empty', () {
      const base = VenueDashboardContext(
        ownerName: 'Alex',
        ownerFirstName: 'Alex',
        venueName: 'Wine Central',
        venueId: 'wine-central',
        logoUrl: 'https://old.example.com/logo.png',
      );

      final updated = base.withVenueDocument({'logoUrl': ''});

      expect(updated.logoUrl, isNull);
    });
  });
}
