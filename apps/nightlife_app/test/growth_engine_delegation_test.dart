import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_app/features/monetisation/services/growth_commercial_support.dart';
import 'package:vex_engines/growth/growth_engine.dart';

void main() {
  group('Mobile Growth Engine delegation', () {
    test('performance helpers delegate to GrowthPerformanceInterpretationService', () {
      const input = GrowthPerformanceInput(
        venueViews: 100,
        favouriteTaps: 10,
        dealViews: 5,
        eventViews: 5,
      );
      expect(
        MobileGrowthCommercialSupport.roiSignalLabel(input),
        const GrowthPerformanceInterpretationService().roiSignalLabel(input),
      );
      expect(MobileGrowthCommercialSupport.estimatedVisits(input), 15);
    });

    test('ROI and conversion summaries delegate to marketing service', () {
      const performance = GrowthPerformance(
        estimatedVisits: 15,
        estimatedRevenueGbp: 270,
        roiSignalLabel: 'Good',
        insightMessage: 'Insight',
        revenueInsightMessage: 'Revenue',
      );
      final roi = MobileGrowthCommercialSupport.roiSummary(performance);
      expect(roi.estimatedRevenueGbp, 270);

      final conversion = MobileGrowthCommercialSupport.conversionSummary(
        conversionRatePercent: 8,
        venueViews: 100,
      );
      expect(conversion.label, 'Healthy conversion');
    });

    test('venue scores delegate to GrowthScoringService', () {
      const performance = GrowthPerformance(
        estimatedVisits: 20,
        estimatedRevenueGbp: 360,
        roiSignalLabel: 'Strong',
        insightMessage: '',
        revenueInsightMessage: '',
      );
      final scores = MobileGrowthCommercialSupport.venueScores(
        performance: performance,
        profileCompletionRemaining: 0,
        hasActiveBoost: true,
        hasUpcomingDealOrEvent: true,
        hasCampaignToolsAccess: true,
        dealCount: 2,
      );
      expect(scores.commercialScore, greaterThan(0));
    });
  });
}
