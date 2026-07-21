import 'workflow_payload.dart';
import 'workflow_status.dart';
import 'workflow_subject_refs.dart';
import 'workflow_type_id.dart';

/// Immutable workflow request aggregate used by the VexWorkflow engine.
final class WorkflowRequest {
  const WorkflowRequest({
    required this.requestId,
    required this.workflowType,
    required this.status,
    required this.submittedByUid,
    required this.subjectRefs,
    required this.payload,
    required this.createdAt,
    required this.updatedAt,
    required this.revision,
    this.assignedReviewerUid,
    this.assignedReviewerUids = const [],
    this.reviewNotesSummary,
    this.decisionReason,
    this.decisionCode,
    this.expiresAt,
    this.submittedAt,
    this.decidedAt,
  });

  final String requestId;
  final WorkflowTypeId workflowType;
  final WorkflowStatus status;
  final String submittedByUid;
  final WorkflowSubjectRefs subjectRefs;
  final WorkflowPayload payload;
  final String? assignedReviewerUid;
  final List<String> assignedReviewerUids;
  final String? reviewNotesSummary;
  final String? decisionReason;
  final String? decisionCode;
  final DateTime? expiresAt;
  final DateTime? submittedAt;
  final DateTime? decidedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int revision;

  WorkflowRequest applyPatch(WorkflowRequestPatch patch) {
    return WorkflowRequest(
      requestId: requestId,
      workflowType: workflowType,
      status: patch.status ?? status,
      submittedByUid: submittedByUid,
      subjectRefs: patch.subjectRefs ?? subjectRefs,
      payload: patch.payload ?? payload,
      assignedReviewerUid: patch.assignedReviewerUid ?? assignedReviewerUid,
      assignedReviewerUids: patch.assignedReviewerUids ?? assignedReviewerUids,
      reviewNotesSummary: patch.reviewNotesSummary ?? reviewNotesSummary,
      decisionReason: patch.decisionReason ?? decisionReason,
      decisionCode: patch.decisionCode ?? decisionCode,
      expiresAt: patch.expiresAt ?? expiresAt,
      submittedAt: patch.submittedAt ?? submittedAt,
      decidedAt: patch.decidedAt ?? decidedAt,
      createdAt: createdAt,
      updatedAt: patch.updatedAt ?? updatedAt,
      revision: patch.revision ?? revision,
    );
  }
}

/// Immutable patch produced by transition planning.
final class WorkflowRequestPatch {
  const WorkflowRequestPatch({
    this.status,
    this.subjectRefs,
    this.payload,
    this.assignedReviewerUid,
    this.assignedReviewerUids,
    this.reviewNotesSummary,
    this.decisionReason,
    this.decisionCode,
    this.expiresAt,
    this.submittedAt,
    this.decidedAt,
    this.updatedAt,
    this.revision,
  });

  final WorkflowStatus? status;
  final WorkflowSubjectRefs? subjectRefs;
  final WorkflowPayload? payload;
  final String? assignedReviewerUid;
  final List<String>? assignedReviewerUids;
  final String? reviewNotesSummary;
  final String? decisionReason;
  final String? decisionCode;
  final DateTime? expiresAt;
  final DateTime? submittedAt;
  final DateTime? decidedAt;
  final DateTime? updatedAt;
  final int? revision;
}
