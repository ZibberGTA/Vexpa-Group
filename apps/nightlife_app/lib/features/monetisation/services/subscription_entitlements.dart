import 'package:vex_core/entitlements/entitlements.dart';

/// In-memory entitlement checks for mobile consumer subscriptions.
///
/// Billing adapters load subscription status from Firestore/Stripe; this facade
/// evaluates what each plan allows without additional network calls.
final class SubscriptionEntitlements {
  SubscriptionEntitlements._();

  static const _entitlements = EntitlementService();

  static const artistPlanId = 'artist_monthly_499';
  static const venueProPlanId = 'venue_pro';

  static bool artistChatAllowed({required bool subscriptionActive}) {
    if (!subscriptionActive) return false;
    return _entitlements.hasConsumerFeature(
      planId: artistPlanId,
      feature: EntitlementFeature.artistChatAccess,
    );
  }

  static bool ownerAnalyticsBreakdownAllowed({required bool subscriptionActive}) {
    if (!subscriptionActive) return false;
    return _entitlements.hasConsumerFeature(
      planId: venueProPlanId,
      feature: EntitlementFeature.analyticsVenueBreakdown,
    );
  }

  static bool venueMessagingAllowed({required bool subscriptionActive}) {
    if (!subscriptionActive) return false;
    return _entitlements.hasConsumerFeature(
      planId: venueProPlanId,
      feature: EntitlementFeature.venueMessagingAccess,
    );
  }

  static bool venueBookingAllowed({
    required bool subscriptionActive,
    required bool bookingFeatureEnabled,
    required String? venueSubscriptionPlan,
  }) {
    if (bookingFeatureEnabled) return true;
    if (!subscriptionActive) {
      return _entitlements.hasConsumerFeature(
        planId: venueSubscriptionPlan,
        feature: EntitlementFeature.venueBookingFeature,
      );
    }
    return _entitlements.hasConsumerFeature(
      planId: venueProPlanId,
      feature: EntitlementFeature.venueBookingFeature,
    );
  }
}
