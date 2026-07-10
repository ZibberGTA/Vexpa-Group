import '../domain/claim_result.dart';
import '../domain/claim_status.dart';

enum ClaimReviewAction { approve, reject, requestMoreInfo, withdraw }

/// Prepared review decision for callable functions.
final class ClaimReviewPayload {
  const ClaimReviewPayload({
    required this.claimId,
    required this.action,
    required this.notes,
    required this.nextStatus,
  });

  final String claimId;
  final ClaimReviewAction action;
  final String notes;
  final ClaimStatus nextStatus;

  String get functionName => switch (action) {
        ClaimReviewAction.approve => 'approveVenueClaim',
        ClaimReviewAction.reject => 'rejectVenueClaim',
        ClaimReviewAction.requestMoreInfo => 'requestMoreClaimInfo',
        ClaimReviewAction.withdraw => 'withdrawVenueClaim',
      };

  Map<String, dynamic> toFunctionPayload() {
    return {
      'claimId': claimId,
      'notes': notes,
    };
  }
}

/// Validates admin review and withdrawal decisions.
final class ClaimReviewService {
  const ClaimReviewService();

  ClaimResult<ClaimReviewPayload> prepareReview({
    required String claimId,
    required ClaimReviewAction action,
    required ClaimStatus currentStatus,
    required String notes,
    required bool reviewerCanApprove,
  }) {
    if (claimId.trim().isEmpty) {
      return const ClaimFailure('claim-id-required', 'Claim not found.');
    }

    if (action == ClaimReviewAction.withdraw) {
      if (!ClaimStatusTransitions.canWithdraw(currentStatus)) {
        return const ClaimFailure(
          'invalid-status-transition',
          'This claim cannot be withdrawn yet.',
        );
      }
      return ClaimSuccess(
        ClaimReviewPayload(
          claimId: claimId.trim(),
          action: action,
          notes: notes.trim(),
          nextStatus: ClaimStatusTransitions.statusAfterWithdraw(currentStatus),
        ),
      );
    }

    if (!reviewerCanApprove) {
      return const ClaimFailure(
        'permission-denied',
        'You do not have permission to review claims.',
      );
    }

    final trimmedNotes = notes.trim();
    if (action != ClaimReviewAction.approve && trimmedNotes.isEmpty) {
      return const ClaimFailure(
        'review-notes-required',
        'Add review notes before continuing.',
      );
    }

    final allowed = switch (action) {
      ClaimReviewAction.approve => ClaimStatusTransitions.canApprove,
      ClaimReviewAction.reject => ClaimStatusTransitions.canReject,
      ClaimReviewAction.requestMoreInfo =>
        ClaimStatusTransitions.canRequestMoreInfo,
      ClaimReviewAction.withdraw => ClaimStatusTransitions.canWithdraw,
    };

    if (!allowed(currentStatus)) {
      return const ClaimFailure(
        'invalid-status-transition',
        'This claim cannot move to that status yet.',
      );
    }

    final nextStatus = switch (action) {
      ClaimReviewAction.approve =>
        ClaimStatusTransitions.statusAfterApprove(currentStatus),
      ClaimReviewAction.reject =>
        ClaimStatusTransitions.statusAfterReject(currentStatus),
      ClaimReviewAction.requestMoreInfo =>
        ClaimStatusTransitions.statusAfterRequestMoreInfo(currentStatus),
      ClaimReviewAction.withdraw =>
        ClaimStatusTransitions.statusAfterWithdraw(currentStatus),
    };

    return ClaimSuccess(
      ClaimReviewPayload(
        claimId: claimId.trim(),
        action: action,
        notes: trimmedNotes,
        nextStatus: nextStatus,
      ),
    );
  }
}
