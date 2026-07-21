import '../domain/workflow_action.dart';
import '../domain/workflow_actor.dart';
import '../domain/workflow_request.dart';
import '../domain/workflow_result.dart';
import '../domain/workflow_transition_plan.dart';
import 'ports/workflow_permission_port.dart';
import 'workflow_lifecycle_service.dart';

/// Plans administrative cancellation transitions.
final class WorkflowCancellationService {
  const WorkflowCancellationService({
    WorkflowLifecycleService lifecycleService =
        const WorkflowLifecycleService(),
  }) : _lifecycleService = lifecycleService;

  final WorkflowLifecycleService _lifecycleService;

  Future<WorkflowResult<WorkflowTransitionPlan>> planCancel({
    required WorkflowRequest request,
    required WorkflowActor actor,
    required WorkflowPermissionPort permissionPort,
    required String auditId,
    required DateTime occurredAt,
    int? expectedRevision,
    String? reason,
    String? decisionCode,
    String? notes,
  }) {
    return _lifecycleService.planTransition(
      request: request,
      action: WorkflowAction.cancel,
      actor: actor,
      permissionPort: permissionPort,
      auditId: auditId,
      occurredAt: occurredAt,
      expectedRevision: expectedRevision,
      notes: notes,
      reason: reason,
      decisionCode: decisionCode,
    );
  }
}
