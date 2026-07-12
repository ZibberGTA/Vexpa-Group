import '../domain/boost_plan.dart';
import '../domain/growth_boost_state.dart';
import '../domain/growth_result.dart';
import '../domain/promotion_status.dart';
import '../shared/growth_product_catalog.dart';

/// Boost lifecycle rules — commerce semantics only (not discovery ranking).
final class GrowthBoostService {
  const GrowthBoostService();

  bool isBoostActive({required bool active, DateTime? endsAt, DateTime? now}) {
    if (!active) return false;
    if (endsAt == null) return true;
    return endsAt.isAfter(now ?? DateTime.now());
  }

  PromotionStatus resolveStatus(GrowthActiveBoost boost, {DateTime? now}) {
    if (!boost.active) {
      return PromotionStatus.cancelled;
    }
    if (!isBoostActive(active: boost.active, endsAt: boost.endsAt, now: now)) {
      return PromotionStatus.expired;
    }
    return PromotionStatus.active;
  }

  DateTime computeEndsAt({
    required BoostPlan plan,
    required DateTime startedAt,
  }) {
    return startedAt.add(Duration(days: plan.days));
  }

  GrowthResult<GrowthBoostActivationPayload> prepareActivation({
    required String venueId,
    required String venueName,
    required String ownerId,
    required String planId,
    required DateTime startedAt,
    String paymentStatus = 'manual',
    String? checkoutSessionPath,
  }) {
    if (venueId.trim().isEmpty) {
      return const GrowthFailure(
        'venue-id-required',
        'Select a venue to boost.',
      );
    }
    if (ownerId.trim().isEmpty) {
      return const GrowthFailure(
        'owner-id-required',
        'Sign in to boost a venue.',
      );
    }

    final plan = GrowthProductCatalog.boostPlanById(planId);
    if (plan == null) {
      return const GrowthFailure(
        'invalid-boost-plan',
        'Select a valid boost plan.',
      );
    }

    final normalizedPaymentStatus = paymentStatus.trim().toLowerCase();
    if (normalizedPaymentStatus.isEmpty) {
      return const GrowthFailure(
        'invalid-payment-status',
        'Payment status is required.',
      );
    }

    return GrowthSuccess(
      GrowthBoostActivationPayload(
        venueId: venueId.trim(),
        venueName: venueName.trim(),
        ownerId: ownerId.trim(),
        plan: plan,
        startedAt: startedAt,
        endsAt: computeEndsAt(plan: plan, startedAt: startedAt),
        paymentStatus: normalizedPaymentStatus,
        checkoutSessionPath: checkoutSessionPath?.trim(),
      ),
    );
  }

  GrowthResult<void> validatePaidCheckout({
    required String? paymentStatus,
    required String? sessionStatus,
  }) {
    final payment = paymentStatus?.trim().toLowerCase();
    final status = sessionStatus?.trim().toLowerCase();
    final paid = payment == 'paid' || status == 'complete' || status == 'paid';
    if (!paid) {
      return const GrowthFailure(
        'checkout-not-paid',
        'Stripe checkout has not been paid yet.',
      );
    }
    return const GrowthSuccess(true);
  }

  GrowthResult<void> detectActivationConflict({
    required GrowthActiveBoost? existingBoost,
    DateTime? now,
  }) {
    if (existingBoost == null) {
      return const GrowthSuccess(true);
    }
    if (isBoostActive(
      active: existingBoost.active,
      endsAt: existingBoost.endsAt,
      now: now,
    )) {
      return const GrowthFailure(
        'boost-already-active',
        'This venue already has an active boost.',
      );
    }
    return const GrowthSuccess(true);
  }
}
