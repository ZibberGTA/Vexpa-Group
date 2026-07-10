import '../models/media_subscription_limits.dart';

/// Temporary subscription facade for venue-owner feature gates.
///
/// TODO(subscription): Replace this wrapper with the real subscription service
/// when plan entitlement checks move out of local venue metadata.
class SubscriptionService {
  const SubscriptionService._();

  static bool canUseGallery({required String venueId, String planId = ''}) {
    if (venueId.trim().isEmpty) return false;
    return MediaSubscriptionLimits.hasMediaCentreAccess(planId);
  }
}
