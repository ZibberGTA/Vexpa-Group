import 'package:test/test.dart';
import 'package:vex_engines/analytics/application/analytics_activity_aggregator.dart';
import 'package:vex_engines/analytics/application/analytics_dashboard_highlight_composer.dart';
import 'package:vex_engines/analytics/application/analytics_dashboard_stats_composer.dart';
import 'package:vex_engines/analytics/domain/analytics_dashboard_date_range.dart';
import 'package:vex_engines/analytics/domain/analytics_dashboard_models.dart';
import 'package:vex_engines/analytics/domain/analytics_venue_metrics.dart';

void main() {
  const periodCalculator = AnalyticsDashboardPeriodCalculator();
  const statsComposer = AnalyticsDashboardStatsComposer();
  const highlightComposer = AnalyticsDashboardHighlightComposer();
  const activityAggregator = AnalyticsActivityAggregator();
  const relativeTimeFormatter = AnalyticsRelativeTimeFormatter();

  group('AnalyticsDashboardPeriodCalculator', () {
    test('calculates last 7 days and previous period boundaries', () {
      final now = DateTime(2026, 7, 11, 15, 30);
      final since = periodCalculator.since(
        range: AnalyticsDashboardDateRange.last7Days,
        now: now,
      );
      final previousSince = periodCalculator.previousPeriodSince(
        range: AnalyticsDashboardDateRange.last7Days,
        now: now,
      );

      expect(since, now.subtract(const Duration(days: 7)));
      expect(previousSince, since!.subtract(const Duration(days: 7)));
    });

    test('all time has no period boundaries', () {
      expect(
        periodCalculator.since(
          range: AnalyticsDashboardDateRange.allTime,
          now: DateTime(2026, 7, 11),
        ),
        isNull,
      );
      expect(
        periodCalculator.previousPeriodSince(
          range: AnalyticsDashboardDateRange.allTime,
          now: DateTime(2026, 7, 11),
        ),
        isNull,
      );
    });
  });

  group('AnalyticsDashboardStatsComposer', () {
    test('composes dashboard stats with percent changes', () {
      final stats = statsComposer.compose(
        current: const AnalyticsVenueMetrics(
          profileViews: 150,
          saves: 20,
          drinkViews: 40,
          dealViews: 30,
          eventViews: 10,
        ),
        previous: const AnalyticsVenueMetrics(
          profileViews: 100,
          saves: 10,
          drinkViews: 40,
          dealViews: 20,
          eventViews: 10,
        ),
      );

      expect(stats, hasLength(5));
      expect(stats.first.metricKey, AnalyticsDashboardMetricKey.profileViews);
      expect(stats.first.value, 150);
      expect(stats.first.changePercent, 50);
      expect(stats[1].changePercent, 100);
    });

    test('returns empty stats without previous comparisons', () {
      final stats = statsComposer.empty();
      expect(stats.every((stat) => stat.value == 0), isTrue);
      expect(stats.every((stat) => stat.changePercent == null), isTrue);
    });
  });

  group('AnalyticsDashboardHighlightComposer', () {
    test('builds profile and saves highlights from period deltas', () {
      final highlights = highlightComposer.compose(
        current: const AnalyticsVenueMetrics(
          profileViews: 10,
          saves: 5,
          drinkViews: 0,
          dealViews: 0,
          eventViews: 0,
        ),
        previous: const AnalyticsVenueMetrics(
          profileViews: 5,
          saves: 2,
          drinkViews: 0,
          dealViews: 0,
          eventViews: 0,
        ),
      );

      expect(highlights, hasLength(2));
      expect(highlights.first.targetTabKey, 'analytics');
      expect(highlights.first.message, contains('profile views'));
    });

    test('returns empty list when previous period is unavailable', () {
      expect(
        highlightComposer.compose(
          current: const AnalyticsVenueMetrics(
            profileViews: 10,
            saves: 0,
            drinkViews: 0,
            dealViews: 0,
            eventViews: 0,
          ),
        ),
        isEmpty,
      );
    });
  });

  group('AnalyticsActivityAggregator', () {
    test('sorts by recency and limits output', () {
      final limited = activityAggregator.sortAndLimit(
        [
          AnalyticsActivityEntry(
            occurredAt: DateTime(2026, 7, 1),
            source: 'analytics',
            eventType: 'drink_view',
          ),
          AnalyticsActivityEntry(
            occurredAt: DateTime(2026, 7, 10),
            source: 'analytics',
            eventType: 'deal_view',
          ),
          AnalyticsActivityEntry(
            occurredAt: DateTime(2026, 7, 5),
            source: 'content_event',
            contentTitle: 'Friday Night',
          ),
        ],
        limit: 2,
      );

      expect(limited, hasLength(2));
      expect(limited.first.eventType, 'deal_view');
      expect(limited.last.contentTitle, 'Friday Night');
    });

    test('handles empty datasets', () {
      expect(activityAggregator.sortAndLimit(const []), isEmpty);
    });
  });

  group('AnalyticsRelativeTimeFormatter', () {
    test('formats deterministic relative labels', () {
      final now = DateTime(2026, 7, 11, 12, 0);
      expect(
        relativeTimeFormatter.format(now.subtract(const Duration(minutes: 10)), now: now),
        '10 minutes ago',
      );
      expect(
        relativeTimeFormatter.format(now.subtract(const Duration(days: 1)), now: now),
        'Yesterday',
      );
    });
  });
}
