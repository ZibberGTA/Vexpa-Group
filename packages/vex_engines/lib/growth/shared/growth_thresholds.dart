/// Shared growth thresholds for recommendations and scoring.
abstract final class GrowthThresholds {
  GrowthThresholds._();

  static const strongIntentRate = 0.35;
  static const goodIntentRate = 0.15;
  static const lowConversionRatePercent = 5.0;
  static const visitViewMultiplier = 0.08;
  static const visitIntentMultiplier = 0.35;
  static const revenuePerEstimatedVisitGbp = 18;
  static const launchDiscountFactor = 0.5;
}
