import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/core/constants/subscription_plans.dart';
import 'package:nightlife_web/features/venue_management/data/growth_commercial_support.dart';
import 'package:nightlife_web/features/venue_management/data/growth_commercial_view_support.dart';
import 'package:vex_engines/growth/growth_engine.dart';

void main() {
  group('Web Growth Engine delegation', () {
    test('subscription plans delegate catalog to Growth Engine', () {
      expect(SubscriptionPlans.tiers.length, 4);
      expect(SubscriptionPlans.tiers.first.id, 'starter');
      expect(SubscriptionPlans.discountedPrice(99), 50);
      expect(
        SubscriptionPlans.launchDiscountLabel,
        GrowthProductCatalog.launchDiscountLabel,
      );
    });

    test(
      'GrowthCommercialSupport recommends starter upgrade without media',
      () {
        final recommendation = GrowthCommercialSupport.recommendVenueUpgrade(
          currentPlanId: 'starter',
          hasMediaCentreAccess: false,
          hasAdvancedAnalyticsAccess: false,
          hasCampaignToolsAccess: false,
        );
        expect(recommendation?.recommendedPlanId, 'professional');
      },
    );

    test(
      'GrowthCommercialSupport interprets performance without analytics engine import',
      () {
        final performance = GrowthCommercialSupport.interpretPerformance(
          const GrowthPerformanceInput(
            venueViews: 100,
            favouriteTaps: 20,
            dealViews: 10,
            eventViews: 10,
          ),
        );
        expect(performance.roiSignalLabel, 'Strong');
      },
    );

    test('GrowthCommercialSupport delegates subscription recommendations', () {
      final recommendations = GrowthCommercialSupport.subscriptionRecommendations(
        currentPlanId: 'starter',
        hasMediaCentreAccess: false,
        hasAdvancedAnalyticsAccess: false,
        hasCampaignToolsAccess: false,
        underutilizedPremiumFeatures: false,
        activeVenueCount: 1,
        daysUntilExpiry: 7,
        growthScoreValue: 55,
        hasActiveSubscription: true,
        hasPublishedContent: true,
      );
      expect(recommendations, isNotEmpty);
      expect(
        recommendations.first.kind,
        SubscriptionRecommendationKind.upgrade,
      );
    });

    test('GrowthCommercialSupport delegates campaign lifecycle summary', () {
      final summary = GrowthCommercialSupport.summarizeCampaign(
        hasUpcomingDealOrEvent: true,
        hasGalleryPhotos: true,
        hasActiveBoost: true,
        hasDraftCampaign: false,
        hasScheduledCampaign: false,
        hasLiveCampaign: true,
        campaignEnded: false,
        notificationsEnabled: true,
        notificationOpenRatePercent: 22,
        impressions: 500,
      );
      expect(summary.status, CampaignCompletionStatus.live);
      expect(summary.health.score, greaterThan(50));
    });

    test('GrowthCommercialSupport delegates venue growth scores', () {
      const performance = GrowthPerformance(
        estimatedVisits: 15,
        estimatedRevenueGbp: 270,
        roiSignalLabel: 'Good',
        insightMessage: '',
        revenueInsightMessage: '',
      );
      final scores = GrowthCommercialSupport.venueScores(
        performance: performance,
        profileCompletionRemaining: 1,
        hasActiveBoost: false,
        hasUpcomingDealOrEvent: true,
        hasCampaignToolsAccess: false,
        dealCount: 1,
      );
      expect(scores.growthScore, greaterThan(0));
    });

    test('GrowthCommercialViewSupport builds production snapshot', () {
      final snapshot = GrowthCommercialViewSupport.build(
        const GrowthCommercialSnapshotInput(
          subscriptionPlanId: 'starter',
          activeVenueCount: 1,
        ),
      );

      expect(snapshot.planCards, isNotEmpty);
      expect(snapshot.commercialSummary.forecastRevenueGbp, greaterThanOrEqualTo(0));
      expect(snapshot.campaignSummary.readinessLabel, isNotEmpty);
    });
  });
}
