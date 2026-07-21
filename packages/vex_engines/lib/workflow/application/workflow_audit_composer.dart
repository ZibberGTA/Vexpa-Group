import '../domain/workflow_action.dart';
import '../domain/workflow_actor.dart';
import '../domain/workflow_audit_action.dart';
import '../domain/workflow_audit_entry.dart';
import '../domain/workflow_status.dart';

/// Builds consistent workflow audit entries.
final class WorkflowAuditComposer {
  const WorkflowAuditComposer();

  WorkflowAuditAction auditActionFor(WorkflowAction action) => switch (action) {
    WorkflowAction.createDraft => WorkflowAuditAction.draftCreated,
    WorkflowAction.updateDraft => WorkflowAuditAction.draftUpdated,
    WorkflowAction.submit => WorkflowAuditAction.submitted,
    WorkflowAction.resubmit => WorkflowAuditAction.resubmitted,
    WorkflowAction.startReview => WorkflowAuditAction.reviewStarted,
    WorkflowAction.requestInformation =>
      WorkflowAuditAction.informationRequested,
    WorkflowAction.approve => WorkflowAuditAction.approved,
    WorkflowAction.reject => WorkflowAuditAction.rejected,
    WorkflowAction.withdraw => WorkflowAuditAction.withdrawn,
    WorkflowAction.cancel => WorkflowAuditAction.cancelled,
    WorkflowAction.expire => WorkflowAuditAction.expired,
    WorkflowAction.assignReviewer => WorkflowAuditAction.reviewerAssigned,
  };

  WorkflowAuditEntry compose({
    required String auditId,
    required String requestId,
    required WorkflowAction action,
    required WorkflowStatus fromStatus,
    required WorkflowStatus toStatus,
    required WorkflowActor actor,
    required DateTime createdAt,
    String? notes,
    String? reason,
    Map<String, Object?> metadata = const {},
  }) {
    return WorkflowAuditEntry(
      auditId: auditId,
      requestId: requestId,
      action: auditActionFor(action),
      fromStatus: fromStatus,
      toStatus: toStatus,
      actor: actor,
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      reason: reason?.trim().isEmpty == true ? null : reason?.trim(),
      metadata: metadata,
      createdAt: createdAt,
    );
  }
}
