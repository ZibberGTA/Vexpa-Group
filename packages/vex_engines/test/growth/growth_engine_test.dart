import 'package:test/test.dart';
import 'package:vex_engines/growth/growth_engine.dart';

void main() {
  const boostService = GrowthBoostService();
  const performanceService = GrowthPerformanceInterpretationService();
  const upgradeService = GrowthUpgradeService();
  const campaignService = GrowthCampaignReadinessService();
  const comparisonService = GrowthComparisonService();
  const scoringService = GrowthScoringService();
  const recommendationService = GrowthRecommendationService();
  const summaryService = GrowthSummaryService();

  group('GrowthBoostService', () {
    test('detects active boost before endsAt', () {
      final now = DateTime.utc(2026, 7, 10);
      expect(
        boostService.isBoostActive(
          active: true,
          endsAt: now.add(const Duration(hours: 1)),
          now: now,
        ),
        isTrue,
      );
    });

    test('marks expired boosts inactive', () {
      final now = DateTime.utc(2026, 7, 10);
      expect(
        boostService.isBoostActive(
          active: true,
          endsAt: now.subtract(const Duration(minutes: 1)),
          now: now,
        ),
        isFalse,
      );
    });

    test('prepares activation payload for valid plan', () {
      final startedAt = DateTime.utc(2026, 7, 10, 12);
      final result = boostService.prepareActivation(
        venueId: 'venue-1',
        venueName: 'Red Lion',
        ownerId: 'owner-1',
        planId: 'boost_24h',
        startedAt: startedAt,
        paymentStatus: 'paid',
      );

      expect(result, isA<GrowthSuccess<GrowthBoostActivationPayload>>());
      final payload =
          (result as GrowthSuccess<GrowthBoostActivationPayload>).value;
      expect(payload.plan.id, 'boost_24h');
      expect(payload.endsAt, startedAt.add(const Duration(days: 1)));
      expect(payload.toAdapterFields()['boostScore'], 35);
    });

    test('rejects invalid boost plan', () {
      final result = boostService.prepareActivation(
        venueId: 'venue-1',
        venueName: 'Red Lion',
        ownerId: 'owner-1',
        planId: 'invalid',
        startedAt: DateTime.utc(2026, 7, 10),
      );
      expect((result as GrowthFailure).code, 'invalid-boost-plan');
    });

    test('validates paid checkout statuses', () {
      expect(
        boostService.validatePaidCheckout(
          paymentStatus: 'paid',
          sessionStatus: null,
        ),
        isA<GrowthSuccess<void>>(),
      );
      expect(
        (boostService.validatePaidCheckout(
                  paymentStatus: 'open',
                  sessionStatus: 'open',
                )
                as GrowthFailure)
            .code,
        'checkout-not-paid',
      );
    });

    test('detects active boost conflict', () {
      final now = DateTime.utc(2026, 7, 10);
      final conflict = boostService.detectActivationConflict(
        existingBoost: GrowthActiveBoost(
          active: true,
          planId: 'boost_7d',
          endsAt: now.add(const Duration(days: 2)),
        ),
        now: now,
      );
      expect((conflict as GrowthFailure).code, 'boost-already-active');
    });
  });

  group('GrowthPerformanceInterpretationService', () {
    test('estimates visits and revenue using thresholds', () {
      const input = GrowthPerformanceInput(
        venueViews: 100,
        favouriteTaps: 10,
        dealViews: 5,
        eventViews: 5,
        conversionRatePercent: 8,
      );
      expect(performanceService.estimatedVisits(input), 15);
      expect(performanceService.estimatedRevenueGbp(input), 270);
    });

    test('labels strong ROI signal', () {
      const input = GrowthPerformanceInput(
        venueViews: 100,
        favouriteTaps: 20,
        dealViews: 10,
        eventViews: 10,
      );
      expect(performanceService.roiSignalLabel(input), 'Strong');
    });

    test('returns new signal with zero views', () {
      expect(
        performanceService.roiSignalLabel(const GrowthPerformanceInput()),
        'New',
      );
    });

    test('builds engagement insight for low conversion', () {
      const input = GrowthPerformanceInput(
        venueViews: 50,
        favouriteTaps: 1,
        conversionRatePercent: 2,
      );
      expect(
        performanceService.engagementInsightMessage(input),
        contains('favourites are low'),
      );
    });
  });

  group('GrowthUpgradeService', () {
    test('recommends professional upgrade for starter without media', () {
      final recommendation = upgradeService.recommendVenueUpgrade(
        currentPlanId: 'starter',
        hasMediaCentreAccess: false,
        hasAdvancedAnalyticsAccess: false,
        hasCampaignToolsAccess: false,
      );
      expect(recommendation?.recommendedPlanId, 'professional');
      expect(
        recommendation?.benefits,
        GrowthUpgradeService.mediaUpgradeBenefits,
      );
    });

    test('returns null when premium campaign tools already available', () {
      final recommendation = upgradeService.recommendVenueUpgrade(
        currentPlanId: 'premium',
        hasMediaCentreAccess: true,
        hasAdvancedAnalyticsAccess: true,
        hasCampaignToolsAccess: true,
      );
      expect(recommendation, isNull);
    });
  });

  group('GrowthCampaignReadinessService', () {
    test('requires gallery and promotion content', () {
      final readiness = campaignService.assess(
        hasUpcomingDealOrEvent: false,
        hasGalleryPhotos: false,
        hasActiveBoost: false,
        hasDraftCampaign: false,
        notificationsEnabled: true,
      );
      expect(readiness.ready, isFalse);
      expect(readiness.missingRequirements, contains('gallery-photos'));
      expect(readiness.missingRequirements, contains('promotion-content'));
    });

    test('marks ready when requirements satisfied', () {
      final readiness = campaignService.assess(
        hasUpcomingDealOrEvent: true,
        hasGalleryPhotos: true,
        hasActiveBoost: true,
        hasDraftCampaign: false,
        notificationsEnabled: true,
      );
      expect(readiness.ready, isTrue);
      expect(campaignService.readinessLabel(readiness), 'Ready to launch');
    });
  });

  group('GrowthComparisonService', () {
    test('compares venue plans from current tier upward', () {
      final plans = comparisonService.compareVenuePlans(
        currentPlanId: 'professional',
      );
      expect(plans.map((plan) => plan.id).toList(), [
        'professional',
        'premium',
        'corporate',
      ]);
    });

    test('calculates discounted launch price', () {
      expect(comparisonService.discountedPriceGbp(99), 50);
    });

    test('detects mixed web and mobile product models', () {
      final issues = comparisonService.detectPlanConflicts(
        venuePlanId: 'starter',
        consumerPlanId: 'venue_pro',
      );
      expect(issues, isNotEmpty);
      expect(issues.first.code, 'mixed-product-models');
    });
  });

  group('GrowthScoringService', () {
    test('scores strong performance higher', () {
      final strong = scoringService.score(
        performance: const GrowthPerformance(
          estimatedVisits: 20,
          estimatedRevenueGbp: 360,
          roiSignalLabel: 'Strong',
          insightMessage: '',
          revenueInsightMessage: '',
        ),
        profileCompletionRemaining: 0,
        hasActiveBoost: true,
        hasUpcomingDealOrEvent: true,
      );
      final weak = scoringService.score(
        performance: const GrowthPerformance(
          estimatedVisits: 0,
          estimatedRevenueGbp: 0,
          roiSignalLabel: 'New',
          insightMessage: '',
          revenueInsightMessage: '',
        ),
        profileCompletionRemaining: 4,
        hasActiveBoost: false,
        hasUpcomingDealOrEvent: false,
      );
      expect(strong.value, greaterThan(weak.value));
    });
  });

  group('GrowthRecommendationService', () {
    test('orders profile and deal opportunities first', () {
      final opportunities = recommendationService.composeOpportunities(
        const GrowthAdviceInput(
          hasGalleryPhotos: false,
          dealCount: 0,
          hasUpcomingEvent: false,
          profileCompletionRemaining: 2,
          hasActiveBoost: false,
          performance: GrowthPerformance(
            estimatedVisits: 0,
            estimatedRevenueGbp: 0,
            roiSignalLabel: 'Build',
            insightMessage: '',
            revenueInsightMessage: '',
          ),
        ),
      );
      expect(opportunities.first.id, 'profile-photos');
      expect(opportunities.map((item) => item.id), contains('create-deal'));
    });
  });

  group('GrowthSummaryService', () {
    test('builds commercial summary with upgrade and boost label', () {
      final summary = summaryService.summarize(
        GrowthSummaryInput(
          currentPlanId: 'starter',
          hasMediaCentreAccess: false,
          hasAdvancedAnalyticsAccess: false,
          hasCampaignToolsAccess: false,
          hasGalleryPhotos: false,
          hasUpcomingDealOrEvent: true,
          hasActiveBoost: true,
          activeBoostPlanName: '7 Day Boost',
          activeBoostEndsAt: DateTime.utc(2026, 7, 12),
          performance: performanceService.interpret(
            const GrowthPerformanceInput(
              venueViews: 120,
              favouriteTaps: 12,
              dealViews: 8,
              eventViews: 4,
              conversionRatePercent: 10,
            ),
          ),
          dealCount: 0,
          profileCompletionRemaining: 1,
        ),
      );

      expect(summary.upgradeRecommendation?.recommendedPlanId, 'professional');
      expect(summary.activeBoostLabel, contains('7 Day Boost'));
      expect(summary.recommendations, isNotEmpty);
    });
  });

  group('GrowthProductCatalog', () {
    test('contains canonical boost and venue plans', () {
      expect(GrowthProductCatalog.boostPlans.length, 3);
      expect(GrowthProductCatalog.webVenuePlans.length, 4);
      expect(GrowthProductCatalog.boostPlanById('boost_30d')?.pricePence, 5999);
    });
  });

  group('GrowthOrdering', () {
    test('preserves deterministic recommendation ordering', () {
      final ordered = GrowthOrdering.orderRecommendations([
        const GrowthRecommendation(
          id: 'b',
          title: 'B',
          message: 'B',
          action: GrowthAction.addDeal,
          priority: GrowthPriority.medium,
        ),
        const GrowthRecommendation(
          id: 'a',
          title: 'A',
          message: 'A',
          action: GrowthAction.addEvent,
          priority: GrowthPriority.high,
        ),
      ]);
      expect(ordered.first.id, 'a');
    });
  });
}
