import 'claim_evidence.dart';
import 'claim_status.dart';

/// Provider-independent claim list record for summaries and ordering.
final class ClaimListEntry {
  const ClaimListEntry({
    required this.id,
    required this.venueId,
    required this.venueName,
    required this.claimantUid,
    required this.claimantEmail,
    required this.status,
    required this.autoApproved,
    required this.confidenceScore,
    required this.evidence,
    this.submittedAt,
    this.reviewNotes = '',
  });

  final String id;
  final String venueId;
  final String venueName;
  final String claimantUid;
  final String claimantEmail;
  final ClaimStatus status;
  final bool autoApproved;
  final int confidenceScore;
  final ClaimEvidence evidence;
  final DateTime? submittedAt;
  final String reviewNotes;

  bool get isPending => status.isPending;
}
