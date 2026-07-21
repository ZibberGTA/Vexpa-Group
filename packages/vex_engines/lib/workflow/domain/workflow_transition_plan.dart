import 'package:vex_core/events/vex_event.dart';

import 'workflow_action.dart';
import 'workflow_audit_entry.dart';
import 'workflow_request.dart';
import 'workflow_status.dart';

/// Planned workflow transition produced by application services.
///
/// Does not perform persistence.
final class WorkflowTransitionPlan {
  const WorkflowTransitionPlan({
    required this.currentStatus,
    required this.nextStatus,
    required this.action,
    required this.requestPatch,
    required this.auditEntry,
    required this.events,
    this.proposedRequest,
  });

  final WorkflowStatus currentStatus;
  final WorkflowStatus nextStatus;
  final WorkflowAction action;
  final WorkflowRequestPatch requestPatch;
  final WorkflowAuditEntry auditEntry;
  final List<VexEvent> events;
  final WorkflowRequest? proposedRequest;
}
