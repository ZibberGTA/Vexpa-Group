import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../models/venue_dashboard_date_range.dart';
import '../models/venue_dashboard_home_data.dart';
import '../models/venue_dashboard_stat.dart';
import '../models/venue_profile_views_chart_data.dart';
import 'venue_dashboard_controller.dart';
import 'venue_dashboard_insights_section.dart';
import 'venue_dashboard_stats_row.dart';
import 'venue_dashboard_welcome_header.dart';

/// Upper main content for the venue dashboard home tab (welcome through insights).
class VenueDashboardMainContent extends StatefulWidget {
  const VenueDashboardMainContent({super.key});

  @override
  State<VenueDashboardMainContent> createState() =>
      _VenueDashboardMainContentState();
}

class _VenueDashboardMainContentState extends State<VenueDashboardMainContent> {
  VenueDashboardDateRange _summaryRange = VenueDashboardDateRange.defaultRange;
  VenueDashboardDateRange _chartRange = VenueDashboardDateRange.defaultRange;
  List<VenueProfileViewsDataPoint> _chartPoints = const [];
  bool _chartInitialized = false;
  bool _chartLoading = false;

  void _initializeChartFromHomeData(VenueDashboardHomeData homeData) {
    if (_chartInitialized) return;

    _chartInitialized = true;
    _chartRange = homeData.dateRange;
    _chartPoints = homeData.chartPoints;
  }

  @override
  Widget build(BuildContext context) {
    final controller = VenueDashboardController.maybeOf(context);
    final homeData = controller?.homeData;
    final loading = controller?.isLoadingHomeData ?? false;
    final stats = homeData?.stats ?? VenueDashboardStatsData.empty();

    if (homeData != null) {
      if (homeData.dateRange != _summaryRange) {
        _summaryRange = homeData.dateRange;
      }
      if (!loading) {
        _initializeChartFromHomeData(homeData);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VenueDashboardWelcomeHeader(
          selectedRange: _summaryRange,
          onRangeChanged: (range) async {
            setState(() => _summaryRange = range);
            await controller?.onDateRangeChanged?.call(range);
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        if (loading)
          const _DashboardStatsLoadingRow()
        else
          VenueDashboardStatsRow(
            stats: stats,
            dateRange: _summaryRange,
          ),
        const SizedBox(height: AppSpacing.xl),
        VenueDashboardInsightsSection(
          loading: (!_chartInitialized && loading) || _chartLoading,
          profileCompletion: homeData?.profileCompletion,
          chartPoints: _chartPoints,
          chartRange: _chartRange,
          onChartRangeChanged: (range) async {
            setState(() {
              _chartRange = range;
              _chartLoading = true;
            });

            final points =
                await controller?.onChartDateRangeChanged?.call(range);
            if (!mounted) return;

            setState(() {
              _chartLoading = false;
              if (points != null) {
                _chartPoints = points;
              }
            });
          },
        ),
      ],
    );
  }
}

class _DashboardStatsLoadingRow extends StatelessWidget {
  const _DashboardStatsLoadingRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: List.generate(
        5,
        (_) => Container(
          width: 160,
          height: 112,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            color: Colors.white.withValues(alpha: 0.04),
          ),
        ),
      ),
    );
  }
}
