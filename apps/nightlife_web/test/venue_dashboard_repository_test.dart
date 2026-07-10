import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/features/auth/services/user_role_service.dart';
import 'package:nightlife_web/features/venue_management/data/venue_dashboard_repository.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_context.dart';
import 'package:nightlife_web/features/venues/models/venue_model.dart';

void main() {
  group('VenueDashboardRepository context mapping', () {
    test('maps venue model fields into dashboard context', () {
      const context = VenueDashboardContext(
        ownerName: 'Jamie Owner',
        ownerFirstName: 'Jamie',
        venueName: 'Real Venue',
        venueId: 'venue-real',
        logoUrl: 'https://example.com/logo.png',
      );

      expect(context.ownerName, 'Jamie Owner');
      expect(context.venueName, 'Real Venue');
      expect(context.logoUrl, isNotNull);
      expect(context.initials, 'RV');
    });

    test('owner role maps to venue dashboard route', () {
      expect(
        UserRoleService.routeForRole(
          UserRoleService.parseUserDocument(const {'role': 'owner'}),
        ),
        '/venue/dashboard',
      );
    });
  });

  group('VenueDashboardLoadException', () {
    test('exposes message', () {
      final error = VenueDashboardLoadException('No venue found');
      expect(error.message, 'No venue found');
      expect(error.toString(), 'No venue found');
    });
  });

  group('VenueModel dashboard fields', () {
    test('supports logo and banner urls used by sidebar/header', () {
      final venue = VenueModel.fromMap('venue-1', {
        'name': 'Copper Lantern',
        'logoUrl': 'https://example.com/logo.png',
        'bannerImageUrl': 'https://example.com/banner.png',
        'ownerId': 'owner-1',
      });

      expect(venue.name, 'Copper Lantern');
      expect(venue.logoUrl, 'https://example.com/logo.png');
      expect(venue.bannerImageUrl, 'https://example.com/banner.png');
    });
  });
}
