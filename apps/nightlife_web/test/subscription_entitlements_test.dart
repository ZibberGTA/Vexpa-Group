import 'package:flutter_test/flutter_test.dart';
import 'package:vex_core/entitlements/entitlements.dart';

import 'package:nightlife_web/features/venue_management/models/media_library_tab.dart';
import 'package:nightlife_web/features/venue_management/models/media_subscription_limits.dart';
import 'package:nightlife_web/features/venue_management/services/subscription_service.dart';

void main() {
  group('Web subscription entitlement delegation', () {
    const engine = EntitlementService();

    test('MediaSubscriptionLimits delegates media access to VexCore', () {
      expect(
        MediaSubscriptionLimits.hasMediaCentreAccess('starter'),
        engine.hasMediaCentreAccess('starter'),
      );
      expect(
        MediaSubscriptionLimits.limitFor(
          planId: 'professional',
          tab: MediaLibraryTab.venueGallery,
        ),
        engine.mediaUploadLimit(
          planId: 'professional',
          mediaLibraryKey: MediaLibraryLimitKey.venueGallery,
        ),
      );
    });

    test('deal images use web cap instead of VexCore entitlement', () {
      expect(
        MediaSubscriptionLimits.limitFor(
          planId: 'professional',
          tab: MediaLibraryTab.dealImages,
        ),
        MediaSubscriptionLimits.dealImagesUploadLimit,
      );
      expect(
        MediaSubscriptionLimits.limitFor(
          planId: 'professional',
          tab: MediaLibraryTab.dealImages,
        ),
        isNot(
          engine.mediaUploadLimit(
            planId: 'professional',
            mediaLibraryKey: MediaLibraryLimitKey.dealImages,
          ),
        ),
      );
    });

    test('event images use web cap instead of VexCore entitlement', () {
      expect(
        MediaSubscriptionLimits.limitFor(
          planId: 'professional',
          tab: MediaLibraryTab.eventImages,
        ),
        MediaSubscriptionLimits.eventImagesUploadLimit,
      );
      expect(
        MediaSubscriptionLimits.limitFor(
          planId: 'professional',
          tab: MediaLibraryTab.eventImages,
        ),
        isNot(
          engine.mediaUploadLimit(
            planId: 'professional',
            mediaLibraryKey: MediaLibraryLimitKey.eventImages,
          ),
        ),
      );
    });

    test('SubscriptionService.canUseGallery delegates to VexCore', () {
      expect(
        SubscriptionService.canUseGallery(
          venueId: 'venue-1',
          planId: 'starter',
        ),
        isFalse,
      );
      expect(
        SubscriptionService.canUseGallery(
          venueId: 'venue-1',
          planId: 'professional',
        ),
        engine.hasMediaCentreAccess('professional'),
      );
    });

    test('unknown plans keep legacy permissive media defaults', () {
      expect(
        MediaSubscriptionLimits.limitFor(
          planId: 'legacy-plan',
          tab: MediaLibraryTab.venueGallery,
        ),
        20,
      );
    });
  });
}
