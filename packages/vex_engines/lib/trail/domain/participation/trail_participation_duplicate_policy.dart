import '../../../workflow/domain/workflow_status.dart';

/// Duplicate and reapply rules for venue trail participation applications.
///
/// - Open statuses block creating a new application for the same trail + venue.
/// - Approved applications block another application for the same trail + venue.
/// - Rejected, withdrawn, cancelled, and expired history allow a new request.
/// - Information-requested applications must be resubmitted on the same request.
abstract final class TrailParticipationDuplicatePolicy {
  static const blockingOpenStatuses = {
    WorkflowStatus.draft,
    WorkflowStatus.submitted,
    WorkflowStatus.underReview,
    WorkflowStatus.informationRequested,
  };

  static bool blocksNewApplication(WorkflowStatus status) {
    return status == WorkflowStatus.approved ||
        blockingOpenStatuses.contains(status);
  }

  static bool requiresResubmit(WorkflowStatus status) {
    return status == WorkflowStatus.informationRequested;
  }

  static bool allowsReapply(WorkflowStatus status) {
    return status == WorkflowStatus.rejected ||
        status == WorkflowStatus.withdrawn ||
        status == WorkflowStatus.cancelled ||
        status == WorkflowStatus.expired;
  }
}
