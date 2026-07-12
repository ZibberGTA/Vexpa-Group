import 'package:vex_engines/growth/growth_engine.dart';

/// Subscription tier definitions for business pricing pages.
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.audience,
    required this.monthlyPriceGbp,
    required this.features,
    this.highlighted = false,
  });

  final String id;
  final String name;
  final String audience;
  final int monthlyPriceGbp;
  final List<String> features;
  final bool highlighted;

  factory SubscriptionPlan.fromCatalog(GrowthVenuePlanProduct product) {
    return SubscriptionPlan(
      id: product.id,
      name: product.name,
      audience: product.audience,
      monthlyPriceGbp: product.monthlyPriceGbp,
      features: product.features,
      highlighted: product.highlighted,
    );
  }
}

class SubscriptionPlans {
  SubscriptionPlans._();

  static const String launchDiscountLabel =
      GrowthProductCatalog.launchDiscountLabel;

  static final List<SubscriptionPlan> tiers = GrowthProductCatalog.webVenuePlans
      .map(SubscriptionPlan.fromCatalog)
      .toList(growable: false);

  static int discountedPrice(int monthlyPriceGbp) =>
      GrowthFormatting.discountedLaunchPriceGbp(monthlyPriceGbp);
}
