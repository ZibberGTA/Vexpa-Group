/// Planned consequence of an approved participation application.
///
/// Not executed in the venue participation foundation phase.
final class TrailParticipationApprovalPlan {
  const TrailParticipationApprovalPlan({
    required this.requestId,
    required this.trailId,
    required this.venueId,
    required this.approvedRequestedStopOrder,
    required this.existingTrailRevision,
    required this.proposedInsertionOrder,
    this.conflictWarnings = const [],
    this.requiresManualPlacement = false,
    this.metadata = const {},
  });

  final String requestId;
  final String trailId;
  final String venueId;
  final int approvedRequestedStopOrder;
  final int existingTrailRevision;
  final int proposedInsertionOrder;
  final List<String> conflictWarnings;
  final bool requiresManualPlacement;
  final Map<String, Object?> metadata;
}
