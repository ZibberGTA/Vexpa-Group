import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/features/venue_management/models/media_library_page_config.dart';
import 'package:nightlife_web/features/venue_management/models/media_library_tab.dart';
import 'package:nightlife_web/features/venue_management/models/media_subscription_limits.dart';

void main() {
  group('MediaSubscriptionLimits', () {
    test('deal images upload limit is five', () {
      expect(MediaSubscriptionLimits.dealImagesUploadLimit, 5);
    });

    test('event images upload limit is five', () {
      expect(MediaSubscriptionLimits.eventImagesUploadLimit, 5);
    });

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
        5,
      );
      expect(
        MediaSubscriptionLimits.limitFor(
          planId: 'professional',
          tab: MediaLibraryTab.eventImages,
        ),
        5,
      );
    });

    test('premium web caps use five for deal and event images', () {
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
        5,
      );
      expect(
        MediaSubscriptionLimits.limitFor(
          planId: 'premium',
          tab: MediaLibraryTab.eventImages,
        ),
        5,
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
      expect(
        MediaSubscriptionLimits.limitFor(
          planId: 'corporate',
          tab: MediaLibraryTab.dealImages,
          customLimits: const {'dealImages': 40},
        ),
        5,
      );
      expect(
        MediaSubscriptionLimits.limitFor(
          planId: 'corporate',
          tab: MediaLibraryTab.eventImages,
          customLimits: const {'eventImages': 40},
        ),
        5,
      );
    });

    group('validateUpload for deal images', () {
      test('allows upload below limit', () {
        expect(
          MediaSubscriptionLimits.validateUpload(
            planId: 'professional',
            tab: MediaLibraryTab.dealImages,
            currentCount: 4,
            uploadCount: 1,
          ),
          isNull,
        );
      });

      test('blocks upload at limit', () {
        expect(
          MediaSubscriptionLimits.validateUpload(
            planId: 'professional',
            tab: MediaLibraryTab.dealImages,
            currentCount: 5,
            uploadCount: 1,
          ),
          contains('reached your deal images limit (5)'),
        );
      });

      test('blocks partial upload when selection exceeds remaining slots', () {
        expect(
          MediaSubscriptionLimits.validateUpload(
            planId: 'professional',
            tab: MediaLibraryTab.dealImages,
            currentCount: 4,
            uploadCount: 2,
          ),
          contains('only upload 1'),
        );
      });

      test('blocks upload for venues already above limit', () {
        expect(
          MediaSubscriptionLimits.validateUpload(
            planId: 'professional',
            tab: MediaLibraryTab.dealImages,
            currentCount: 8,
            uploadCount: 1,
          ),
          contains('reached your deal images limit (5)'),
        );
      });
    });

    group('validateUpload for event images', () {
      test('allows upload below limit', () {
        expect(
          MediaSubscriptionLimits.validateUpload(
            planId: 'professional',
            tab: MediaLibraryTab.eventImages,
            currentCount: 4,
            uploadCount: 1,
          ),
          isNull,
        );
      });

      test('blocks upload at limit', () {
        expect(
          MediaSubscriptionLimits.validateUpload(
            planId: 'professional',
            tab: MediaLibraryTab.eventImages,
            currentCount: 5,
            uploadCount: 1,
          ),
          contains('reached your event images limit (5)'),
        );
      });

      test('blocks partial upload when selection exceeds remaining slots', () {
        expect(
          MediaSubscriptionLimits.validateUpload(
            planId: 'professional',
            tab: MediaLibraryTab.eventImages,
            currentCount: 4,
            uploadCount: 2,
          ),
          contains('only upload 1'),
        );
      });

      test('blocks upload for venues already above limit', () {
        expect(
          MediaSubscriptionLimits.validateUpload(
            planId: 'professional',
            tab: MediaLibraryTab.eventImages,
            currentCount: 8,
            uploadCount: 1,
          ),
          contains('reached your event images limit (5)'),
        );
      });
    });

    test('venue gallery limits remain unchanged', () {
      expect(
        MediaSubscriptionLimits.limitFor(
          planId: 'professional',
          tab: MediaLibraryTab.venueGallery,
        ),
        20,
      );
    });
  });

  group('MediaLibraryPageConfig', () {
    test('venue gallery quick actions include cover and export', () {
      final config = MediaLibraryPageConfig.forTab(
        MediaLibraryTab.venueGallery,
      );
      expect(config.primaryActionLabel, 'Upload Photos');
      expect(
        config.quickActions.map((action) => action.label),
        containsAll([
          'Upload Photos',
          'Reorder Gallery',
          'Set Featured Image',
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
