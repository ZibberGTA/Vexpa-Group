import 'media_library_tab.dart';

/// Subscription-based upload limits for each media library.
class MediaSubscriptionLimits {
  MediaSubscriptionLimits._();

  static const starterPlanId = 'starter';

  static bool hasMediaCentreAccess(String planId) {
    return planId.trim().toLowerCase() != starterPlanId;
  }

  static int limitFor({
    required String planId,
    required MediaLibraryTab tab,
    Map<String, int> customLimits = const {},
  }) {
    final normalized = planId.trim().toLowerCase();

    if (normalized == 'corporate') {
      final custom = customLimits[tab.customLimitKey];
      if (custom != null && custom > 0) return custom;
      return 50;
    }

    return switch (normalized) {
      'starter' => 0,
      'professional' => switch (tab) {
          MediaLibraryTab.brandAssets => 0,
          MediaLibraryTab.venueGallery => 20,
          MediaLibraryTab.dealImages => 15,
          MediaLibraryTab.eventImages => 15,
        },
      'premium' => switch (tab) {
          MediaLibraryTab.brandAssets => 0,
          MediaLibraryTab.venueGallery => 30,
          MediaLibraryTab.dealImages => 25,
          MediaLibraryTab.eventImages => 25,
        },
      _ => switch (tab) {
          MediaLibraryTab.brandAssets => 0,
          MediaLibraryTab.venueGallery => 20,
          MediaLibraryTab.dealImages => 15,
          MediaLibraryTab.eventImages => 15,
        },
    };
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
