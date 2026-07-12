import '../domain/boost_plan.dart';

/// Canonical web venue subscription product.
final class GrowthVenuePlanProduct {
  const GrowthVenuePlanProduct({
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
}

/// Canonical product catalog for growth comparisons and recommendations.
abstract final class GrowthProductCatalog {
  GrowthProductCatalog._();

  static const launchDiscountLabel = 'First 12 months — 50% off every plan';

  static const artistConsumerPlanId = 'artist_monthly_499';
  static const venueProConsumerPlanId = 'venue_pro';

  static const webVenuePlans = <GrowthVenuePlanProduct>[
    GrowthVenuePlanProduct(
      id: 'starter',
      name: 'Starter',
      audience: 'Small venues getting started on Vexda',
      monthlyPriceGbp: 49,
      features: [
        'Venue profile & discovery listing',
        'Drinks & deals management',
        'Basic analytics',
        'Customer search visibility',
      ],
    ),
    GrowthVenuePlanProduct(
      id: 'professional',
      name: 'Professional',
      audience: 'Active venues that need full discovery tools',
      monthlyPriceGbp: 99,
      highlighted: true,
      features: [
        'Everything in Starter',
        'Events & gallery management',
        'Featured placement eligibility',
        'Team manager access',
        'Priority support',
      ],
    ),
    GrowthVenuePlanProduct(
      id: 'premium',
      name: 'Premium',
      audience: 'High-traffic venues maximising reach',
      monthlyPriceGbp: 179,
      features: [
        'Everything in Professional',
        'Premium discovery placement',
        'Campaign & promotion tools',
        'Advanced analytics',
        'Trail & event spotlighting',
      ],
    ),
    GrowthVenuePlanProduct(
      id: 'corporate',
      name: 'Corporate',
      audience: 'Multi-venue groups and operators',
      monthlyPriceGbp: 349,
      features: [
        'Everything in Premium',
        'Multi-venue dashboard',
        'Dedicated account manager',
        'Custom onboarding',
        'Enterprise reporting',
      ],
    ),
  ];

  static const boostPlans = <BoostPlan>[
    BoostPlan(
      id: 'boost_24h',
      name: '24 Hour Boost',
      description: 'Push one venue higher in Trending for a full day.',
      days: 1,
      boostScore: 35,
      priceLabel: '£4.99',
      pricePence: 499,
    ),
    BoostPlan(
      id: 'boost_7d',
      name: '7 Day Boost',
      description: 'Keep one venue promoted during the week.',
      days: 7,
      boostScore: 45,
      priceLabel: '£19.99',
      pricePence: 1999,
    ),
    BoostPlan(
      id: 'boost_30d',
      name: '30 Day Boost',
      description: 'Monthly visibility for your highest-priority venue.',
      days: 30,
      boostScore: 55,
      priceLabel: '£59.99',
      pricePence: 5999,
    ),
  ];

  static BoostPlan? boostPlanById(String id) {
    final trimmed = id.trim();
    for (final plan in boostPlans) {
      if (plan.id == trimmed) return plan;
    }
    return null;
  }

  static GrowthVenuePlanProduct? venuePlanById(String id) {
    final normalized = id.trim().toLowerCase();
    for (final plan in webVenuePlans) {
      if (plan.id == normalized) return plan;
    }
    return null;
  }

  static GrowthVenuePlanProduct? nextVenuePlan(String currentPlanId) {
    final index = webVenuePlans.indexWhere((plan) => plan.id == currentPlanId);
    if (index < 0 || index >= webVenuePlans.length - 1) return null;
    return webVenuePlans[index + 1];
  }
}
