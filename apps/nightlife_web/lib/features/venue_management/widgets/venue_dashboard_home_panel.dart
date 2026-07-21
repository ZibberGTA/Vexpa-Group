import 'package:flutter/material.dart';

import '../../../core/constants/breakpoints.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/venue_dashboard_home_data.dart';
import 'venue_dashboard_controller.dart';
import 'venue_dashboard_main_content.dart';
import 'venue_dashboard_next_seven_days_section.dart';
import 'venue_dashboard_performance_highlights_section.dart';
import 'venue_dashboard_right_column.dart';
import 'venue_dashboard_whats_next_section.dart';

/// Home panel for the venue management dashboard with main content and right column.
class VenueDashboardHomePanel extends StatelessWidget {
  const VenueDashboardHomePanel({super.key});

  static List<Widget> _lowerSections(VenueDashboardController? controller) {
    final homeData = controller?.homeData;
    final loading = controller?.isLoadingHomeData ?? false;

    return [
      const SizedBox(height: AppSpacing.xl),
      VenueDashboardNextSevenDaysSection(
        schedule: homeData?.nextSevenDaysSchedule ??
            VenueDashboardHomeData.empty().nextSevenDaysSchedule,
        loading: loading,
      ),
      const SizedBox(height: AppSpacing.xl),
      VenueDashboardPerformanceHighlightsSection(
        highlights: homeData?.highlights ??
            VenueDashboardInsightsBuilder.setupHighlights(),
      ),
      const SizedBox(height: AppSpacing.xl),
      VenueDashboardWhatsNextSection(
        actions: homeData?.whatsNext ?? const [],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final controller = VenueDashboardController.maybeOf(context);
    final sideBySide = Breakpoints.isDesktop(context);
    final lowerSections = _lowerSections(controller);

    if (sideBySide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const VenueDashboardMainContent(),
                ...lowerSections,
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          const VenueDashboardRightColumn(useControllerFeed: true),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const VenueDashboardMainContent(),
        ...lowerSections,
        const SizedBox(height: AppSpacing.xl),
        const VenueDashboardRightColumn(
          expanded: true,
          useControllerFeed: true,
        ),
      ],
    );
  }
}
