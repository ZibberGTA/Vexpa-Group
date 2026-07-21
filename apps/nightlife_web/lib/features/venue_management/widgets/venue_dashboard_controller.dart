import 'package:flutter/material.dart';

import '../models/venue_dashboard_context.dart';
import '../models/venue_dashboard_date_range.dart';
import '../models/venue_dashboard_home_data.dart';
import '../models/venue_dashboard_tab.dart';
import '../models/venue_profile_views_chart_data.dart';
import '../presentation/venue_management_activity_presentation.dart';

typedef VenueDashboardTabSelector = void Function(
  VenueDashboardTab tab, {
  String? pendingActionKey,
});

/// Exposes venue dashboard shell actions and loaded data to child panels.
class VenueDashboardController extends InheritedWidget {
  const VenueDashboardController({
    super.key,
    required this.selectTab,
    required this.contextData,
    required super.child,
    this.takePendingTabActionKey,
    this.homeData,
    this.isLoadingHomeData = false,
    this.homeDataError,
    this.onRefreshHomeData,
    this.onDateRangeChanged,
    this.onChartDateRangeChanged,
    this.recentManagementActivity,
    this.isLoadingRecentActivity = false,
    this.recentActivityError,
    this.onRetryRecentActivity,
  });

  final VenueDashboardTabSelector selectTab;
  final String? Function()? takePendingTabActionKey;
  final VenueDashboardContext contextData;
  final VenueDashboardHomeData? homeData;
  final bool isLoadingHomeData;
  final Object? homeDataError;
  final Future<void> Function()? onRefreshHomeData;
  final Future<void> Function(VenueDashboardDateRange range)? onDateRangeChanged;
  final Future<List<VenueProfileViewsDataPoint>> Function(
    VenueDashboardDateRange range,
  )? onChartDateRangeChanged;
  final List<VenueManagementActivityPresentation>? recentManagementActivity;
  final bool isLoadingRecentActivity;
  final Object? recentActivityError;
  final Future<void> Function()? onRetryRecentActivity;

  static VenueDashboardController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<VenueDashboardController>();
  }

  static VenueDashboardController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(controller != null, 'VenueDashboardController not found in context');
    return controller!;
  }

  @override
  bool updateShouldNotify(VenueDashboardController oldWidget) {
    return selectTab != oldWidget.selectTab ||
        takePendingTabActionKey != oldWidget.takePendingTabActionKey ||
        contextData != oldWidget.contextData ||
        homeData != oldWidget.homeData ||
        isLoadingHomeData != oldWidget.isLoadingHomeData ||
        homeDataError != oldWidget.homeDataError ||
        onRefreshHomeData != oldWidget.onRefreshHomeData ||
        onDateRangeChanged != oldWidget.onDateRangeChanged ||
        onChartDateRangeChanged != oldWidget.onChartDateRangeChanged ||
        recentManagementActivity != oldWidget.recentManagementActivity ||
        isLoadingRecentActivity != oldWidget.isLoadingRecentActivity ||
        recentActivityError != oldWidget.recentActivityError ||
        onRetryRecentActivity != oldWidget.onRetryRecentActivity;
  }
}
