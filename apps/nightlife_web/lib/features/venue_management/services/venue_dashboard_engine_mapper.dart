import 'package:flutter/material.dart';
import 'package:vex_engines/analytics/domain/analytics_dashboard_date_range.dart';
import 'package:vex_engines/analytics/domain/analytics_dashboard_models.dart';
import 'package:vex_engines/venue/domain/venue_dashboard_models.dart';

import '../models/venue_dashboard_activity.dart';
import '../models/venue_dashboard_date_range.dart';
import '../models/venue_dashboard_performance_highlight.dart';
import '../models/venue_dashboard_stat.dart';
import '../models/venue_dashboard_tab.dart';
import '../models/venue_dashboard_whats_next_action.dart';

/// Maps engine dashboard DTOs to web presentation models.
abstract final class VenueDashboardEngineMapper {
  static AnalyticsDashboardDateRange toAnalyticsRange(
    VenueDashboardDateRange range,
  ) {
    return switch (range) {
      VenueDashboardDateRange.today => AnalyticsDashboardDateRange.today,
      VenueDashboardDateRange.last3Days => AnalyticsDashboardDateRange.last3Days,
      VenueDashboardDateRange.last7Days => AnalyticsDashboardDateRange.last7Days,
      VenueDashboardDateRange.lastMonth => AnalyticsDashboardDateRange.lastMonth,
      VenueDashboardDateRange.allTime => AnalyticsDashboardDateRange.allTime,
      VenueDashboardDateRange.custom => AnalyticsDashboardDateRange.custom,
    };
  }

  static List<VenueDashboardStat> statsFromEngine(
    List<AnalyticsDashboardStat> stats,
  ) {
    return stats
        .map(
          (stat) => VenueDashboardStat(
            label: _statLabel(stat.metricKey),
            value: stat.value,
            changePercent: stat.changePercent,
            icon: _statIcon(stat.metricKey),
          ),
        )
        .toList();
  }

  static List<VenueDashboardPerformanceHighlight> highlightsFromEngine(
    List<VenueDashboardHighlight> highlights,
  ) {
    return highlights
        .map(
          (highlight) => VenueDashboardPerformanceHighlight(
            message: highlight.message,
            buttonLabel: highlight.buttonLabel,
            icon: _iconForKey(highlight.iconKey),
            targetTab: _tabForKey(highlight.targetTabKey),
            accent: _accentForKey(highlight.accentKey),
          ),
        )
        .toList();
  }

  static List<VenueDashboardHighlight> analyticsHighlightsFromEngine(
    List<AnalyticsDashboardHighlight> highlights,
  ) {
    return highlights
        .map(
          (highlight) => VenueDashboardHighlight(
            message: highlight.message,
            buttonLabel: highlight.buttonLabel,
            targetTabKey: highlight.targetTabKey,
            accentKey: highlight.accentKey,
            iconKey: _analyticsIconKey(highlight.accentKey),
          ),
        )
        .toList();
  }

  static List<VenueDashboardWhatsNextAction> whatsNextFromEngine(
    List<VenueWhatsNextAction> actions,
  ) {
    return actions
        .map(
          (action) => VenueDashboardWhatsNextAction(
            title: action.title,
            message: action.message,
            buttonLabel: action.buttonLabel,
            icon: _iconForKey(action.iconKey),
            targetTab: _tabForKey(action.targetTabKey)!,
          ),
        )
        .toList();
  }

  static List<VenueDashboardActivity> activityFromEngine(
    List<VenueActivityItem> items,
  ) {
    return items
        .map(
          (item) => VenueDashboardActivity(
            title: item.title,
            timestampLabel: item.timestampLabel,
            icon: _iconForKey(item.iconKey),
          ),
        )
        .toList();
  }

  static String _statLabel(String metricKey) {
    return switch (metricKey) {
      AnalyticsDashboardMetricKey.profileViews => 'Profile Views',
      AnalyticsDashboardMetricKey.saves => 'Saves',
      AnalyticsDashboardMetricKey.drinkViews => 'Drink Views',
      AnalyticsDashboardMetricKey.dealViews => 'Deal Views',
      AnalyticsDashboardMetricKey.eventViews => 'Event Views',
      _ => metricKey,
    };
  }

  static IconData _statIcon(String metricKey) {
    return switch (metricKey) {
      AnalyticsDashboardMetricKey.profileViews => Icons.visibility_outlined,
      AnalyticsDashboardMetricKey.saves => Icons.bookmark_outline_rounded,
      AnalyticsDashboardMetricKey.drinkViews => Icons.local_bar_outlined,
      AnalyticsDashboardMetricKey.dealViews => Icons.local_offer_outlined,
      AnalyticsDashboardMetricKey.eventViews => Icons.event_outlined,
      _ => Icons.insights_outlined,
    };
  }

  static String _analyticsIconKey(String accentKey) {
    return switch (accentKey) {
      'pink' => 'bookmark_outline_rounded',
      _ => 'visibility_outlined',
    };
  }

  static IconData _iconForKey(String iconKey) {
    return switch (iconKey) {
      'photo_library_outlined' => Icons.photo_library_outlined,
      'local_bar_outlined' => Icons.local_bar_outlined,
      'local_offer_outlined' => Icons.local_offer_outlined,
      'event_outlined' => Icons.event_outlined,
      'storefront_outlined' => Icons.storefront_outlined,
      'bookmark_outline_rounded' => Icons.bookmark_outline_rounded,
      'groups_outlined' => Icons.groups_outlined,
      'visibility_outlined' => Icons.visibility_outlined,
      _ => Icons.circle_outlined,
    };
  }

  static VenueDashboardTab? _tabForKey(String tabKey) {
    return switch (tabKey) {
      VenueDashboardTabKey.analytics => VenueDashboardTab.analytics,
      VenueDashboardTabKey.gallery => VenueDashboardTab.gallery,
      VenueDashboardTabKey.drinks => VenueDashboardTab.drinks,
      VenueDashboardTabKey.deals => VenueDashboardTab.deals,
      VenueDashboardTabKey.events => VenueDashboardTab.events,
      VenueDashboardTabKey.venueProfile => VenueDashboardTab.venueProfile,
      _ => null,
    };
  }

  static VenueDashboardHighlightAccent _accentForKey(String accentKey) {
    return switch (accentKey) {
      'pink' => VenueDashboardHighlightAccent.pink,
      'gold' => VenueDashboardHighlightAccent.gold,
      'emerald' => VenueDashboardHighlightAccent.emerald,
      'blue' => VenueDashboardHighlightAccent.blue,
      _ => VenueDashboardHighlightAccent.purple,
    };
  }
}
