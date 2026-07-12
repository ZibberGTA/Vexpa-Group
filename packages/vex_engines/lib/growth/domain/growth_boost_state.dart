import 'boost_plan.dart';
import 'promotion_status.dart';

/// Adapter-supplied active boost state.
final class GrowthActiveBoost {
  const GrowthActiveBoost({
    required this.active,
    required this.planId,
    this.planName = '',
    this.boostScore = 0,
    this.priceLabel = '',
    this.pricePence = 0,
    this.paymentStatus = '',
    this.startedAt,
    this.endsAt,
    this.status = PromotionStatus.draft,
  });

  final bool active;
  final String planId;
  final String planName;
  final int boostScore;
  final String priceLabel;
  final int pricePence;
  final String paymentStatus;
  final DateTime? startedAt;
  final DateTime? endsAt;
  final PromotionStatus status;
}

/// Prepared boost activation payload for Firebase adapters.
final class GrowthBoostActivationPayload {
  const GrowthBoostActivationPayload({
    required this.venueId,
    required this.venueName,
    required this.ownerId,
    required this.plan,
    required this.startedAt,
    required this.endsAt,
    required this.paymentStatus,
    this.checkoutSessionPath,
  });

  final String venueId;
  final String venueName;
  final String ownerId;
  final BoostPlan plan;
  final DateTime startedAt;
  final DateTime endsAt;
  final String paymentStatus;
  final String? checkoutSessionPath;

  Map<String, Object?> toAdapterFields() {
    return {
      'venueId': venueId,
      'venueName': venueName,
      'ownerId': ownerId,
      'planId': plan.id,
      'planName': plan.name,
      'priceLabel': plan.priceLabel,
      'pricePence': plan.pricePence,
      'boostScore': plan.boostScore,
      'active': true,
      'paymentStatus': paymentStatus,
      if (checkoutSessionPath != null)
        'checkoutSessionPath': checkoutSessionPath,
      'startedAt': startedAt.toUtc().toIso8601String(),
      'endsAt': endsAt.toUtc().toIso8601String(),
    };
  }
}
