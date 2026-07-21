import 'package:nightlife_web/features/venue_management/models/venue_dashboard_date_range.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_home_data.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_stat.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_tab.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_whats_next_action.dart';
import 'package:nightlife_web/features/venue_management/models/venue_profile_completion.dart';
import 'package:nightlife_web/features/venue_management/presentation/venue_management_activity_presentation.dart';
import 'package:nightlife_web/features/venue_management/services/venue_dashboard_schedule_service.dart';
import 'package:flutter/material.dart';

/// Shared dashboard home data for widget tests.
class VenueDashboardTestData {
  VenueDashboardTestData._();

  static VenueDashboardHomeData sampleHomeData({
    VenueProfileCompletion? completion,
    DateTime? now,
  }) {
    final clock = now ?? DateTime(2026, 7, 21, 12);
    return VenueDashboardHomeData(
      dateRange: VenueDashboardDateRange.last7Days,
      stats: VenueDashboardStatsData.empty(),
      chartPoints: const [],
      profileCompletion: completion ??
          const VenueProfileCompletion(
            completedSteps: 7,
            totalSteps: 10,
          ),
      highlights: VenueDashboardInsightsBuilder.setupHighlights(),
      whatsNext: const [
        VenueDashboardWhatsNextAction(
          title: 'Create a new deal',
          message: 'Deals increase customer engagement.',
          buttonLabel: 'Create deal',
          icon: Icons.local_offer_outlined,
          targetTab: VenueDashboardTab.deals,
        ),
      ],
      nextSevenDaysSchedule: VenueDashboardScheduleService().compose(
        events: const [],
        deals: const [],
        now: clock,
      ),
    );
  }

  static List<VenueManagementActivityPresentation> sampleRecentManagementActivity() {
    return const [
      VenueManagementActivityPresentation(
        icon: Icons.storefront_outlined,
        title: 'Venue profile updated',
        description: 'Venue information was changed',
        actorDisplayName: 'Alex Morgan',
        timestampLabel: '2 hours ago',
      ),
    ];
  }
}
