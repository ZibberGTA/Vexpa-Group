import 'growth_thresholds.dart';

/// Price and currency formatting helpers.
abstract final class GrowthFormatting {
  GrowthFormatting._();

  static int discountedLaunchPriceGbp(int monthlyPriceGbp) {
    return (monthlyPriceGbp * GrowthThresholds.launchDiscountFactor).round();
  }

  static String formatGbp(int amount) => '£$amount';

  static String formatGbpFromPence(int pence) {
    final pounds = pence / 100;
    if (pence % 100 == 0) {
      return '£${pounds.toInt()}';
    }
    return '£${pounds.toStringAsFixed(2)}';
  }

  static String formatPercent(double value) => '${value.toStringAsFixed(1)}%';
}
