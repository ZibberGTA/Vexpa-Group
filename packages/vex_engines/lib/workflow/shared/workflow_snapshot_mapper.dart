import 'package:vex_core/workflow/workflow.dart';

import '../domain/workflow_payload.dart';
import '../domain/workflow_request.dart';
import '../domain/workflow_result.dart';
import '../domain/workflow_status.dart';
import '../domain/workflow_subject_refs.dart';
import '../domain/workflow_type_id.dart';

/// Maps VexCore workflow snapshots to VexWorkflow domain models.
abstract final class WorkflowSnapshotMapper {
  static WorkflowRequest toDomain(WorkflowRequestSnapshot snapshot) {
    final statusResult = WorkflowStatusTransitions.parsePersistenceValue(
      snapshot.status,
    );
    final status = statusResult is WorkflowSuccess<WorkflowStatus>
        ? statusResult.value
        : WorkflowStatus.draft;

    return WorkflowRequest(
      requestId: snapshot.requestId,
      workflowType: WorkflowTypeId(snapshot.workflowType),
      status: status,
      submittedByUid: snapshot.submittedByUid,
      subjectRefs: WorkflowSubjectRefs(snapshot.subjectRefs.values),
      payload: WorkflowPayload(
        values: Map<String, Object?>.from(snapshot.payload.values),
        schemaVersion: snapshot.payload.schemaVersion,
      ),
      assignedReviewerUid: snapshot.assignedReviewerUid,
      assignedReviewerUids: List<String>.from(snapshot.assignedReviewerUids),
      reviewNotesSummary: snapshot.reviewNotesSummary,
      decisionReason: snapshot.decisionReason,
      decisionCode: snapshot.decisionCode,
      expiresAt: snapshot.expiresAt,
      submittedAt: snapshot.submittedAt,
      decidedAt: snapshot.decidedAt,
      createdAt: snapshot.createdAt,
      updatedAt: snapshot.updatedAt,
      revision: snapshot.revision,
    );
  }

  static WorkflowSubjectRefsSnapshot toSubjectRefsSnapshot(
    WorkflowSubjectRefs subjectRefs,
  ) {
    return WorkflowSubjectRefsSnapshot(
      Map<String, String>.from(subjectRefs.values),
    );
  }

  static WorkflowPayloadSnapshot toPayloadSnapshot(WorkflowPayload payload) {
    return WorkflowPayloadSnapshot(
      values: Map<String, Object?>.from(payload.values),
      schemaVersion: payload.schemaVersion,
    );
  }
}
