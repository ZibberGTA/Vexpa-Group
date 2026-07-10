import 'package:nightlife_web/features/venue_management/models/venue_dashboard_activity.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_date_range.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_home_data.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_stat.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_tab.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_whats_next_action.dart';
import 'package:nightlife_web/features/venue_management/models/venue_profile_completion.dart';
import 'package:flutter/material.dart';

/// Shared dashboard home data for widget tests.
class VenueDashboardTestData {
  VenueDashboardTestData._();

  static VenueDashboardHomeData sampleHomeData({
    VenueProfileCompletion? completion,
  }) {
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
      recentActivity: const [
        VenueDashboardActivity(
          title: 'Venue profile updated',
          timestampLabel: '2 hours ago',
          icon: Icons.storefront_outlined,
        ),
      ],
    );
  }
}
