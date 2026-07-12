import 'promotion_status.dart';

/// Time-bounded promotion window for boosts or campaigns.
final class PromotionWindow {
  const PromotionWindow({required this.status, this.startsAt, this.endsAt});

  final PromotionStatus status;
  final DateTime? startsAt;
  final DateTime? endsAt;

  bool isActiveAt(DateTime moment) {
    if (status != PromotionStatus.active) return false;
    if (startsAt != null && moment.isBefore(startsAt!)) return false;
    if (endsAt != null && !moment.isBefore(endsAt!)) return false;
    return true;
  }
}
