import 'package:test/test.dart';
import 'package:vex_core/entitlements/entitlements.dart';

void main() {
  const service = EntitlementService();

  group('SubscriptionTierNormalizer', () {
    test('normalises venue tier aliases', () {
      expect(
        service.normalizeVenueTier('venue_pro'),
        SubscriptionTier.professional,
      );
      expect(
        service.normalizeVenueTier(' PRO '),
        SubscriptionTier.professional,
      );
      expect(service.normalizeVenueTier('premium'), SubscriptionTier.premium);
      expect(service.normalizeVenueTier('corporate'), SubscriptionTier.corporate);
      expect(service.normalizeVenueTier('starter'), SubscriptionTier.starter);
    });

    test('missing tier resolves to unknown', () {
      expect(service.normalizeVenueTier(null), SubscriptionTier.unknown);
      expect(service.normalizeVenueTier(''), SubscriptionTier.unknown);
      expect(service.normalizeVenueTier('—'), SubscriptionTier.unknown);
    });

    test('unknown raw id resolves to unknown tier', () {
      expect(service.normalizeVenueTier('legacy_plan'), SubscriptionTier.unknown);
    });

    test('parses consumer plans separately', () {
      expect(
        service.normalizeConsumerPlan('artist_monthly_499'),
        ConsumerSubscriptionPlan.artistMonthly499,
      );
      expect(
        service.normalizeConsumerPlan('venue_pro'),
        ConsumerSubscriptionPlan.venuePro,
      );
      expect(
        service.normalizeConsumerPlan('unknown'),
        ConsumerSubscriptionPlan.unknown,
      );
    });
  });

  group('EntitlementService venue features', () {
    test('starter has no media centre access', () {
      expect(service.hasMediaCentreAccess('starter'), isFalse);
      expect(
        service.hasVenueFeature(
          planId: 'starter',
          feature: EntitlementFeature.mediaCentreAccess,
        ),
        isFalse,
      );
    });

    test('professional and unknown tiers allow media centre access', () {
      expect(service.hasMediaCentreAccess('professional'), isTrue);
      expect(service.hasMediaCentreAccess('legacy'), isTrue);
    });

    test('media limits match existing web spec', () {
      expect(
        service.mediaUploadLimit(
          planId: 'starter',
          mediaLibraryKey: MediaLibraryLimitKey.venueGallery,
        ),
        0,
      );
      expect(
        service.mediaUploadLimit(
          planId: 'professional',
          mediaLibraryKey: MediaLibraryLimitKey.venueGallery,
        ),
        20,
      );
      expect(
        service.mediaUploadLimit(
          planId: 'premium',
          mediaLibraryKey: MediaLibraryLimitKey.dealImages,
        ),
        25,
      );
      expect(
        service.mediaUploadLimit(
          planId: 'corporate',
          mediaLibraryKey: MediaLibraryLimitKey.venueGallery,
          customLimits: const {'venueGallery': 12},
        ),
        12,
      );
    });

    test('premium admin pill detection is deterministic', () {
      expect(service.isPremiumVenueTier('premium'), isTrue);
      expect(service.isPremiumVenueTier('professional'), isTrue);
      expect(service.isPremiumVenueTier('starter'), isFalse);
    });

    test('plan ordering is deterministic', () {
      expect(service.compareVenueTier('starter', 'premium'), lessThan(0));
      expect(service.compareVenueTier('premium', 'premium'), 0);
      expect(service.compareVenueTier('corporate', 'starter'), greaterThan(0));
    });

    test('venue tiers do not grant consumer-only features', () {
      expect(
        service.hasVenueFeature(
          planId: 'premium',
          feature: EntitlementFeature.artistChatAccess,
        ),
        isFalse,
      );
    });
  });

  group('EntitlementService consumer features', () {
    test('artist plan grants chat only', () {
      expect(
        service.hasConsumerFeature(
          planId: 'artist_monthly_499',
          feature: EntitlementFeature.artistChatAccess,
        ),
        isTrue,
      );
      expect(
        service.hasConsumerFeature(
          planId: 'artist_monthly_499',
          feature: EntitlementFeature.analyticsVenueBreakdown,
        ),
        isFalse,
      );
    });

    test('venue pro grants owner analytics and messaging features', () {
      expect(
        service.hasConsumerFeature(
          planId: 'venue_pro',
          feature: EntitlementFeature.analyticsVenueBreakdown,
        ),
        isTrue,
      );
      expect(
        service.hasConsumerFeature(
          planId: 'venue_pro',
          feature: EntitlementFeature.venueMessagingAccess,
        ),
        isTrue,
      );
      expect(
        service.hasConsumerFeature(
          planId: 'venue_pro',
          feature: EntitlementFeature.venueBookingFeature,
        ),
        isTrue,
      );
    });

    test('unknown consumer plan fails closed', () {
      expect(
        service.hasConsumerFeature(
          planId: 'unknown_plan',
          feature: EntitlementFeature.venueBookingFeature,
        ),
        isFalse,
      );
    });
  });

  group('Admin labels', () {
    test('adminVenueSubscriptionPlanLabel matches CRM pills', () {
      expect(adminVenueSubscriptionPlanLabel('starter'), 'Starter');
      expect(adminVenueSubscriptionPlanLabel('venue_pro'), 'Professional');
      expect(adminVenueSubscriptionPlanLabel('unknown'), 'Unknown');
    });
  });
}
