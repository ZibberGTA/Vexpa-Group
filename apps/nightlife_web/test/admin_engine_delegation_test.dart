import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/features/admin/data/admin_venue_content_support.dart';
import 'package:nightlife_web/features/admin/data/admin_venue_health_support.dart';
import 'package:nightlife_web/features/admin/models/admin_dashboard_models.dart';
import 'package:nightlife_web/features/admin/models/admin_venue_crm.dart';
import 'package:vex_engines/experience/application/experience_admin_content_service.dart';
import 'package:vex_engines/venue/domain/venue_admin_health.dart';

void main() {
  group('Admin engine delegation', () {
    test('AdminVenueHealthSupport delegates health scoring to Venue Engine', () {
      final profile = AdminVenueCrmView(
        row: AdminDocumentRow(
          id: 'v1',
          path: 'venues/v1',
          data: {
            'name': 'Fox Bar',
            'logoUrl': 'logo',
            'bannerImageUrl': 'banner',
            'description': 'Desc',
            'address': '1 Street',
            'city': 'Leeds',
            'website': 'https://fox.example',
            'openingHours': {
              'monday': {'open': '12:00'},
            },
            'isVerified': true,
            'ownerId': 'owner-1',
          },
        ),
      );

      final health = AdminVenueHealthSupport.calculateHealth(
        profile: profile,
        drinksCount: 2,
        dealsCount: 1,
        eventsCount: 1,
      );

      expect(health.scorePercent, greaterThanOrEqualTo(75));
      expect(health.totalCount, 12);
      expect(health.items.length, 12);
    });

    test('AdminVenueHealthSupport accent tier delegates to engine thresholds', () {
      expect(
        AdminVenueHealthSupport.accentTier(80),
        VenueHealthAccentTier.strong,
      );
      expect(
        AdminVenueHealthSupport.accentTier(40),
        VenueHealthAccentTier.weak,
      );
    });

    test('AdminVenueContentSupport delegates upcoming event counting', () {
      final now = DateTime(2026, 7, 12, 12);
      final count = AdminVenueContentSupport.countUpcomingEvents(
        startDateTimes: [now.add(const Duration(hours: 1)), null],
        now: now,
      );

      expect(
        count,
        const ExperienceAdminContentService().countUpcomingEvents(
          startDateTimes: [now.add(const Duration(hours: 1)), null],
          now: now,
        ),
      );
    });

    test('AdminVenueContentSupport maps engine summary to admin model', () {
      final mapped = AdminVenueContentSupport.mapSummary(
        AdminVenueContentSupport.buildSummary(
          drinksCount: 3,
          dealsCount: 2,
          eventsCount: 1,
          liveDealsCount: 1,
          upcomingEventsCount: 2,
        ),
      );

      expect(mapped.drinksCount, 3);
      expect(mapped.upcomingEventsCount, 2);
      expect(mapped.unavailable, isFalse);
    });

    test('estimateTableHealth excludes content counts', () {
      final profile = AdminVenueCrmView(
        row: AdminDocumentRow(
          id: 'v1',
          path: 'venues/v1',
          data: {'logoUrl': 'logo'},
        ),
      );

      final estimate = AdminVenueHealthSupport.estimateTableHealth(profile);
      final full = AdminVenueHealthSupport.calculateHealth(
        profile: profile,
        drinksCount: 5,
        dealsCount: 5,
        eventsCount: 5,
      );

      expect(estimate.passedCount, lessThan(full.passedCount));
    });
  });
}
