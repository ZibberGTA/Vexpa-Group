import '../domain/analytics_venue_metrics.dart';

/// Engagement and popularity calculations from venue metrics.
final class AnalyticsEngagementCalculator {
  const AnalyticsEngagementCalculator();

  AnalyticsEngagementMetrics compute(AnalyticsVenueMetrics metrics) {
    final conversionRate = metrics.profileViews == 0
        ? 0.0
        : (metrics.saves / metrics.profileViews) * 100;

    final contentViews =
        metrics.drinkViews + metrics.dealViews + metrics.eventViews;

    return AnalyticsEngagementMetrics(
      favouriteConversionRate: conversionRate,
      totalContentViews: contentViews,
      popularityScore: metrics.profileViews + metrics.saves + contentViews,
    );
  }

  String formatConversionRate(double rate) => '${rate.toStringAsFixed(1)}%';
}
