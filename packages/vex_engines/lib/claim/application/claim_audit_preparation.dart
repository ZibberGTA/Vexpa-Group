/// Prepares audit trail entries for completed claim actions.
final class ClaimAuditPreparation {
  ClaimAuditPreparation._();

  static Map<String, dynamic> event({
    required String type,
    required String actorUid,
    required String actorRole,
    required String message,
    Map<String, dynamic> metadata = const {},
  }) {
    return {
      'type': type,
      'actorUid': actorUid,
      'actorRole': actorRole,
      'message': message,
      'metadata': metadata,
    };
  }

  static Map<String, dynamic> submissionEvent({
    required String claimantUid,
    required int confidenceScore,
    required bool autoApproved,
  }) =>
      event(
        type: 'claim_submitted',
        actorUid: claimantUid,
        actorRole: 'claimant',
        message: autoApproved
            ? 'Claim submitted and auto-approved.'
            : 'Claim submitted for review.',
        metadata: {
          'confidenceScore': confidenceScore,
          'autoApproved': autoApproved,
        },
      );

  static Map<String, dynamic> reviewEvent({
    required String reviewerUid,
    required String action,
    required String notes,
  }) =>
      event(
        type: 'claim_review',
        actorUid: reviewerUid,
        actorRole: 'reviewer',
        message: 'Claim $action.',
        metadata: {'notes': notes, 'action': action},
      );
}

/// Prepares ownership assignment fields after claim approval.
final class ClaimOwnershipTransferPreparation {
  ClaimOwnershipTransferPreparation._();

  static Map<String, dynamic> assignOwner({
    required String claimantUid,
    required String claimId,
    required String venueId,
  }) {
    return {
      'ownerId': claimantUid,
      'ownerIds': [claimantUid],
      'claimedBy': claimantUid,
      'isClaimed': true,
      'claimStatus': 'claimed',
      'activeClaimId': claimId,
      'venueId': venueId,
    };
  }
}
