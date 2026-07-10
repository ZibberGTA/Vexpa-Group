import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../models/venue_dashboard_activity.dart';
import '../models/venue_page_quick_action.dart';
import 'venue_dashboard_go_premium_panel.dart';
import 'venue_dashboard_quick_actions_panel.dart';
import 'venue_dashboard_recent_activity_panel.dart';
import 'venue_dashboard_layout.dart';

/// Right-hand dashboard column — Quick Actions, Recent Activity, Go Premium.
class VenueDashboardRightColumn extends StatelessWidget {
  const VenueDashboardRightColumn({
    super.key,
    this.expanded = false,
    this.quickActions,
    this.activities,
    this.onQuickAction,
  });

  /// When true, the column stretches to the available content width (tablet/mobile).
  final bool expanded;
  final List<VenuePageQuickAction>? quickActions;
  final List<VenueDashboardActivity>? activities;
  final void Function(VenuePageQuickAction action)? onQuickAction;

  @override
  Widget build(BuildContext context) {
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
            VenueDashboardRecentActivityPanel(activities: activities ?? const []),
            const SizedBox(height: AppSpacing.lg),
            const VenueDashboardGoPremiumPanel(),
          ],
        ),
      ),
    );
  }
}
