import '../domain/promotion_status.dart';

/// Human-readable commercial labels.
abstract final class GrowthCommercialLabels {
  GrowthCommercialLabels._();

  static String promotionStatusLabel(PromotionStatus status) =>
      switch (status) {
        PromotionStatus.draft => 'Draft',
        PromotionStatus.scheduled => 'Scheduled',
        PromotionStatus.active => 'Active',
        PromotionStatus.expired => 'Expired',
        PromotionStatus.cancelled => 'Cancelled',
      };

  static String roiSignalLabel(String signal) => switch (signal.trim()) {
    'Strong' => 'Strong ROI signal',
    'Good' => 'Good ROI signal',
    'Build' => 'Build ROI signal',
    _ => 'New ROI signal',
  };

  static String activeBoostSummary({
    required String planName,
    required DateTime? endsAt,
  }) {
    if (planName.trim().isEmpty) {
      return 'Boost active';
    }
    if (endsAt == null) {
      return '$planName boost active';
    }
    return '$planName boost active until ${_shortDate(endsAt)}';
  }

  static String _shortDate(DateTime value) {
    final local = value.toLocal();
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekday = weekdays[(local.weekday - 1).clamp(0, 6)];
    return '$weekday ${local.day}/${local.month}';
  }
}
