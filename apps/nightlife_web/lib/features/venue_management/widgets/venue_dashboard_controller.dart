import 'package:flutter/material.dart';

import '../models/venue_dashboard_context.dart';
import '../models/venue_dashboard_date_range.dart';
import '../models/venue_dashboard_home_data.dart';
import '../models/venue_dashboard_tab.dart';

/// Exposes venue dashboard shell actions and loaded data to child panels.
class VenueDashboardController extends InheritedWidget {
  const VenueDashboardController({
    super.key,
    required this.selectTab,
    required this.contextData,
    required super.child,
    this.homeData,
    this.isLoadingHomeData = false,
    this.homeDataError,
    this.onRefreshHomeData,
    this.onDateRangeChanged,
  });

  final ValueChanged<VenueDashboardTab> selectTab;
  final VenueDashboardContext contextData;
  final VenueDashboardHomeData? homeData;
  final bool isLoadingHomeData;
  final Object? homeDataError;
  final Future<void> Function()? onRefreshHomeData;
  final Future<void> Function(VenueDashboardDateRange range)? onDateRangeChanged;

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
        contextData != oldWidget.contextData ||
        homeData != oldWidget.homeData ||
        isLoadingHomeData != oldWidget.isLoadingHomeData ||
        homeDataError != oldWidget.homeDataError ||
        onRefreshHomeData != oldWidget.onRefreshHomeData ||
        onDateRangeChanged != oldWidget.onDateRangeChanged;
  }
}
