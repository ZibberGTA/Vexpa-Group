import 'package:flutter_test/flutter_test.dart';
import 'package:vex_core/entitlements/entitlements.dart';

import 'package:nightlife_app/features/monetisation/services/subscription_entitlements.dart';

void main() {
  group('Mobile subscription entitlement delegation', () {
    test('artist chat requires active artist plan entitlement', () {
      expect(
        SubscriptionEntitlements.artistChatAllowed(subscriptionActive: true),
        isTrue,
      );
      expect(
        SubscriptionEntitlements.artistChatAllowed(subscriptionActive: false),
        isFalse,
      );
    });

    test('owner analytics breakdown requires active venue pro entitlement', () {
      expect(
        SubscriptionEntitlements.ownerAnalyticsBreakdownAllowed(
          subscriptionActive: true,
        ),
        isTrue,
      );
      expect(
        SubscriptionEntitlements.ownerAnalyticsBreakdownAllowed(
          subscriptionActive: false,
        ),
        isFalse,
      );
    });

    test('unknown consumer plans fail closed through VexCore', () {
      const service = EntitlementService();
      expect(
        service.hasConsumerFeature(
          planId: 'made_up_plan',
          feature: EntitlementFeature.venueBookingFeature,
        ),
        isFalse,
      );
    });
  });
}
