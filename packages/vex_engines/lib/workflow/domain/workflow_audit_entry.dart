import 'workflow_actor.dart';
import 'workflow_audit_action.dart';
import 'workflow_status.dart';

/// Append-only workflow audit entry draft produced by orchestration services.
final class WorkflowAuditEntry {
  const WorkflowAuditEntry({
    required this.auditId,
    required this.requestId,
    required this.action,
    required this.fromStatus,
    required this.toStatus,
    required this.actor,
    required this.createdAt,
    this.notes,
    this.reason,
    this.metadata = const {},
  });

  final String auditId;
  final String requestId;
  final WorkflowAuditAction action;
  final WorkflowStatus fromStatus;
  final WorkflowStatus toStatus;
  final WorkflowActor actor;
  final String? notes;
  final String? reason;
  final Map<String, Object?> metadata;
  final DateTime createdAt;
}
