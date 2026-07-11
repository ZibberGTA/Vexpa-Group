import '../domain/claim_evidence.dart';
import '../domain/claim_list_entry.dart';
import '../domain/claim_result.dart';
import '../domain/claim_status.dart';
import 'claim_evidence_validator.dart';

/// Admin dashboard metrics derived from claim list entries.
final class ClaimAdminMetrics {
  const ClaimAdminMetrics({
    required this.total,
    required this.pendingReview,
    required this.autoApproved,
  });

  final int total;
  final int pendingReview;
  final int autoApproved;
}

/// Claimant-facing summary for a single claim.
final class ClaimantClaimSummary {
  const ClaimantClaimSummary({
    required this.claimId,
    required this.venueLabel,
    required this.statusLabel,
    required this.canWithdraw,
    required this.evidenceComplete,
  });

  final String claimId;
  final String venueLabel;
  final String statusLabel;
  final bool canWithdraw;
  final bool evidenceComplete;
}

/// Admin review panel summary for a selected claim.
final class ClaimAdminReviewSummary {
  const ClaimAdminReviewSummary({
    required this.claimId,
    required this.statusLabel,
    required this.canApprove,
    required this.canReject,
    required this.canRequestMoreInfo,
    required this.evidenceComplete,
    required this.reviewReady,
  });

  final String claimId;
  final String statusLabel;
  final bool canApprove;
  final bool canReject;
  final bool canRequestMoreInfo;
  final bool evidenceComplete;
  final bool reviewReady;
}

/// Summaries, metrics, and deterministic ordering for claim lists.
final class ClaimSummaryService {
  const ClaimSummaryService({
    ClaimEvidenceValidator evidenceValidator = const ClaimEvidenceValidator(),
  }) : _evidenceValidator = evidenceValidator;

  final ClaimEvidenceValidator _evidenceValidator;

  ClaimAdminMetrics adminMetrics(Iterable<ClaimListEntry> claims) {
    final list = claims.toList(growable: false);
    return ClaimAdminMetrics(
      total: list.length,
      pendingReview: list.where((claim) => claim.isPending).length,
      autoApproved: list.where((claim) => claim.autoApproved).length,
    );
  }

  List<ClaimListEntry> orderForAdminDisplay(List<ClaimListEntry> claims) {
    final ordered = List<ClaimListEntry>.from(claims);
    ordered.sort((left, right) {
      final leftTime = left.submittedAt?.millisecondsSinceEpoch ?? 0;
      final rightTime = right.submittedAt?.millisecondsSinceEpoch ?? 0;
      if (leftTime != rightTime) {
        return rightTime.compareTo(leftTime);
      }
      return right.id.compareTo(left.id);
    });
    return ordered;
  }

  ClaimantClaimSummary claimantSummary(ClaimListEntry claim) {
    return ClaimantClaimSummary(
      claimId: claim.id,
      venueLabel: claim.venueName.isEmpty ? claim.venueId : claim.venueName,
      statusLabel: claim.status.label,
      canWithdraw: ClaimStatusTransitions.canWithdraw(claim.status),
      evidenceComplete: isEvidenceComplete(claim.evidence),
    );
  }

  ClaimAdminReviewSummary adminReviewSummary({
    required ClaimListEntry claim,
    required bool reviewerCanApprove,
  }) {
    final evidenceComplete = isEvidenceComplete(claim.evidence);
    final reviewReady =
        reviewerCanApprove && claim.isPending && evidenceComplete;

    return ClaimAdminReviewSummary(
      claimId: claim.id,
      statusLabel: claim.status.label,
      canApprove:
          reviewerCanApprove && ClaimStatusTransitions.canApprove(claim.status),
      canReject:
          reviewerCanApprove && ClaimStatusTransitions.canReject(claim.status),
      canRequestMoreInfo:
          reviewerCanApprove &&
          ClaimStatusTransitions.canRequestMoreInfo(claim.status),
      evidenceComplete: evidenceComplete,
      reviewReady: reviewReady,
    );
  }

  bool isEvidenceComplete(ClaimEvidence evidence) =>
      _evidenceValidator.validate(evidence) is ClaimSuccess<ClaimEvidence>;

  ClaimResult<bool> submissionReadiness({
    required ClaimEvidence evidence,
    required bool claimantActive,
    required Iterable<ClaimStatus> existingStatusesForVenue,
  }) {
    if (!claimantActive) {
      return const ClaimFailure(
        'claimant-inactive',
        'Your account cannot submit claims right now.',
      );
    }
    if (!ClaimStatusTransitions.canSubmit(
      existingStatusesForVenue: existingStatusesForVenue,
    )) {
      return const ClaimFailure(
        'open-claim-exists',
        'You already have an active claim for this venue.',
      );
    }

    final evidenceResult = _evidenceValidator.validate(evidence);
    if (evidenceResult is ClaimFailure<ClaimEvidence>) {
      return ClaimFailure(evidenceResult.code, evidenceResult.message);
    }
    return const ClaimSuccess(true);
  }
}
