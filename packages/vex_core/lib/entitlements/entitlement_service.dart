import 'entitlement.dart';
import 'entitlement_limits.dart';
import 'subscription_tier.dart';

/// In-memory subscription entitlement evaluation.
///
/// Callers pass plan ids already loaded by billing adapters — this type performs
/// no network I/O.
final class EntitlementService {
  const EntitlementService();

  SubscriptionTier normalizeVenueTier(String? planId) =>
      SubscriptionTierNormalizer.parseVenueTier(planId);

  ConsumerSubscriptionPlan normalizeConsumerPlan(String? planId) =>
      SubscriptionTierNormalizer.parseConsumerPlan(planId);

  bool hasVenueFeature({
    required String? planId,
    required EntitlementFeature feature,
  }) {
    return hasVenueFeatureForTier(
      tier: normalizeVenueTier(planId),
      feature: feature,
    );
  }

  bool hasVenueFeatureForTier({
    required SubscriptionTier tier,
    required EntitlementFeature feature,
  }) {
    return switch (feature) {
      EntitlementFeature.mediaCentreAccess => hasMediaCentreAccessForTier(tier),
      EntitlementFeature.analyticsVenueBreakdown ||
      EntitlementFeature.artistChatAccess ||
      EntitlementFeature.venueMessagingAccess ||
      EntitlementFeature.venueBookingFeature =>
        false,
    };
  }

  bool hasConsumerFeature({
    required String? planId,
    required EntitlementFeature feature,
  }) {
    return hasConsumerFeatureForPlan(
      plan: normalizeConsumerPlan(planId),
      feature: feature,
    );
  }

  bool hasConsumerFeatureForPlan({
    required ConsumerSubscriptionPlan plan,
    required EntitlementFeature feature,
  }) {
    return switch (feature) {
      EntitlementFeature.artistChatAccess =>
        plan == ConsumerSubscriptionPlan.artistMonthly499,
      EntitlementFeature.analyticsVenueBreakdown ||
      EntitlementFeature.venueMessagingAccess ||
      EntitlementFeature.venueBookingFeature =>
        plan == ConsumerSubscriptionPlan.venuePro,
      EntitlementFeature.mediaCentreAccess => false,
    };
  }

  bool hasMediaCentreAccess(String? planId) =>
      hasMediaCentreAccessForTier(normalizeVenueTier(planId));

  bool hasMediaCentreAccessForTier(SubscriptionTier tier) {
    return tier != SubscriptionTier.starter;
  }

  int mediaUploadLimit({
    required String? planId,
    required String mediaLibraryKey,
    Map<String, int> customLimits = const {},
  }) {
    return EntitlementLimits.mediaLimitForPlanId(
      planId: planId,
      mediaLibraryKey: mediaLibraryKey,
      customLimits: customLimits,
    );
  }

  bool isPremiumVenueTier(String? planId) {
    final label = adminVenueSubscriptionPlanLabel(planId);
    return isPremiumVenueSubscriptionTier(label);
  }

  int compareVenueTier(String? a, String? b) {
    final tierA = normalizeVenueTier(a);
    final tierB = normalizeVenueTier(b);
    return subscriptionTierOrder(tierA).compareTo(subscriptionTierOrder(tierB));
  }
}
