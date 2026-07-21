import '../events/vex_event.dart';

/// Shared fields for generic workflow lifecycle events.
abstract base class VexWorkflowLifecycleEvent extends VexEvent {
  VexWorkflowLifecycleEvent({
    required this.requestId,
    required this.workflowType,
    required this.submittedByUid,
    required this.subjectRefs,
    required this.resultingStatus,
    required this.revision,
    String? id,
    DateTime? occurredAt,
  }) : super(
         id: id ?? _defaultId(requestId, occurredAt),
         occurredAt: occurredAt ?? DateTime.now(),
       );

  final String requestId;
  final String workflowType;
  final String submittedByUid;
  final Map<String, String> subjectRefs;
  final String resultingStatus;
  final int revision;

  static String _defaultId(String requestId, DateTime? occurredAt) {
    final stamp = (occurredAt ?? DateTime.now()).microsecondsSinceEpoch;
    return 'workflow-$requestId-$stamp';
  }
}

final class WorkflowSubmittedEvent extends VexWorkflowLifecycleEvent {
  WorkflowSubmittedEvent({
    required super.requestId,
    required super.workflowType,
    required super.submittedByUid,
    required super.subjectRefs,
    required super.resultingStatus,
    required super.revision,
    super.id,
    super.occurredAt,
  });

  @override
  String get type => 'workflow.submitted';
}

final class WorkflowReviewStartedEvent extends VexWorkflowLifecycleEvent {
  WorkflowReviewStartedEvent({
    required super.requestId,
    required super.workflowType,
    required super.submittedByUid,
    required super.subjectRefs,
    required super.resultingStatus,
    required super.revision,
    super.id,
    super.occurredAt,
  });

  @override
  String get type => 'workflow.review_started';
}

final class WorkflowInformationRequestedEvent
    extends VexWorkflowLifecycleEvent {
  WorkflowInformationRequestedEvent({
    required super.requestId,
    required super.workflowType,
    required super.submittedByUid,
    required super.subjectRefs,
    required super.resultingStatus,
    required super.revision,
    super.id,
    super.occurredAt,
  });

  @override
  String get type => 'workflow.information_requested';
}

final class WorkflowApprovedEvent extends VexWorkflowLifecycleEvent {
  WorkflowApprovedEvent({
    required super.requestId,
    required super.workflowType,
    required super.submittedByUid,
    required super.subjectRefs,
    required super.resultingStatus,
    required super.revision,
    super.id,
    super.occurredAt,
  });

  @override
  String get type => 'workflow.approved';
}

final class WorkflowRejectedEvent extends VexWorkflowLifecycleEvent {
  WorkflowRejectedEvent({
    required super.requestId,
    required super.workflowType,
    required super.submittedByUid,
    required super.subjectRefs,
    required super.resultingStatus,
    required super.revision,
    super.id,
    super.occurredAt,
  });

  @override
  String get type => 'workflow.rejected';
}

final class WorkflowWithdrawnEvent extends VexWorkflowLifecycleEvent {
  WorkflowWithdrawnEvent({
    required super.requestId,
    required super.workflowType,
    required super.submittedByUid,
    required super.subjectRefs,
    required super.resultingStatus,
    required super.revision,
    super.id,
    super.occurredAt,
  });

  @override
  String get type => 'workflow.withdrawn';
}

final class WorkflowCancelledEvent extends VexWorkflowLifecycleEvent {
  WorkflowCancelledEvent({
    required super.requestId,
    required super.workflowType,
    required super.submittedByUid,
    required super.subjectRefs,
    required super.resultingStatus,
    required super.revision,
    super.id,
    super.occurredAt,
  });

  @override
  String get type => 'workflow.cancelled';
}

final class WorkflowExpiredEvent extends VexWorkflowLifecycleEvent {
  WorkflowExpiredEvent({
    required super.requestId,
    required super.workflowType,
    required super.submittedByUid,
    required super.subjectRefs,
    required super.resultingStatus,
    required super.revision,
    super.id,
    super.occurredAt,
  });

  @override
  String get type => 'workflow.expired';
}

final class WorkflowReviewerAssignedEvent extends VexWorkflowLifecycleEvent {
  WorkflowReviewerAssignedEvent({
    required super.requestId,
    required super.workflowType,
    required super.submittedByUid,
    required super.subjectRefs,
    required super.resultingStatus,
    required super.revision,
    super.id,
    super.occurredAt,
  });

  @override
  String get type => 'workflow.reviewer_assigned';
}
