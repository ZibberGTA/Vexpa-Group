import 'package:flutter/material.dart';

import '../../../core/constants/breakpoints.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/venue_images_repository.dart';
import '../models/venue_dashboard_context.dart';
import '../models/venue_dashboard_date_range.dart';
import '../models/venue_dashboard_home_data.dart';
import '../models/venue_dashboard_tab.dart';
import 'venue_dashboard_controller.dart';
import 'venue_dashboard_layout.dart';
import 'venue_dashboard_page_transition.dart';
import 'venue_dashboard_sidebar.dart';
import 'venue_dashboard_tab_content_view.dart';
import 'venue_dashboard_top_bar.dart';

/// Reusable desktop shell for the Vexda venue management dashboard.
class VenueDashboardShell extends StatefulWidget {
  const VenueDashboardShell({
    super.key,
    required this.contextData,
    this.initialTab = VenueDashboardTab.dashboard,
    this.onTabSelected,
    this.homeData,
    this.isLoadingHomeData = false,
    this.onRefreshHomeData,
    this.onDateRangeChanged,
  });

  const VenueDashboardShell.loading({super.key})
    : contextData = null,
      initialTab = VenueDashboardTab.dashboard,
      onTabSelected = null,
      homeData = null,
      isLoadingHomeData = true,
      onRefreshHomeData = null,
      onDateRangeChanged = null;

  final VenueDashboardContext? contextData;
  final VenueDashboardTab initialTab;
  final ValueChanged<VenueDashboardTab>? onTabSelected;
  final VenueDashboardHomeData? homeData;
  final bool isLoadingHomeData;
  final Future<void> Function()? onRefreshHomeData;
  final Future<void> Function(VenueDashboardDateRange range)?
  onDateRangeChanged;

  @override
  State<VenueDashboardShell> createState() => VenueDashboardShellState();
}

class VenueDashboardShellState extends State<VenueDashboardShell> {
  late VenueDashboardTab _selectedTab =
      widget.initialTab == VenueDashboardTab.map
      ? VenueDashboardTab.dashboard
      : widget.initialTab;
  late bool _sidebarExpanded;
  bool _compactLayoutResolved = false;
  final _venueImagesRepository = VenueImagesRepository();

  @override
  void initState() {
    super.initState();
    _sidebarExpanded = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_compactLayoutResolved) {
      _sidebarExpanded = !_isCompact(context);
      _compactLayoutResolved = true;
    }
  }

  void _toggleSidebar() {
    setState(() => _sidebarExpanded = !_sidebarExpanded);
  }

  void _selectTab(VenueDashboardTab tab) {
    if (tab.opensPublicMap) {
      Navigator.pushNamed(context, AppRouter.map);
      return;
    }

    setState(() => _selectedTab = tab);
    widget.onTabSelected?.call(tab);
  }

  bool _isCompact(BuildContext context) {
    return Breakpoints.isMobile(context) || Breakpoints.isTablet(context);
  }

  @override
  Widget build(BuildContext context) {
    final contextData = widget.contextData;
    if (contextData == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(color: AppColors.primaryPink),
              SizedBox(height: AppSpacing.lg),
              Text(
                'Loading your venue dashboard…',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final compact = _isCompact(context);
    final inlineSidebarExpanded = compact ? false : _sidebarExpanded;

    return StreamBuilder<Map<String, dynamic>?>(
      stream: _venueImagesRepository.watchVenueDocument(contextData.venueId),
      builder: (context, venueSnapshot) {
        final liveContext = contextData.withVenueDocument(venueSnapshot.data);

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  VenueDashboardTopBar(
                    contextData: liveContext,
                    onNotificationsTap: () {},
                  ),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!compact || !_sidebarExpanded)
                          ClipRect(
                            clipBehavior: Clip.none,
                            child: VenueDashboardSidebar(
                              contextData: liveContext,
                              expanded: inlineSidebarExpanded,
                              selectedTab: _selectedTab,
                              onTabSelected: _selectTab,
                              venueDocument: venueSnapshot.data,
                              onToggleSidebar: _toggleSidebar,
                            ),
                          ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(
                              compact ? AppSpacing.lg : AppSpacing.xl,
                            ),
                            child: VenueDashboardController(
                              selectTab: _selectTab,
                              contextData: liveContext,
                              homeData: widget.homeData,
                              isLoadingHomeData: widget.isLoadingHomeData,
                              onRefreshHomeData: widget.onRefreshHomeData,
                              onDateRangeChanged: widget.onDateRangeChanged,
                              child: AnimatedSwitcher(
                                duration: VenueDashboardPageTransition.duration,
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                transitionBuilder:
                                    VenueDashboardPageTransition.builder,
                                layoutBuilder:
                                    (currentChild, previousChildren) {
                                      return Stack(
                                        alignment: Alignment.topCenter,
                                        children: [
                                          ...previousChildren,
                                          ?currentChild,
                                        ],
                                      );
                                    },
                                child: VenueDashboardTabContentView(
                                  key: ValueKey(_selectedTab),
                                  tab: _selectedTab,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (compact && _sidebarExpanded) ...[
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _toggleSidebar,
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.45),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: VenueDashboardLayout.topBarHeight,
                  bottom: 0,
                  child: Material(
                    color: Colors.transparent,
                    child: ClipRect(
                      clipBehavior: Clip.none,
                      child: VenueDashboardSidebar(
                        contextData: liveContext,
                        expanded: true,
                        selectedTab: _selectedTab,
                        venueDocument: venueSnapshot.data,
                        onToggleSidebar: _toggleSidebar,
                        onTabSelected: (tab) {
                          _selectTab(tab);
                          _toggleSidebar();
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
