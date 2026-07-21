/// Query for listing workflow requests.
final class WorkflowListQuery {
  const WorkflowListQuery({
    this.workflowType,
    this.statuses = const [],
    this.submittedByUid,
    this.assignedReviewerUid,
    this.subjectVenueId,
    this.subjectTrailId,
    this.orderByUpdatedAtDesc = false,
    this.limit = 50,
  });

  final String? workflowType;
  final List<String> statuses;
  final String? submittedByUid;
  final String? assignedReviewerUid;

  /// Indexed top-level subject field for venue-side queries.
  final String? subjectVenueId;

  /// Indexed top-level subject field for trail + venue duplicate detection.
  final String? subjectTrailId;

  /// When true, adapters should order by `updatedAt` descending.
  final bool orderByUpdatedAtDesc;
  final int limit;
}
