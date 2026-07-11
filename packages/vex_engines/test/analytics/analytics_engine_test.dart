import 'package:test/test.dart';
import 'package:vex_engines/analytics/application/analytics_chart_series_builder.dart';
import 'package:vex_engines/analytics/application/analytics_engagement_calculator.dart';
import 'package:vex_engines/analytics/application/analytics_event_validator.dart';
import 'package:vex_engines/analytics/application/analytics_metrics_composer.dart';
import 'package:vex_engines/analytics/application/analytics_percent_change.dart';
import 'package:vex_engines/analytics/application/analytics_top_entity_aggregator.dart';
import 'package:vex_engines/analytics/application/analytics_trending_input_builder.dart';
import 'package:vex_engines/analytics/application/analytics_weekly_growth_calculator.dart';
import 'package:vex_engines/analytics/domain/analytics_chart_period.dart';
import 'package:vex_engines/analytics/domain/analytics_event_record.dart';
import 'package:vex_engines/analytics/domain/analytics_future_content.dart';
import 'package:vex_engines/analytics/domain/analytics_venue_metrics.dart';

void main() {
  const composer = AnalyticsMetricsComposer();
  const chartBuilder = AnalyticsChartSeriesBuilder();
  const topAggregator = AnalyticsTopEntityAggregator();
  const growthCalculator = AnalyticsWeeklyGrowthCalculator();
  const engagementCalculator = AnalyticsEngagementCalculator();
  const validator = AnalyticsEventValidator();

  group('AnalyticsMetricsComposer', () {
    test('aggregates dashboard count queries in standard order', () {
      final metrics = composer.fromDashboardCounts([10, 2, 3, 4, 5]);
      expect(metrics.profileViews, 10);
      expect(metrics.saves, 2);
      expect(metrics.total, 24);
    });

    test('reports empty snapshot when counts and chart are zero', () {
      expect(
        composer.snapshotHasData(
          current: AnalyticsVenueMetrics.empty,
          chartPoints: const [],
        ),
        isFalse,
      );
    });
  });

  group('AnalyticsPercentChange', () {
    test('returns null when previous is unavailable', () {
      expect(AnalyticsPercentChange.calculate(10, null), isNull);
    });

    test('returns 100 when previous is zero and current is positive', () {
      expect(AnalyticsPercentChange.calculate(5, 0), 100);
    });

    test('calculates deterministic percentage change', () {
      expect(AnalyticsPercentChange.calculate(150, 100), 50);
    });
  });

  group('AnalyticsChartSeriesBuilder', () {
    test('buckets profile views by weekday for last 7 days', () {
      final series = chartBuilder.buildProfileViewsSeries(
        timestamps: [
          DateTime(2026, 7, 6), // Mon
          DateTime(2026, 7, 6, 15),
          DateTime(2026, 7, 7), // Tue
        ],
        period: AnalyticsChartPeriod.last7Days,
      );

      expect(series.firstWhere((point) => point.label == 'Mon').value, 2);
      expect(series.firstWhere((point) => point.label == 'Tue').value, 1);
    });

    test('returns empty series for empty timestamps', () {
      expect(
        chartBuilder.buildProfileViewsSeries(
          timestamps: const [],
          period: AnalyticsChartPeriod.today,
        ),
        isEmpty,
      );
    });
  });

  group('AnalyticsTopEntityAggregator', () {
    test('ranks top drinks deals and events from event records', () {
      final top = topAggregator.aggregateTodayEntities(const [
        AnalyticsEventRecord(
          type: 'drink_view',
          payload: {'drinkName': 'Espresso Martini'},
        ),
        AnalyticsEventRecord(
          type: 'drink_view',
          payload: {'drinkName': 'Espresso Martini'},
        ),
        AnalyticsEventRecord(
          type: 'deal_view',
          payload: {'dealTitle': 'Happy Hour'},
        ),
      ]);

      expect(top.topDrinkName, 'Espresso Martini');
      expect(top.topDealTitle, 'Happy Hour');
    });

    test('ignores malformed payload records', () {
      final items = topAggregator.topItems(
        events: const [
          AnalyticsEventRecord(type: 'drink_view', payload: {}),
          AnalyticsEventRecord(
            type: 'drink_view',
            payload: {'drinkId': 'd1', 'drinkName': 'Lager'},
          ),
        ],
        idKey: 'drinkId',
        nameKey: 'drinkName',
      );

      expect(items, hasLength(1));
      expect(items.first.name, 'Lager');
    });
  });

  group('AnalyticsWeeklyGrowthCalculator', () {
    test('computes week-over-week growth deterministically', () {
      final now = DateTime(2026, 7, 14, 12);
      final growth = growthCalculator.compute(
        eventTimestamps: [
          now.subtract(const Duration(days: 1)),
          now.subtract(const Duration(days: 2)),
          now.subtract(const Duration(days: 10)),
        ],
        now: now,
      );

      expect(growth.thisWeekScore, 2);
      expect(growth.lastWeekScore, 1);
      expect(growth.percentageChange, 100);
      expect(growth.dashboardLabel, contains('Growing'));
    });
  });

  group('AnalyticsEngagementCalculator', () {
    test('calculates favourite conversion and popularity score', () {
      const metrics = AnalyticsVenueMetrics(
        profileViews: 100,
        saves: 10,
        drinkViews: 5,
        dealViews: 3,
        eventViews: 2,
      );

      final engagement = engagementCalculator.compute(metrics);
      expect(engagement.favouriteConversionRate, 10);
      expect(engagement.totalContentViews, 10);
      expect(engagement.popularityScore, 120);
    });
  });

  group('AnalyticsTrendingInputBuilder', () {
    test('builds clamped trending inputs', () {
      const builder = AnalyticsTrendingInputBuilder();
      final input = builder.build(
        venueViews: 50,
        favouriteTaps: 5,
        drinkViews: 3,
        dealViews: 2,
        eventViews: 1,
        boostScore: 10,
        isOpen: true,
      );

      expect(input.venueViews, 50);
      expect(input.isOpen, isTrue);
    });
  });

  group('AnalyticsEventValidator', () {
    test('rejects invalid venue IDs and accepts known event types', () {
      expect(validator.isValidVenueId(' '), isFalse);
      expect(validator.isValidEventType('venue_view'), isTrue);
      expect(validator.canLogEvent(venueId: 'v1', type: 'deal_view'), isTrue);
    });
  });

  group('Analytics future content structure', () {
    test('marks AI capabilities as planned only', () {
      expect(
        AnalyticsFutureContent.planned,
        contains(AnalyticsFutureCapability.aiInsights),
      );
    });
  });
}
