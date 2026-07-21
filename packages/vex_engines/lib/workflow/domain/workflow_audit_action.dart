/// Standard immutable audit actions recorded for workflow requests.
enum WorkflowAuditAction {
  draftCreated,
  draftUpdated,
  submitted,
  reviewStarted,
  informationRequested,
  resubmitted,
  reviewerAssigned,
  approved,
  rejected,
  withdrawn,
  cancelled,
  expired,
}

extension WorkflowAuditActionCodec on WorkflowAuditAction {
  String get persistenceValue => switch (this) {
    WorkflowAuditAction.draftCreated => 'draft_created',
    WorkflowAuditAction.draftUpdated => 'draft_updated',
    WorkflowAuditAction.submitted => 'submitted',
    WorkflowAuditAction.reviewStarted => 'review_started',
    WorkflowAuditAction.informationRequested => 'information_requested',
    WorkflowAuditAction.resubmitted => 'resubmitted',
    WorkflowAuditAction.reviewerAssigned => 'reviewer_assigned',
    WorkflowAuditAction.approved => 'approved',
    WorkflowAuditAction.rejected => 'rejected',
    WorkflowAuditAction.withdrawn => 'withdrawn',
    WorkflowAuditAction.cancelled => 'cancelled',
    WorkflowAuditAction.expired => 'expired',
  };
}
