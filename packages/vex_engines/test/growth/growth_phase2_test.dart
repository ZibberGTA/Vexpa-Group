import 'package:test/test.dart';
import 'package:vex_engines/growth/growth_engine.dart';

void main() {
  const subscriptionService = GrowthSubscriptionService();
  const campaignLifecycleService = GrowthCampaignLifecycleService();
  const marketingSummaryService = GrowthMarketingSummaryService();
  const commercialService = GrowthCommercialService();
  const boostLifecycleService = GrowthBoostLifecycleService();
  const scoringService = GrowthScoringService();
  const performanceService = GrowthPerformanceInterpretationService();

  group('GrowthSubscriptionService', () {
    test('recommends upgrade, renewal, and trial in deterministic order', () {
      final items = subscriptionService.subscriptionRecommendations(
        currentPlanId: 'starter',
        hasMediaCentreAccess: false,
        hasAdvancedAnalyticsAccess: false,
        hasCampaignToolsAccess: false,
        underutilizedPremiumFeatures: false,
        activeVenueCount: 1,
        daysUntilExpiry: 5,
        growthScoreValue: 70,
        hasActiveSubscription: false,
        hasPublishedContent: true,
      );

      expect(items, isNotEmpty);
      expect(items.first.kind, SubscriptionRecommendationKind.upgrade);
      expect(
        items.map((item) => item.kind),
        contains(SubscriptionRecommendationKind.trial),
      );
    });

    test('recommends downgrade for underutilized corporate plan', () {
      final downgrade = subscriptionService.recommendDowngrade(
        currentPlanId: 'corporate',
        underutilizedPremiumFeatures: true,
        activeVenueCount: 2,
      );
      expect(downgrade?.targetPlanId, 'premium');
    });

    test('builds product summary with discounted launch price', () {
      final summary = subscriptionService.productSummary('professional');
      expect(summary?.monthlyPriceGbp, 99);
      expect(summary?.discountedMonthlyPriceGbp, 50);
    });
  });

  group('GrowthCampaignLifecycleService', () {
    test('assesses campaign health and completion status', () {
      final readiness = campaignLifecycleService.assessReadiness(
        hasUpcomingDealOrEvent: true,
        hasGalleryPhotos: true,
        hasActiveBoost: true,
        hasDraftCampaign: false,
        notificationsEnabled: true,
      );
      final health = campaignLifecycleService.assessHealth(
        readiness: readiness,
        hasActiveBoost: true,
        notificationOpenRatePercent: 25,
        impressions: 600,
      );
      expect(health.label, 'Healthy');

      final status = campaignLifecycleService.completionStatus(
        hasDraftCampaign: false,
        hasScheduledCampaign: false,
        hasLiveCampaign: true,
        campaignEnded: false,
      );
      expect(status, CampaignCompletionStatus.live);
    });

    test('recommends campaign fixes when requirements missing', () {
      final summary = campaignLifecycleService.summarize(
        hasUpcomingDealOrEvent: false,
        hasGalleryPhotos: false,
        hasActiveBoost: false,
        hasDraftCampaign: true,
        hasScheduledCampaign: false,
        hasLiveCampaign: false,
        campaignEnded: false,
        notificationsEnabled: true,
        notificationOpenRatePercent: 0,
        impressions: 0,
      );
      expect(summary.health.label, isNot('Healthy'));
      expect(summary.recommendations, isNotEmpty);
    });
  });

  group('GrowthMarketingSummaryService', () {
    test('builds ROI and conversion summaries', () {
      const input = GrowthPerformanceInput(
        venueViews: 100,
        favouriteTaps: 20,
        dealViews: 10,
        eventViews: 10,
        conversionRatePercent: 8,
      );
      final performance = marketingSummaryService.buildPerformanceSummary(input);
      final roi = marketingSummaryService.buildRoiSummary(performance);
      final conversion = marketingSummaryService.buildConversionSummary(
        conversionRatePercent: 8,
        venueViews: 100,
      );

      expect(roi.estimatedVisits, greaterThan(0));
      expect(conversion.label, 'Healthy conversion');
    });
  });

  group('GrowthCommercialService', () {
    test('formats pricing and renewal prompts', () {
      expect(
        commercialService.pricingLabel(
          monthlyPriceGbp: 99,
          includeLaunchDiscount: true,
        ),
        contains('50'),
      );
      expect(
        commercialService.renewalPrompt(daysUntilRenewal: 3),
        contains('3 days'),
      );
    });

    test('forecasts revenue over multiple months', () {
      const performance = GrowthPerformance(
        estimatedVisits: 10,
        estimatedRevenueGbp: 180,
        roiSignalLabel: 'Good',
        insightMessage: '',
        revenueInsightMessage: '',
      );
      expect(commercialService.forecastRevenueGbp(performance: performance, months: 3), 540);
    });
  });

  group('GrowthBoostLifecycleService', () {
    test('suggests renewal before boost expiry', () {
      final now = DateTime.utc(2026, 7, 10);
      final recommendation = boostLifecycleService.renewalRecommendation(
        activeBoost: GrowthActiveBoost(
          active: true,
          planId: 'boost_7d',
          endsAt: now.add(const Duration(days: 2)),
        ),
        performance: const GrowthPerformance(
          estimatedVisits: 10,
          estimatedRevenueGbp: 180,
          roiSignalLabel: 'Strong',
          insightMessage: '',
          revenueInsightMessage: '',
        ),
        now: now,
      );
      expect(recommendation?.suggestedPlanId, 'boost_30d');
    });

    test('suggests boost plan and timing', () {
      final suggestion = boostLifecycleService.composeSuggestion(
        performance: const GrowthPerformance(
          estimatedVisits: 20,
          estimatedRevenueGbp: 360,
          roiSignalLabel: 'Strong',
          insightMessage: '',
          revenueInsightMessage: '',
        ),
        hasUpcomingEvent: true,
        hasWeekendDeal: false,
      );
      expect(suggestion?.plan.id, 'boost_24h');
      expect(suggestion?.timingLabel, contains('48 hours'));
    });
  });

  group('GrowthScoringService venue scores', () {
    test('returns multi-dimensional venue growth scores', () {
      const performance = GrowthPerformance(
        estimatedVisits: 20,
        estimatedRevenueGbp: 360,
        roiSignalLabel: 'Strong',
        insightMessage: '',
        revenueInsightMessage: '',
      );
      final scores = scoringService.venueScores(
        performance: performance,
        profileCompletionRemaining: 0,
        hasActiveBoost: true,
        hasUpcomingDealOrEvent: true,
        hasCampaignToolsAccess: true,
        dealCount: 2,
      );
      expect(scores.growthScore, greaterThan(scores.revenueScore ~/ 2));
      expect(scores.marketingScore, greaterThan(50));
    });
  });

  group('Malformed inputs', () {
    test('handles empty plan ids and zero engagement safely', () {
      expect(subscriptionService.productSummary(''), isNull);
      expect(
        performanceService.roiSignalLabel(const GrowthPerformanceInput()),
        'New',
      );
      expect(
        commercialService.renewalPrompt(daysUntilRenewal: 999),
        isNull,
      );
    });
  });
}
