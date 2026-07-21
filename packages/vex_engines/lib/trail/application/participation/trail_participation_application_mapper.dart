import 'package:vex_core/workflow/workflow.dart';

import '../../../workflow/domain/workflow_result.dart';
import '../../../workflow/domain/workflow_status.dart';
import '../../domain/participation/trail_participation_application.dart';
import '../../domain/participation/trail_participation_submission_payload.dart';

/// Maps workflow snapshots into participation domain models.
abstract final class TrailParticipationApplicationMapper {
  static TrailParticipationApplication? fromWorkflowSnapshot(
    WorkflowRequestSnapshot snapshot,
  ) {
    final statusResult = WorkflowStatusTransitions.parsePersistenceValue(
      snapshot.status,
    );
    if (statusResult is! WorkflowSuccess<WorkflowStatus>) {
      return null;
    }

    final payload = TrailParticipationSubmissionPayload.fromPayloadValues(
      snapshot.payload.values,
    );
    if (payload == null) return null;

    return TrailParticipationApplication.fromPayload(
      workflowRequestId: snapshot.requestId,
      workflowStatus: statusResult.value,
      submittedByUid: snapshot.submittedByUid,
      payload: payload,
      updatedAt: snapshot.updatedAt,
      revision: snapshot.revision,
      submittedAt: snapshot.submittedAt,
      createdAt: snapshot.createdAt,
      decidedAt: snapshot.decidedAt,
      decisionReason: snapshot.decisionReason,
      informationRequestNote: snapshot.reviewNotesSummary,
    );
  }
}
