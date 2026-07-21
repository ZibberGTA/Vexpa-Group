import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/breakpoints.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/vexcore/web_vexcore.dart';
import '../../data/venue_management_activity_service.dart';
import '../../models/venue_dashboard_tab.dart';
import '../../models/venue_dashboard_tab_activity.dart';
import '../../models/venue_page_config.dart';
import '../../models/venue_page_quick_action.dart';
import '../../presentation/venue_management_activity_presentation.dart';
import '../../presentation/venue_management_activity_presentation_mapper.dart';
import '../venue_dashboard_controller.dart';
import '../venue_dashboard_right_column.dart';
import '../venue_dashboard_recent_activity_panel.dart';
import '../venue_management_page_activity_controller.dart';
import 'venue_dashboard_page_widgets.dart';
import 'venue_management_tab_pages.dart';

/// Standard venue management page layout with header, workspace and sidebar.
class VenueDashboardPageScaffold extends StatefulWidget {
  const VenueDashboardPageScaffold({
    super.key,
    required this.tab,
    required this.mainContent,
    this.onPrimaryAction,
    this.onQuickAction,
    this.quickActionsOverride,
    this.primaryActionLabelOverride,
    this.primaryActionIconOverride,
    this.showRightColumn = true,
    this.activityLimit = VenueDashboardRecentActivityPanel.maxItems,
    VenueManagementActivityService? activityService,
    VenueManagementActivityPresentationMapper? activityPresentationMapper,
  }) : _activityService = activityService,
       _activityPresentationMapper = activityPresentationMapper;

  final VenueDashboardTab tab;
  final Widget mainContent;
  final VoidCallback? onPrimaryAction;
  final void Function(VenuePageQuickAction action)? onQuickAction;
  final List<VenuePageQuickAction>? quickActionsOverride;
  final String? primaryActionLabelOverride;
  final IconData? primaryActionIconOverride;
  final bool showRightColumn;
  final int activityLimit;
  final VenueManagementActivityService? _activityService;
  final VenueManagementActivityPresentationMapper? _activityPresentationMapper;

  @override
  State<VenueDashboardPageScaffold> createState() =>
      _VenueDashboardPageScaffoldState();
}

class _VenueDashboardPageScaffoldState extends State<VenueDashboardPageScaffold> {
  late final VenueManagementActivityService _activityService =
      widget._activityService ?? WebVexCore.venueManagementActivityService;
  late final VenueManagementActivityPresentationMapper _activityMapper =
      widget._activityPresentationMapper ??
      const VenueManagementActivityPresentationMapper();

  List<VenueManagementActivityPresentation>? _recentActivity;
  bool _loadingRecentActivity = false;
  Object? _recentActivityError;
  String? _loadedVenueId;
  String? _loadedSourceArea;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    scheduleMicrotask(_loadPageActivityIfNeeded);
  }

  @override
  void didUpdateWidget(covariant VenueDashboardPageScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tab != widget.tab) {
      scheduleMicrotask(_loadPageActivityIfNeeded);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final venueId = VenueDashboardController.maybeOf(context)?.contextData.venueId;
    final sourceArea = widget.tab.activitySourceArea;
    if (venueId != _loadedVenueId || sourceArea != _loadedSourceArea) {
      scheduleMicrotask(_loadPageActivityIfNeeded);
    }
  }

  Future<void> _loadPageActivityIfNeeded() async {
    final sourceArea = widget.tab.activitySourceArea;
    final venueId = VenueDashboardController.maybeOf(context)?.contextData.venueId;

    if (sourceArea == null || venueId == null || venueId.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _recentActivity = const [];
        _loadingRecentActivity = false;
        _recentActivityError = null;
        _loadedVenueId = venueId;
        _loadedSourceArea = sourceArea;
      });
      return;
    }

    final generation = ++_loadGeneration;

    setState(() {
      _loadingRecentActivity = true;
      _recentActivityError = null;
      if (_loadedVenueId != venueId || _loadedSourceArea != sourceArea) {
        _recentActivity = null;
      }
    });

    try {
      final records = await _activityService.loadRecentActivityForSourceArea(
        venueId: venueId,
        sourceArea: sourceArea,
        limit: widget.activityLimit,
      );

      if (!mounted || generation != _loadGeneration) return;
      final currentVenueId =
          VenueDashboardController.maybeOf(context)?.contextData.venueId;
      if (currentVenueId != venueId ||
          widget.tab.activitySourceArea != sourceArea) {
        return;
      }

      setState(() {
        _recentActivity = records.map(_activityMapper.map).toList(growable: false);
        _loadedVenueId = venueId;
        _loadedSourceArea = sourceArea;
        _loadingRecentActivity = false;
      });
    } catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _recentActivityError = error;
        _loadingRecentActivity = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.tab.pageConfig;
    final quickActions = widget.quickActionsOverride ?? config.quickActions;
    final primaryActionLabel =
        widget.primaryActionLabelOverride ?? config.primaryActionLabel;
    final primaryActionIcon =
        widget.primaryActionIconOverride ?? config.primaryActionIcon;
    final sideBySide = Breakpoints.isDesktop(context);

    final mainColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VenueDashboardPageHeader(
          title: config.title,
          subtitle: config.subtitle,
          primaryActionLabel: primaryActionLabel,
          primaryActionIcon: primaryActionIcon,
          onPrimaryAction: widget.onPrimaryAction ??
              (primaryActionLabel == null
                  ? null
                  : () => showVenuePagePlaceholderAction(
                        context,
                        primaryActionLabel,
                      )),
        ),
        const SizedBox(height: AppSpacing.xl),
        widget.mainContent,
      ],
    );

    final pageBody = sideBySide && widget.showRightColumn
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: mainColumn),
              const SizedBox(width: AppSpacing.xl),
              VenueDashboardRightColumn(
                quickActions: quickActions,
                onQuickAction: widget.onQuickAction,
                pageRecentActivity: _recentActivity,
                isLoadingPageRecentActivity: _loadingRecentActivity,
                pageRecentActivityError: _recentActivityError,
                onRetryPageRecentActivity: _loadPageActivityIfNeeded,
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              mainColumn,
              if (widget.showRightColumn) ...[
                const SizedBox(height: AppSpacing.xl),
                VenueDashboardRightColumn(
                  expanded: true,
                  quickActions: quickActions,
                  onQuickAction: widget.onQuickAction,
                  pageRecentActivity: _recentActivity,
                  isLoadingPageRecentActivity: _loadingRecentActivity,
                  pageRecentActivityError: _recentActivityError,
                  onRetryPageRecentActivity: _loadPageActivityIfNeeded,
                ),
              ],
            ],
          );

    return VenueManagementPageActivityController(
      reload: _loadPageActivityIfNeeded,
      recentActivity: _recentActivity,
      isLoadingRecentActivity: _loadingRecentActivity,
      recentActivityError: _recentActivityError,
      child: pageBody,
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
