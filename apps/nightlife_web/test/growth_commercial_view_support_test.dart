import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/features/venue_management/data/growth_commercial_view_support.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_context.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_date_range.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_home_data.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_stat.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_tab.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_whats_next_action.dart';
import 'package:nightlife_web/features/venue_management/models/venue_profile_completion.dart';
import 'package:nightlife_web/features/venue_management/widgets/venue_dashboard_controller.dart';
import 'package:vex_engines/growth/growth_engine.dart';

void main() {
  group('GrowthCommercialViewSupport', () {
    test('builds subscription plan cards from Growth product catalog', () {
      final snapshot = GrowthCommercialViewSupport.build(
        const GrowthCommercialSnapshotInput(
          subscriptionPlanId: 'starter',
          activeVenueCount: 1,
          homeData: null,
        ),
      );

      expect(snapshot.planCards.length, 3);
      expect(snapshot.planCards.first.name, 'Starter');
      expect(snapshot.planCards.first.price, '£25');
      expect(snapshot.planCards[1].name, 'Professional');
      expect(snapshot.planCards.last.name, 'Premium');
    });

    test('derives marketing metrics from dashboard home stats', () {
      final snapshot = GrowthCommercialViewSupport.build(
        GrowthCommercialSnapshotInput(
          subscriptionPlanId: 'professional',
          activeVenueCount: 1,
          homeData: VenueDashboardHomeData(
            dateRange: VenueDashboardDateRange.lastMonth,
            stats: VenueDashboardStatsData.fromAnalytics(
              profileViews: 100,
              saves: 20,
              drinkViews: 10,
              dealViews: 15,
              eventViews: 5,
            ),
            chartPoints: const [],
            profileCompletion: const VenueProfileCompletion(
              completedSteps: 8,
              totalSteps: 10,
            ),
            highlights: const [],
            whatsNext: const [
              VenueDashboardWhatsNextAction(
                title: 'Add an upcoming event',
                message: 'Events bring more people through the door.',
                buttonLabel: 'Add event',
                icon: Icons.event_outlined,
                targetTab: VenueDashboardTab.events,
              ),
            ],
            recentActivity: const [],
            analyticsAvailable: true,
          ),
        ),
      );

      expect(snapshot.marketingMetrics.length, 4);
      expect(snapshot.commercialSummary.marketing.performance.roiSignalLabel,
          'Strong');
      expect(snapshot.recommendationCards, isNotEmpty);
      expect(snapshot.goalCards.length, 4);
      expect(snapshot.forecastRevenueLabel, contains('forecast'));
    });

    test('surfaces renewal prompt when expiry is within 14 days', () {
      final snapshot = GrowthCommercialViewSupport.build(
        const GrowthCommercialSnapshotInput(
          subscriptionPlanId: 'professional',
          activeVenueCount: 1,
          daysUntilExpiry: 7,
        ),
      );

      expect(snapshot.renewalPrompt, isNotNull);
      expect(snapshot.renewalPrompt, contains('7 days'));
      expect(snapshot.subscriptionRecommendations, isNotEmpty);
    });

    test('fromDashboard delegates through controller context and home data', () {
      final controller = VenueDashboardController(
        selectTab: (_) {},
        contextData: const VenueDashboardContext(
          ownerName: 'Alex Morgan',
          ownerFirstName: 'Alex',
          venueName: 'Copper Lantern',
          venueId: 'venue-1',
          subscriptionPlanId: 'starter',
          daysUntilSubscriptionRenewal: 3,
        ),
        homeData: VenueDashboardHomeData.empty(),
        child: const SizedBox.shrink(),
      );

      final snapshot = GrowthCommercialViewSupport.fromDashboard(controller);

      expect(snapshot.planCards.first.state,
          GrowthSubscriptionPlanCardState.current);
      expect(snapshot.campaignSummary.status, isA<CampaignCompletionStatus>());
      expect(snapshot.goPremiumTitle, isNotEmpty);
    });
  });
}
