import 'package:flutter/material.dart';

import '../presentation/venue_management_activity_presentation.dart';

/// Exposes canonical page-scoped activity state to entity management pages.
class VenueManagementPageActivityController extends InheritedWidget {
  const VenueManagementPageActivityController({
    super.key,
    required this.reload,
    required super.child,
    this.recentActivity,
    this.isLoadingRecentActivity = false,
    this.recentActivityError,
  });

  final List<VenueManagementActivityPresentation>? recentActivity;
  final bool isLoadingRecentActivity;
  final Object? recentActivityError;
  final Future<void> Function() reload;

  static VenueManagementPageActivityController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<VenueManagementPageActivityController>();
  }

  static Future<void> reloadIfPresent(BuildContext context) async {
    await maybeOf(context)?.reload();
  }

  @override
  bool updateShouldNotify(VenueManagementPageActivityController oldWidget) {
    return recentActivity != oldWidget.recentActivity ||
        isLoadingRecentActivity != oldWidget.isLoadingRecentActivity ||
        recentActivityError != oldWidget.recentActivityError ||
        reload != oldWidget.reload;
  }
}
