import 'package:vex_core/entitlements/entitlements.dart';

/// Temporary subscription facade for venue-owner feature gates.
///
/// Plan entitlement checks delegate to VexCore. Billing status remains in
/// venue metadata and payment adapters.
class SubscriptionService {
  const SubscriptionService._();

  static const _entitlements = EntitlementService();

  static bool canUseGallery({required String venueId, String planId = ''}) {
    if (venueId.trim().isEmpty) return false;
    return _entitlements.hasMediaCentreAccess(planId);
  }
}
