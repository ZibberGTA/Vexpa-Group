/// Lifecycle status for a venue ownership claim.
enum ClaimStatus {
  draft,
  pendingReview,
  needsMoreInfo,
  autoApproved,
  approved,
  rejected,
  completed,
  error,
}

/// Firestore and UI helpers for [ClaimStatus].
extension ClaimStatusCodec on ClaimStatus {
  String get firestoreValue => switch (this) {
        ClaimStatus.draft => 'draft',
        ClaimStatus.pendingReview => 'pending_review',
        ClaimStatus.needsMoreInfo => 'needs_more_info',
        ClaimStatus.autoApproved => 'auto_approved',
        ClaimStatus.approved => 'approved',
        ClaimStatus.rejected => 'rejected',
        ClaimStatus.completed => 'completed',
        ClaimStatus.error => 'error',
      };

  String get label => switch (this) {
        ClaimStatus.draft => 'Draft',
        ClaimStatus.pendingReview => 'Pending Review',
        ClaimStatus.needsMoreInfo => 'Needs More Info',
        ClaimStatus.autoApproved => 'Auto Approved',
        ClaimStatus.approved => 'Approved',
        ClaimStatus.rejected => 'Rejected',
        ClaimStatus.completed => 'Completed',
        ClaimStatus.error => 'Error',
      };

  bool get isPending => this == ClaimStatus.pendingReview;

  bool get isApproved =>
      this == ClaimStatus.approved ||
      this == ClaimStatus.autoApproved ||
      this == ClaimStatus.completed;

  static ClaimStatus fromFirestore(Object? value) {
    final raw = value?.toString().trim().toLowerCase();
    return switch (raw) {
      'draft' => ClaimStatus.draft,
      'needs_more_info' || 'more_info_requested' => ClaimStatus.needsMoreInfo,
      'auto_approved' => ClaimStatus.autoApproved,
      'approved' => ClaimStatus.approved,
      'rejected' => ClaimStatus.rejected,
      'completed' => ClaimStatus.completed,
      'error' => ClaimStatus.error,
      _ => ClaimStatus.pendingReview,
    };
  }
}

/// Allowed claim status transitions enforced by review and submission rules.
final class ClaimStatusTransitions {
  ClaimStatusTransitions._();

  static const openStatuses = {
    ClaimStatus.draft,
    ClaimStatus.pendingReview,
    ClaimStatus.needsMoreInfo,
  };

  static bool hasOpenClaim(Iterable<ClaimStatus> existingStatuses) =>
      existingStatuses.any(openStatuses.contains);

  static bool canSubmit({
    required Iterable<ClaimStatus> existingStatusesForVenue,
  }) =>
      !hasOpenClaim(existingStatusesForVenue);

  static bool canApprove(ClaimStatus status) =>
      status == ClaimStatus.pendingReview ||
      status == ClaimStatus.needsMoreInfo ||
      status == ClaimStatus.autoApproved;

  static bool canReject(ClaimStatus status) =>
      status == ClaimStatus.pendingReview ||
      status == ClaimStatus.needsMoreInfo ||
      status == ClaimStatus.autoApproved;

  static bool canRequestMoreInfo(ClaimStatus status) =>
      status == ClaimStatus.pendingReview ||
      status == ClaimStatus.autoApproved;

  static bool canWithdraw(ClaimStatus status) =>
      status == ClaimStatus.draft ||
      status == ClaimStatus.pendingReview ||
      status == ClaimStatus.needsMoreInfo;

  static ClaimStatus statusAfterApprove(ClaimStatus current) =>
      ClaimStatus.approved;

  static ClaimStatus statusAfterReject(ClaimStatus current) =>
      ClaimStatus.rejected;

  static ClaimStatus statusAfterRequestMoreInfo(ClaimStatus current) =>
      ClaimStatus.needsMoreInfo;

  static ClaimStatus statusAfterWithdraw(ClaimStatus current) =>
      ClaimStatus.draft;
}
