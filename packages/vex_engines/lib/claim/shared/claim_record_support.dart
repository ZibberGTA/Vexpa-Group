import '../domain/claim_status.dart';

/// Safe parsing and ordering helpers for claim records from adapters.
final class ClaimRecordSupport {
  ClaimRecordSupport._();

  static ClaimStatus parseStatusSafely(Object? value) =>
      ClaimStatusCodec.fromFirestore(value);

  static bool isMalformedClaimRecord(Map<String, dynamic>? data) {
    if (data == null) {
      return true;
    }

    final venueId = (data['venueId'] ?? '').toString().trim();
    final claimantUid = (data['claimantUid'] ?? '').toString().trim();
    if (venueId.isEmpty && claimantUid.isEmpty) {
      return true;
    }

    final statusRaw = data['status'];
    if (statusRaw != null &&
        statusRaw.toString().trim().isEmpty &&
        data.containsKey('status')) {
      return true;
    }

    return false;
  }

  static int compareSubmittedAtDesc({
    required DateTime? leftSubmittedAt,
    required DateTime? rightSubmittedAt,
    required String leftId,
    required String rightId,
  }) {
    final leftTime = leftSubmittedAt?.millisecondsSinceEpoch ?? 0;
    final rightTime = rightSubmittedAt?.millisecondsSinceEpoch ?? 0;
    if (leftTime != rightTime) {
      return rightTime.compareTo(leftTime);
    }
    return leftId.compareTo(rightId);
  }

  static String venueDisplayLabel({
    required String venueName,
    required String venueId,
  }) {
    final trimmedName = venueName.trim();
    if (trimmedName.isNotEmpty) {
      return trimmedName;
    }
    return venueId.trim();
  }

  static String claimantDisplayLabel({
    required String claimantEmail,
    required String claimantUid,
  }) {
    final trimmedEmail = claimantEmail.trim();
    if (trimmedEmail.isNotEmpty) {
      return trimmedEmail;
    }
    return claimantUid.trim();
  }
}
