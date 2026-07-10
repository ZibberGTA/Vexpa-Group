import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../models/venue_dashboard_date_range.dart';
import '../models/venue_dashboard_stat.dart';
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
  VenueDashboardDateRange _selectedRange = VenueDashboardDateRange.defaultRange;

  @override
  Widget build(BuildContext context) {
    final controller = VenueDashboardController.maybeOf(context);
    final homeData = controller?.homeData;
    final loading = controller?.isLoadingHomeData ?? false;
    final stats = homeData?.stats ?? VenueDashboardStatsData.empty();

    if (homeData != null && homeData.dateRange != _selectedRange) {
      _selectedRange = homeData.dateRange;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VenueDashboardWelcomeHeader(
          selectedRange: _selectedRange,
          onRangeChanged: (range) async {
            setState(() => _selectedRange = range);
            await controller?.onDateRangeChanged?.call(range);
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        if (loading)
          const _DashboardStatsLoadingRow()
        else
          VenueDashboardStatsRow(
            stats: stats,
            dateRange: _selectedRange,
          ),
        const SizedBox(height: AppSpacing.xl),
        VenueDashboardInsightsSection(
          loading: loading,
          profileCompletion: homeData?.profileCompletion,
          chartPoints: homeData?.chartPoints,
          chartRange: _selectedRange,
          onChartRangeChanged: (range) async {
            setState(() => _selectedRange = range);
            await controller?.onDateRangeChanged?.call(range);
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
