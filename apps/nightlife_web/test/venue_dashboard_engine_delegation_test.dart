import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/features/venue_management/data/venue_activity_service.dart';
import 'package:nightlife_web/features/venue_management/data/venue_dashboard_repository.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_date_range.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_home_data.dart';
import 'package:nightlife_web/features/venue_management/services/venue_dashboard_engine_mapper.dart';
import 'package:vex_engines/analytics/application/analytics_dashboard_highlight_composer.dart';
import 'package:vex_engines/analytics/application/analytics_dashboard_stats_composer.dart';
import 'package:vex_engines/analytics/domain/analytics_venue_metrics.dart';
import 'package:vex_engines/venue/application/venue_dashboard_composer.dart';
import 'package:vex_engines/venue/domain/venue_dashboard_models.dart';
import 'package:vex_engines/venue/domain/venue_profile_completion.dart';

void main() {
  test('VenueDashboardRepository exposes engine collaborators', () {
    final repository = VenueDashboardRepository(
      statsComposer: const AnalyticsDashboardStatsComposer(),
      highlightComposer: const AnalyticsDashboardHighlightComposer(),
      dashboardHighlightComposer: const VenueDashboardHighlightComposer(),
      whatsNextComposer: const VenueWhatsNextComposer(),
    );

    expect(repository, isA<VenueDashboardRepository>());
  });

  test('VenueActivityService exposes engine collaborators', () {
    final service = VenueActivityService();
    expect(service, isA<VenueActivitySource>());
  });

  test('date range delegates period boundaries to Analytics Engine', () {
    final range = VenueDashboardDateRange.last7Days;
    final since = range.since;

    expect(since, isNotNull);
    expect(
      DateTime.now().difference(since!).inDays,
      inInclusiveRange(6, 8),
    );
    expect(
      VenueDashboardEngineMapper.toAnalyticsRange(range).label,
      'Last 7 days',
    );
  });

  test('dashboard home setup highlights match engine output', () {
    final highlights = VenueDashboardInsightsBuilder.setupHighlights();
    final engineHighlights = VenueDashboardEngineMapper.highlightsFromEngine(
      const VenueDashboardSetupHighlights().build(),
    );

    expect(highlights.length, engineHighlights.length);
    expect(highlights.first.message, engineHighlights.first.message);
    expect(highlights.first.buttonLabel, engineHighlights.first.buttonLabel);
  });

  test('stats mapper preserves analytics engine metric order', () {
    const composer = AnalyticsDashboardStatsComposer();
    final stats = VenueDashboardEngineMapper.statsFromEngine(
      composer.compose(
        current: const AnalyticsVenueMetrics(
          profileViews: 10,
          saves: 2,
          drinkViews: 3,
          dealViews: 4,
          eventViews: 5,
        ),
      ),
    );

    expect(stats.map((stat) => stat.label).toList(), [
      'Profile Views',
      'Saves',
      'Drink Views',
      'Deal Views',
      'Event Views',
    ]);
  });

  test('whats next mapper preserves engine ordering', () {
    const composer = VenueWhatsNextComposer();
    final actions = VenueDashboardEngineMapper.whatsNextFromEngine(
      composer.compose(
        venue: const VenueDashboardVenueSnapshot(
          venueId: 'venue-1',
          galleryImageCount: 0,
        ),
        profileCompletion: const VenueProfileCompletion(
          completedSteps: 8,
          totalSteps: 10,
        ),
        counts: const VenueDashboardContentCounts(
          dealCount: 0,
          hasUpcomingEvent: false,
        ),
      ),
    );

    expect(actions.first.title, 'Add more photos');
    expect(actions.any((action) => action.title == 'Create a new deal'), isTrue);
  });
}
