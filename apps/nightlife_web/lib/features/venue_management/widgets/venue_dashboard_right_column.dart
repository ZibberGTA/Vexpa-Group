import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../models/venue_page_quick_action.dart';
import '../presentation/venue_management_activity_presentation.dart';
import 'venue_dashboard_controller.dart';
import 'venue_dashboard_go_premium_panel.dart';
import 'venue_dashboard_layout.dart';
import 'venue_dashboard_quick_actions_panel.dart';
import 'venue_dashboard_recent_activity_panel.dart';

/// Right-hand dashboard column — Quick Actions, Recent Activity, Go Premium.
class VenueDashboardRightColumn extends StatelessWidget {
  const VenueDashboardRightColumn({
    super.key,
    this.expanded = false,
    this.quickActions,
    this.useControllerFeed = false,
    this.onQuickAction,
    this.pageRecentActivity,
    this.isLoadingPageRecentActivity = false,
    this.pageRecentActivityError,
    this.onRetryPageRecentActivity,
  });

  /// When true, the column stretches to the available content width (tablet/mobile).
  final bool expanded;
  final List<VenuePageQuickAction>? quickActions;
  final bool useControllerFeed;
  final void Function(VenuePageQuickAction action)? onQuickAction;
  final List<VenueManagementActivityPresentation>? pageRecentActivity;
  final bool isLoadingPageRecentActivity;
  final Object? pageRecentActivityError;
  final Future<void> Function()? onRetryPageRecentActivity;

  @override
  Widget build(BuildContext context) {
    final controller = VenueDashboardController.maybeOf(context);
    final usesDashboardFeed = useControllerFeed ||
        (pageRecentActivity == null &&
            pageRecentActivityError == null &&
            !isLoadingPageRecentActivity &&
            controller != null &&
            (controller.recentManagementActivity != null ||
                controller.isLoadingRecentActivity ||
                controller.recentActivityError != null));

    return SizedBox(
      width: expanded ? double.infinity : VenueDashboardLayout.rightColumnWidth,
      child: SingleChildScrollView(
        primary: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VenueDashboardQuickActionsPanel(
              actions: quickActions,
              onQuickAction: onQuickAction,
            ),
            const SizedBox(height: AppSpacing.lg),
            VenueDashboardRecentActivityPanel(
              useControllerFeed: usesDashboardFeed,
              pageRecentActivity: pageRecentActivity,
              isLoadingPageRecentActivity: isLoadingPageRecentActivity,
              pageRecentActivityError: pageRecentActivityError,
              onRetryPageRecentActivity: onRetryPageRecentActivity,
            ),
            const SizedBox(height: AppSpacing.lg),
            const VenueDashboardGoPremiumPanel(),
          ],
        ),
      ),
    );
  }
}
