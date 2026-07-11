import 'entitlement.dart';
import 'subscription_tier.dart';

/// Numeric subscription limits (media uploads, etc.).
final class EntitlementLimits {
  EntitlementLimits._();

  static const starterPlanId = 'starter';

  static int mediaLimitFor({
    required SubscriptionTier tier,
    required String mediaLibraryKey,
    Map<String, int> customLimits = const {},
  }) {
    if (tier == SubscriptionTier.corporate) {
      final custom = customLimits[mediaLibraryKey];
      if (custom != null && custom > 0) return custom;
      return 50;
    }

    return switch (tier) {
      SubscriptionTier.starter => 0,
      SubscriptionTier.professional => _professionalLimit(mediaLibraryKey),
      SubscriptionTier.premium => _premiumLimit(mediaLibraryKey),
      SubscriptionTier.free ||
      SubscriptionTier.unknown =>
        _professionalLimit(mediaLibraryKey),
      SubscriptionTier.corporate => 50,
    };
  }

  static int mediaLimitForPlanId({
    required String? planId,
    required String mediaLibraryKey,
    Map<String, int> customLimits = const {},
  }) {
    return mediaLimitFor(
      tier: SubscriptionTierNormalizer.parseVenueTier(planId),
      mediaLibraryKey: mediaLibraryKey,
      customLimits: customLimits,
    );
  }

  static int _professionalLimit(String mediaLibraryKey) {
    return switch (mediaLibraryKey) {
      MediaLibraryLimitKey.brandAssets => 0,
      MediaLibraryLimitKey.venueGallery => 20,
      MediaLibraryLimitKey.dealImages => 15,
      MediaLibraryLimitKey.eventImages => 15,
      _ => 0,
    };
  }

  static int _premiumLimit(String mediaLibraryKey) {
    return switch (mediaLibraryKey) {
      MediaLibraryLimitKey.brandAssets => 0,
      MediaLibraryLimitKey.venueGallery => 30,
      MediaLibraryLimitKey.dealImages => 25,
      MediaLibraryLimitKey.eventImages => 25,
      _ => 0,
    };
  }
}
