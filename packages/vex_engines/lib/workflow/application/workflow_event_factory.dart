import 'package:vex_core/events/workflow_events.dart';

import '../domain/workflow_action.dart';
import '../domain/workflow_request.dart';
import '../domain/workflow_status.dart';

/// Builds generic workflow lifecycle events from transition context.
final class WorkflowEventFactory {
  const WorkflowEventFactory();

  List<VexWorkflowLifecycleEvent> eventsFor({
    required WorkflowAction action,
    required WorkflowRequest proposedRequest,
    DateTime? occurredAt,
  }) {
    final common = _CommonEventFields(
      requestId: proposedRequest.requestId,
      workflowType: proposedRequest.workflowType.value,
      submittedByUid: proposedRequest.submittedByUid,
      subjectRefs: Map<String, String>.from(proposedRequest.subjectRefs.values),
      resultingStatus: proposedRequest.status.persistenceValue,
      revision: proposedRequest.revision,
      occurredAt: occurredAt,
    );

    return switch (action) {
      WorkflowAction.submit || WorkflowAction.resubmit => [
        WorkflowSubmittedEvent(
          requestId: common.requestId,
          workflowType: common.workflowType,
          submittedByUid: common.submittedByUid,
          subjectRefs: common.subjectRefs,
          resultingStatus: common.resultingStatus,
          revision: common.revision,
          occurredAt: common.occurredAt,
        ),
      ],
      WorkflowAction.startReview => [
        WorkflowReviewStartedEvent(
          requestId: common.requestId,
          workflowType: common.workflowType,
          submittedByUid: common.submittedByUid,
          subjectRefs: common.subjectRefs,
          resultingStatus: common.resultingStatus,
          revision: common.revision,
          occurredAt: common.occurredAt,
        ),
      ],
      WorkflowAction.requestInformation => [
        WorkflowInformationRequestedEvent(
          requestId: common.requestId,
          workflowType: common.workflowType,
          submittedByUid: common.submittedByUid,
          subjectRefs: common.subjectRefs,
          resultingStatus: common.resultingStatus,
          revision: common.revision,
          occurredAt: common.occurredAt,
        ),
      ],
      WorkflowAction.approve => [
        WorkflowApprovedEvent(
          requestId: common.requestId,
          workflowType: common.workflowType,
          submittedByUid: common.submittedByUid,
          subjectRefs: common.subjectRefs,
          resultingStatus: common.resultingStatus,
          revision: common.revision,
          occurredAt: common.occurredAt,
        ),
      ],
      WorkflowAction.reject => [
        WorkflowRejectedEvent(
          requestId: common.requestId,
          workflowType: common.workflowType,
          submittedByUid: common.submittedByUid,
          subjectRefs: common.subjectRefs,
          resultingStatus: common.resultingStatus,
          revision: common.revision,
          occurredAt: common.occurredAt,
        ),
      ],
      WorkflowAction.withdraw => [
        WorkflowWithdrawnEvent(
          requestId: common.requestId,
          workflowType: common.workflowType,
          submittedByUid: common.submittedByUid,
          subjectRefs: common.subjectRefs,
          resultingStatus: common.resultingStatus,
          revision: common.revision,
          occurredAt: common.occurredAt,
        ),
      ],
      WorkflowAction.cancel => [
        WorkflowCancelledEvent(
          requestId: common.requestId,
          workflowType: common.workflowType,
          submittedByUid: common.submittedByUid,
          subjectRefs: common.subjectRefs,
          resultingStatus: common.resultingStatus,
          revision: common.revision,
          occurredAt: common.occurredAt,
        ),
      ],
      WorkflowAction.expire => [
        WorkflowExpiredEvent(
          requestId: common.requestId,
          workflowType: common.workflowType,
          submittedByUid: common.submittedByUid,
          subjectRefs: common.subjectRefs,
          resultingStatus: common.resultingStatus,
          revision: common.revision,
          occurredAt: common.occurredAt,
        ),
      ],
      WorkflowAction.assignReviewer => [
        WorkflowReviewerAssignedEvent(
          requestId: common.requestId,
          workflowType: common.workflowType,
          submittedByUid: common.submittedByUid,
          subjectRefs: common.subjectRefs,
          resultingStatus: common.resultingStatus,
          revision: common.revision,
          occurredAt: common.occurredAt,
        ),
      ],
      WorkflowAction.createDraft || WorkflowAction.updateDraft => const [],
    };
  }
}

final class _CommonEventFields {
  const _CommonEventFields({
    required this.requestId,
    required this.workflowType,
    required this.submittedByUid,
    required this.subjectRefs,
    required this.resultingStatus,
    required this.revision,
    this.occurredAt,
  });

  final String requestId;
  final String workflowType;
  final String submittedByUid;
  final Map<String, String> subjectRefs;
  final String resultingStatus;
  final int revision;
  final DateTime? occurredAt;
}
