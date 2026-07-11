import 'package:vex_core/entitlements/entitlements.dart';

import 'media_library_tab.dart';

/// Subscription-based upload limits for each media library.
class MediaSubscriptionLimits {
  MediaSubscriptionLimits._();

  static const _entitlements = EntitlementService();

  static const starterPlanId = 'starter';

  static bool hasMediaCentreAccess(String planId) {
    return _entitlements.hasMediaCentreAccess(planId);
  }

  static int limitFor({
    required String planId,
    required MediaLibraryTab tab,
    Map<String, int> customLimits = const {},
  }) {
    return _entitlements.mediaUploadLimit(
      planId: planId,
      mediaLibraryKey: tab.customLimitKey,
      customLimits: customLimits,
    );
  }

  static String? validateUpload({
    required String planId,
    required MediaLibraryTab tab,
    required int currentCount,
    required int uploadCount,
    Map<String, int> customLimits = const {},
  }) {
    if (!tab.countsTowardSubscriptionLimit) {
      return 'Upload logo and banner from the Venue Profile page.';
    }

    if (!hasMediaCentreAccess(planId)) {
      return 'Upgrade to Professional to upload ${tab.emptyUnit}.';
    }

    final limit = limitFor(
      planId: planId,
      tab: tab,
      customLimits: customLimits,
    );
    if (currentCount + uploadCount > limit) {
      final remaining = (limit - currentCount).clamp(0, limit);
      if (remaining == 0) {
        return 'You have reached your ${tab.label.toLowerCase()} limit ($limit).';
      }
      return 'You can only upload $remaining more ${tab.emptyUnit} on your plan.';
    }
    return null;
  }
}
