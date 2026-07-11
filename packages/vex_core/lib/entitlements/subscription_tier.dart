/// Canonical venue subscription tiers for dashboard entitlements.
enum SubscriptionTier {
  starter,
  professional,
  premium,
  corporate,
  free,
  unknown,
}

/// Mobile consumer subscription plans (user-level billing products).
enum ConsumerSubscriptionPlan {
  artistMonthly499,
  venuePro,
  unknown,
}

/// Normalises raw plan identifiers from Firestore, Stripe metadata, or UI.
final class SubscriptionTierNormalizer {
  SubscriptionTierNormalizer._();

  static String normalizeRaw(String? raw) {
    if (raw == null) return '';
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed == '—') return '';
    return trimmed.toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');
  }

  /// Parses venue-scoped plan ids (`subscriptionPlanId`, etc.).
  static SubscriptionTier parseVenueTier(String? raw) {
    final normalized = normalizeRaw(raw);
    return switch (normalized) {
      'starter' => SubscriptionTier.starter,
      'professional' || 'pro' || 'venue_pro' || 'venuepro' =>
        SubscriptionTier.professional,
      'premium' => SubscriptionTier.premium,
      'corporate' => SubscriptionTier.corporate,
      'free' => SubscriptionTier.free,
      '' => SubscriptionTier.unknown,
      _ => SubscriptionTier.unknown,
    };
  }

  /// Parses user-level consumer billing plan ids.
  static ConsumerSubscriptionPlan parseConsumerPlan(String? raw) {
    final normalized = normalizeRaw(raw);
    return switch (normalized) {
      'artist_monthly_499' => ConsumerSubscriptionPlan.artistMonthly499,
      'venue_pro' || 'venuepro' => ConsumerSubscriptionPlan.venuePro,
      _ => ConsumerSubscriptionPlan.unknown,
    };
  }
}

/// Display ordering for venue tiers (lower index = lower tier).
int subscriptionTierOrder(SubscriptionTier tier) {
  return switch (tier) {
    SubscriptionTier.starter => 0,
    SubscriptionTier.free => 1,
    SubscriptionTier.unknown => 2,
    SubscriptionTier.professional => 3,
    SubscriptionTier.premium => 4,
    SubscriptionTier.corporate => 5,
  };
}

/// Admin CRM pill label for a venue subscription tier id.
String adminVenueSubscriptionPlanLabel(String? raw) {
  if (raw == null) return 'Unknown';
  final trimmed = raw.trim();
  if (trimmed.isEmpty || trimmed == '—') return 'Unknown';

  return switch (SubscriptionTierNormalizer.normalizeRaw(trimmed)) {
    'starter' => 'Starter',
    'professional' || 'pro' || 'venue_pro' || 'venuepro' => 'Professional',
    'premium' => 'Premium',
    'corporate' => 'Corporate',
    'free' => 'Free',
    _ => 'Unknown',
  };
}

/// Admin table formatting for raw subscription tier ids.
String formatAdminVenueSubscriptionTier(String? raw) {
  if (raw == null) return '—';
  final trimmed = raw.trim();
  if (trimmed.isEmpty || trimmed == '—') return '—';

  final normalized = SubscriptionTierNormalizer.normalizeRaw(trimmed);
  return switch (normalized) {
    'venue_pro' || 'pro' || 'venuepro' => 'Venue Pro',
    'professional' => 'Professional',
    'starter' => 'Starter',
    'premium' => 'Premium',
    'corporate' => 'Corporate',
    _ =>
      trimmed
          .split(RegExp(r'[_\s]+'))
          .where((part) => part.isNotEmpty)
          .map(
            (part) =>
                '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
          )
          .join(' '),
  };
}

/// Whether the normalised admin display tier counts as premium/pro.
bool isPremiumVenueSubscriptionDisplayTier(String? displayTier) {
  final value = displayTier?.toLowerCase() ?? '';
  return value.contains('pro') || value == 'premium' || value == 'corporate';
}

/// Compatibility alias used by admin CRM screens.
bool isPremiumVenueSubscriptionTier(String? displayTier) =>
    isPremiumVenueSubscriptionDisplayTier(displayTier);
