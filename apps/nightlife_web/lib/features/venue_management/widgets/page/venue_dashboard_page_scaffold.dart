import 'package:flutter/material.dart';

import '../../../../core/constants/breakpoints.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../models/venue_dashboard_activity.dart';
import '../../models/venue_dashboard_tab.dart';
import '../../models/venue_page_config.dart';
import '../../models/venue_page_quick_action.dart';
import '../venue_dashboard_right_column.dart';
import 'venue_dashboard_page_widgets.dart';
import 'venue_management_tab_pages.dart';

/// Standard venue management page layout with header, workspace and sidebar.
class VenueDashboardPageScaffold extends StatelessWidget {
  const VenueDashboardPageScaffold({
    super.key,
    required this.tab,
    required this.mainContent,
    this.onPrimaryAction,
    this.onQuickAction,
    this.activities,
    this.quickActionsOverride,
    this.primaryActionLabelOverride,
    this.primaryActionIconOverride,
    this.showRightColumn = true,
  });

  final VenueDashboardTab tab;
  final Widget mainContent;
  final VoidCallback? onPrimaryAction;
  final void Function(VenuePageQuickAction action)? onQuickAction;
  final List<VenueDashboardActivity>? activities;
  final List<VenuePageQuickAction>? quickActionsOverride;
  final String? primaryActionLabelOverride;
  final IconData? primaryActionIconOverride;
  final bool showRightColumn;

  @override
  Widget build(BuildContext context) {
    final config = tab.pageConfig;
    final quickActions = quickActionsOverride ?? config.quickActions;
    final primaryActionLabel =
        primaryActionLabelOverride ?? config.primaryActionLabel;
    final primaryActionIcon =
        primaryActionIconOverride ?? config.primaryActionIcon;
    final sideBySide = Breakpoints.isDesktop(context);

    final mainColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VenueDashboardPageHeader(
          title: config.title,
          subtitle: config.subtitle,
          primaryActionLabel: primaryActionLabel,
          primaryActionIcon: primaryActionIcon,
          onPrimaryAction: onPrimaryAction ??
              (primaryActionLabel == null
                  ? null
                  : () => showVenuePagePlaceholderAction(
                        context,
                        primaryActionLabel,
                      )),
        ),
        const SizedBox(height: AppSpacing.xl),
        mainContent,
      ],
    );

    if (sideBySide && showRightColumn) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: mainColumn),
          const SizedBox(width: AppSpacing.xl),
          VenueDashboardRightColumn(
            quickActions: quickActions,
            activities: activities ?? config.recentActivity,
            onQuickAction: onQuickAction,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        mainColumn,
        if (showRightColumn) ...[
          const SizedBox(height: AppSpacing.xl),
          VenueDashboardRightColumn(
            expanded: true,
            quickActions: quickActions,
            activities: activities ?? config.recentActivity,
            onQuickAction: onQuickAction,
          ),
        ],
      ],
    );
  }
}

/// Resolves a standard venue management page for the given tab.
class VenueManagementTabPage extends StatelessWidget {
  const VenueManagementTabPage({
    super.key,
    required this.tab,
  });

  final VenueDashboardTab tab;

  @override
  Widget build(BuildContext context) {
    return VenueDashboardPageScaffold(
      tab: tab,
      mainContent: VenueManagementTabPages.contentFor(tab),
    );
  }
}
