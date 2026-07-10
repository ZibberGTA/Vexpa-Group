import 'package:flutter/material.dart';

import 'venue_dashboard_activity.dart';
import 'venue_dashboard_date_range.dart';
import 'venue_dashboard_performance_highlight.dart';
import 'venue_dashboard_stat.dart';
import 'venue_dashboard_tab.dart';
import 'venue_dashboard_whats_next_action.dart';
import 'venue_profile_completion.dart';
import 'venue_profile_views_chart_data.dart';

/// Real dashboard home content for the active venue.
class VenueDashboardHomeData {
  const VenueDashboardHomeData({
    required this.dateRange,
    required this.stats,
    required this.chartPoints,
    required this.profileCompletion,
    required this.highlights,
    required this.whatsNext,
    required this.recentActivity,
    this.analyticsAvailable = false,
  });

  final VenueDashboardDateRange dateRange;
  final List<VenueDashboardStat> stats;
  final List<VenueProfileViewsDataPoint> chartPoints;
  final VenueProfileCompletion profileCompletion;
  final List<VenueDashboardPerformanceHighlight> highlights;
  final List<VenueDashboardWhatsNextAction> whatsNext;
  final List<VenueDashboardActivity> recentActivity;
  final bool analyticsAvailable;

  static VenueDashboardHomeData empty({
    VenueDashboardDateRange dateRange = VenueDashboardDateRange.defaultRange,
    VenueProfileCompletion? profileCompletion,
  }) {
    return VenueDashboardHomeData(
      dateRange: dateRange,
      stats: VenueDashboardStatsData.empty(),
      chartPoints: const [],
      profileCompletion: profileCompletion ?? VenueProfileCompletion.empty,
      highlights: VenueDashboardInsightsBuilder.setupHighlights(),
      whatsNext: const [],
      recentActivity: const [],
      analyticsAvailable: false,
    );
  }
}

/// Builds setup-focused insights when analytics are unavailable.
class VenueDashboardInsightsBuilder {
  VenueDashboardInsightsBuilder._();

  static List<VenueDashboardPerformanceHighlight> setupHighlights() {
    return const [
      VenueDashboardPerformanceHighlight(
        message: 'Add more photos to improve visibility.',
        buttonLabel: 'Add Photos',
        icon: Icons.photo_library_outlined,
        targetTab: VenueDashboardTab.gallery,
        accent: VenueDashboardHighlightAccent.blue,
      ),
      VenueDashboardPerformanceHighlight(
        message: 'Add drinks so customers can discover your venue.',
        buttonLabel: 'Add Drinks',
        icon: Icons.local_bar_outlined,
        targetTab: VenueDashboardTab.drinks,
        accent: VenueDashboardHighlightAccent.gold,
      ),
      VenueDashboardPerformanceHighlight(
        message: 'Create a deal to attract more customers.',
        buttonLabel: 'Create Deal',
        icon: Icons.local_offer_outlined,
        targetTab: VenueDashboardTab.deals,
        accent: VenueDashboardHighlightAccent.pink,
      ),
      VenueDashboardPerformanceHighlight(
        message: 'Add an event to increase engagement.',
        buttonLabel: 'Add Event',
        icon: Icons.event_outlined,
        targetTab: VenueDashboardTab.events,
        accent: VenueDashboardHighlightAccent.emerald,
      ),
    ];
  }
}
