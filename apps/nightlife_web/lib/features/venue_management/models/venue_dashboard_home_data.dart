import 'package:vex_engines/venue/application/venue_dashboard_composer.dart';

import 'venue_dashboard_date_range.dart';
import 'venue_dashboard_performance_highlight.dart';
import 'venue_dashboard_schedule.dart';
import 'venue_dashboard_stat.dart';
import 'venue_dashboard_whats_next_action.dart';
import 'venue_profile_completion.dart';
import 'venue_profile_views_chart_data.dart';
import '../services/venue_dashboard_engine_mapper.dart';
import '../services/venue_dashboard_schedule_service.dart';

/// Real dashboard home content for the active venue.
class VenueDashboardHomeData {
  const VenueDashboardHomeData({
    required this.dateRange,
    required this.stats,
    required this.chartPoints,
    required this.profileCompletion,
    required this.highlights,
    required this.whatsNext,
    required this.nextSevenDaysSchedule,
    this.analyticsAvailable = false,
  });

  final VenueDashboardDateRange dateRange;
  final List<VenueDashboardStat> stats;
  final List<VenueProfileViewsDataPoint> chartPoints;
  final VenueProfileCompletion profileCompletion;
  final List<VenueDashboardPerformanceHighlight> highlights;
  final List<VenueDashboardWhatsNextAction> whatsNext;
  final VenueDashboardSchedule nextSevenDaysSchedule;
  final bool analyticsAvailable;

  static VenueDashboardHomeData empty({
    VenueDashboardDateRange dateRange = VenueDashboardDateRange.defaultRange,
    VenueProfileCompletion? profileCompletion,
    DateTime? now,
  }) {
    return VenueDashboardHomeData(
      dateRange: dateRange,
      stats: VenueDashboardStatsData.empty(),
      chartPoints: const [],
      profileCompletion: profileCompletion ?? VenueProfileCompletion.empty,
      highlights: VenueDashboardInsightsBuilder.setupHighlights(),
      whatsNext: const [],
      nextSevenDaysSchedule: VenueDashboardScheduleService().compose(
        events: const [],
        deals: const [],
        now: now ?? DateTime.now(),
      ),
      analyticsAvailable: false,
    );
  }
}

/// Builds setup-focused insights when analytics are unavailable.
class VenueDashboardInsightsBuilder {
  VenueDashboardInsightsBuilder._();

  static List<VenueDashboardPerformanceHighlight> setupHighlights() {
    return VenueDashboardEngineMapper.highlightsFromEngine(
      const VenueDashboardSetupHighlights().build(),
    );
  }
}
