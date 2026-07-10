import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_context.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_date_range.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_home_data.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_stat.dart';
import 'package:nightlife_web/features/venue_management/models/venue_profile_completion.dart';
import 'package:nightlife_web/features/venue_management/services/venue_profile_completion_calculator.dart';
import 'package:nightlife_web/features/venue_management/utils/venue_dashboard_welcome_name.dart';
import 'package:nightlife_web/features/venues/models/venue_model.dart';

void main() {
  group('VenueDashboardWelcomeName', () {
    test('uses first name from owner context', () {
      expect(
        VenueDashboardWelcomeName.welcomeTitle(
          contextData: const VenueDashboardContext(
            ownerName: 'Alex Morgan',
            ownerFirstName: 'Alex',
            venueName: 'Test Venue',
            venueId: 'test',
          ),
        ),
        'Welcome back, Alex',
      );
    });

    test('falls back to User when no name', () {
      expect(
        VenueDashboardWelcomeName.welcomeTitle(),
        'Welcome back, User',
      );
    });
  });

  group('VenueDashboardStat subtitles', () {
    test('shows no data yet when analytics are zero', () {
      const stat = VenueDashboardStat(
        label: 'Profile Views',
        value: 0,
        icon: Icons.visibility_outlined,
      );

      expect(
        stat.subtitleLabel(VenueDashboardDateRange.last7Days),
        'No data yet',
      );
    });

    test('uses comparison text when available', () {
      const stat = VenueDashboardStat(
        label: 'Profile Views',
        value: 100,
        changePercent: 12,
        icon: Icons.visibility_outlined,
      );

      expect(
        stat.subtitleLabel(VenueDashboardDateRange.last7Days),
        '+12% vs previous 7 days',
      );
    });
  });

  group('VenueDashboardStatsData', () {
    test('empty stats return zero values without fake percentages', () {
      final stats = VenueDashboardStatsData.empty();
      expect(stats.length, 5);
      expect(stats.every((stat) => stat.value == 0), isTrue);
      expect(stats.every((stat) => !stat.hasComparison), isTrue);
    });
  });

  group('VenueProfileCompletionCalculator', () {
    test('calculates completion from venue fields and drink count', () {
      final completion = VenueProfileCompletionCalculator.calculate(
        venue: VenueModel(
          id: 'venue-1',
          name: 'Copper Lantern',
          address: '12 High Street',
          area: 'City Centre',
          city: 'London',
          category: 'Bar',
          venueType: 'Bar',
          crowdLevel: 'moderate',
          logoUrl: 'https://example.com/logo.png',
          bannerImageUrl: 'https://example.com/banner.png',
          phone: '02070000000',
          website: 'https://example.com',
          featureTags: const ['liveMusic'],
          openingHours: const {
            'monday': {'open': '17:00', 'close': '23:00'},
          },
        ),
        drinkCount: 2,
      );

      expect(completion.completedSteps, 10);
      expect(completion.percentage, 100);
    });

    test('returns zero completion for empty venue', () {
      final completion = VenueProfileCompletionCalculator.calculate(
        venue: VenueModel(
          id: 'venue-1',
          name: '',
          address: '',
          area: '',
          city: '',
          category: '',
          venueType: '',
          crowdLevel: 'quiet',
        ),
        drinkCount: 0,
      );

      expect(completion.completedSteps, 0);
      expect(completion.percentage, 0);
    });
  });

  group('VenueDashboardHomeData', () {
    test('empty home data does not include fake analytics', () {
      final home = VenueDashboardHomeData.empty();
      expect(home.stats.every((stat) => stat.value == 0), isTrue);
      expect(home.chartPoints, isEmpty);
      expect(home.analyticsAvailable, isFalse);
    });
  });
}
