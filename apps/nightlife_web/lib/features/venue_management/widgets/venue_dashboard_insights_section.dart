import 'package:flutter/material.dart';

import '../../../core/constants/breakpoints.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/venue_dashboard_date_range.dart';
import '../models/venue_profile_completion.dart';
import '../models/venue_profile_views_chart_data.dart';
import 'venue_dashboard_layout.dart';
import 'venue_dashboard_profile_completion_card.dart';
import 'venue_dashboard_profile_views_chart_panel.dart';

/// Graph and profile completion panels below the dashboard stat cards.
class VenueDashboardInsightsSection extends StatelessWidget {
  const VenueDashboardInsightsSection({
    super.key,
    this.loading = false,
    this.profileCompletion,
    this.chartPoints,
    this.chartRange = VenueDashboardDateRange.defaultRange,
    this.onChartRangeChanged,
  });

  final bool loading;
  final VenueProfileCompletion? profileCompletion;
  final List<VenueProfileViewsDataPoint>? chartPoints;
  final VenueDashboardDateRange chartRange;
  final ValueChanged<VenueDashboardDateRange>? onChartRangeChanged;

  @override
  Widget build(BuildContext context) {
    final stackVertically = !Breakpoints.isDesktop(context);
    final completion = profileCompletion ?? VenueProfileCompletion.empty;
    final points = chartPoints ?? const [];

    if (stackVertically) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: VenueDashboardLayout.insightsSectionMinHeight,
            child: VenueDashboardProfileViewsChartPanel(
              loading: loading,
              points: points,
              selectedRange: chartRange,
              onRangeChanged: onChartRangeChanged,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          VenueDashboardProfileCompletionCard(
            completion: completion,
            stretchContent: false,
          ),
        ],
      );
    }

    return SizedBox(
      height: VenueDashboardLayout.insightsSectionMinHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: VenueDashboardLayout.insightsGraphFlex,
            child: VenueDashboardProfileViewsChartPanel(
              loading: loading,
              points: points,
              selectedRange: chartRange,
              onRangeChanged: onChartRangeChanged,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            flex: VenueDashboardLayout.insightsCompletionFlex,
            child: VenueDashboardProfileCompletionCard(completion: completion),
          ),
        ],
      ),
    );
  }
}
