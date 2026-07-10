import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/features/venue_management/models/media_library_page_config.dart';
import 'package:nightlife_web/features/venue_management/models/media_library_tab.dart';
import 'package:nightlife_web/features/venue_management/models/media_subscription_limits.dart';

void main() {
  group('MediaSubscriptionLimits', () {
    test('starter plan has no media centre access', () {
      expect(MediaSubscriptionLimits.hasMediaCentreAccess('starter'), isFalse);
      expect(
        MediaSubscriptionLimits.limitFor(
          planId: 'starter',
          tab: MediaLibraryTab.venueGallery,
        ),
        0,
      );
    });

    test('professional plan limits match spec', () {
      expect(
        MediaSubscriptionLimits.limitFor(
          planId: 'professional',
          tab: MediaLibraryTab.venueGallery,
        ),
        20,
      );
      expect(
        MediaSubscriptionLimits.limitFor(
          planId: 'professional',
          tab: MediaLibraryTab.dealImages,
        ),
        15,
      );
      expect(
        MediaSubscriptionLimits.limitFor(
          planId: 'professional',
          tab: MediaLibraryTab.eventImages,
        ),
        15,
      );
    });

    test('premium plan limits match spec', () {
      expect(
        MediaSubscriptionLimits.limitFor(
          planId: 'premium',
          tab: MediaLibraryTab.venueGallery,
        ),
        30,
      );
      expect(
        MediaSubscriptionLimits.limitFor(
          planId: 'premium',
          tab: MediaLibraryTab.dealImages,
        ),
        25,
      );
    });

    test('corporate plan uses custom limits when configured', () {
      expect(
        MediaSubscriptionLimits.limitFor(
          planId: 'corporate',
          tab: MediaLibraryTab.venueGallery,
          customLimits: const {'venueGallery': 40},
        ),
        40,
      );
    });

    test('validateUpload blocks when over limit', () {
      expect(
        MediaSubscriptionLimits.validateUpload(
          planId: 'professional',
          tab: MediaLibraryTab.dealImages,
          currentCount: 14,
          uploadCount: 2,
        ),
        contains('only upload 1'),
      );
    });
  });

  group('MediaLibraryPageConfig', () {
    test('venue gallery quick actions include cover and export', () {
      final config = MediaLibraryPageConfig.forTab(MediaLibraryTab.venueGallery);
      expect(config.primaryActionLabel, 'Upload Photos');
      expect(
        config.quickActions.map((action) => action.label),
        containsAll([
          'Upload Photos',
          'Reorder Gallery',
          'Set Cover Photo',
          'Export Gallery List',
          'Delete Selected',
        ]),
      );
    });

    test('deal images quick actions include replace', () {
      final config = MediaLibraryPageConfig.forTab(MediaLibraryTab.dealImages);
      expect(
        config.quickActions.map((action) => action.label),
        contains('Replace Image'),
      );
    });
  });
}
