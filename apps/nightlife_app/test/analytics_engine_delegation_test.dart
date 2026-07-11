import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_app/features/analytics/services/analytics_service.dart';

void main() {
  group('AnalyticsService engine delegation', () {
    test('WeeklyGrowthMetric uses Analytics Engine calculator semantics', () {
      const metric = WeeklyGrowthMetric(
        thisWeekScore: 2,
        lastWeekScore: 1,
        percentageChange: 100,
      );

      expect(metric.hasActivity, isTrue);
      expect(metric.dashboardLabel, contains('Growing'));
    });

    test('AnalyticsSummary conversion rate uses engagement rules', () {
      const summary = AnalyticsSummary(
        venueViews: 100,
        favouriteTaps: 10,
        crowdUpdates: 0,
        drinkViews: 0,
        dealViews: 0,
        eventViews: 0,
        topDrinks: [],
        topDeals: [],
        crowdTrends: [],
      );

      expect(summary.favouriteConversionRate, 10);
      expect(summary.formattedConversionRate, '10.0%');
    });
  });
}
