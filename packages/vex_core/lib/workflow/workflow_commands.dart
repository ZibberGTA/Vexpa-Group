import 'workflow_snapshots.dart';

/// Actor context carried by workflow commands.
final class WorkflowActorContext {
  const WorkflowActorContext({required this.uid, required this.kind});

  final String uid;
  final String kind;
}

/// Creates a new draft workflow request.
final class CreateWorkflowDraftCommand {
  const CreateWorkflowDraftCommand({
    required this.requestId,
    required this.workflowType,
    required this.submittedByUid,
    required this.subjectRefs,
    required this.payload,
    required this.actor,
  });

  final String requestId;
  final String workflowType;
  final String submittedByUid;
  final WorkflowSubjectRefsSnapshot subjectRefs;
  final WorkflowPayloadSnapshot payload;
  final WorkflowActorContext actor;
}

/// Updates an existing draft workflow request.
final class UpdateWorkflowDraftCommand {
  const UpdateWorkflowDraftCommand({
    required this.requestId,
    required this.expectedRevision,
    required this.payload,
    required this.actor,
  });

  final String requestId;
  final int expectedRevision;
  final WorkflowPayloadSnapshot payload;
  final WorkflowActorContext actor;
}

/// Submits a draft workflow request for review.
final class SubmitWorkflowCommand {
  const SubmitWorkflowCommand({
    required this.requestId,
    required this.expectedRevision,
    required this.actor,
  });

  final String requestId;
  final int expectedRevision;
  final WorkflowActorContext actor;
}

/// Resubmits after information was requested.
final class ResubmitWorkflowCommand {
  const ResubmitWorkflowCommand({
    required this.requestId,
    required this.expectedRevision,
    required this.payload,
    required this.actor,
  });

  final String requestId;
  final int expectedRevision;
  final WorkflowPayloadSnapshot payload;
  final WorkflowActorContext actor;
}

/// Withdraws an open workflow request.
final class WithdrawWorkflowCommand {
  const WithdrawWorkflowCommand({
    required this.requestId,
    required this.expectedRevision,
    required this.actor,
    this.notes,
  });

  final String requestId;
  final int expectedRevision;
  final WorkflowActorContext actor;
  final String? notes;
}

/// Privileged workflow commands executed through trusted gateways.
sealed class WorkflowPrivilegedCommand {
  const WorkflowPrivilegedCommand({
    required this.requestId,
    required this.expectedRevision,
    required this.actor,
  });

  final String requestId;
  final int expectedRevision;
  final WorkflowActorContext actor;
}

final class StartWorkflowReviewCommand extends WorkflowPrivilegedCommand {
  const StartWorkflowReviewCommand({
    required super.requestId,
    required super.expectedRevision,
    required super.actor,
    this.notes,
  });

  final String? notes;
}

final class RequestWorkflowInformationCommand
    extends WorkflowPrivilegedCommand {
  const RequestWorkflowInformationCommand({
    required super.requestId,
    required super.expectedRevision,
    required super.actor,
    required this.notes,
  });

  final String notes;
}

final class ApproveWorkflowCommand extends WorkflowPrivilegedCommand {
  const ApproveWorkflowCommand({
    required super.requestId,
    required super.expectedRevision,
    required super.actor,
    this.notes,
    this.reason,
    this.decisionCode,
  });

  final String? notes;
  final String? reason;
  final String? decisionCode;
}

final class RejectWorkflowCommand extends WorkflowPrivilegedCommand {
  const RejectWorkflowCommand({
    required super.requestId,
    required super.expectedRevision,
    required super.actor,
    this.notes,
    this.reason,
    this.decisionCode,
  });

  final String? notes;
  final String? reason;
  final String? decisionCode;
}

final class CancelWorkflowCommand extends WorkflowPrivilegedCommand {
  const CancelWorkflowCommand({
    required super.requestId,
    required super.expectedRevision,
    required super.actor,
    this.notes,
    this.reason,
    this.decisionCode,
  });

  final String? notes;
  final String? reason;
  final String? decisionCode;
}

final class AssignWorkflowReviewerCommand extends WorkflowPrivilegedCommand {
  const AssignWorkflowReviewerCommand({
    required super.requestId,
    required super.expectedRevision,
    required super.actor,
    required this.assignedReviewerUid,
    this.notes,
  });

  final String assignedReviewerUid;
  final String? notes;
}

final class ExpireWorkflowCommand extends WorkflowPrivilegedCommand {
  const ExpireWorkflowCommand({
    required super.requestId,
    required super.expectedRevision,
    required super.actor,
    this.reason,
  });

  final String? reason;
}
