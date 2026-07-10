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
}

class SubscriptionPlans {
  SubscriptionPlans._();

  static const String launchDiscountLabel =
      'First 12 months — 50% off every plan';

  static const List<SubscriptionPlan> tiers = [
    SubscriptionPlan(
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
    SubscriptionPlan(
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
    SubscriptionPlan(
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
    SubscriptionPlan(
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

  static int discountedPrice(int monthlyPriceGbp) => (monthlyPriceGbp / 2).round();
}
