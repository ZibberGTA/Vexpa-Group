import '../domain/workflow_action.dart';
import '../domain/workflow_actor.dart';
import '../domain/workflow_request.dart';
import '../domain/workflow_result.dart';
import '../domain/workflow_transition_plan.dart';
import 'ports/workflow_permission_port.dart';
import 'workflow_lifecycle_service.dart';

/// Plans submitter withdrawal transitions.
final class WorkflowWithdrawalService {
  const WorkflowWithdrawalService({
    WorkflowLifecycleService lifecycleService =
        const WorkflowLifecycleService(),
  }) : _lifecycleService = lifecycleService;

  final WorkflowLifecycleService _lifecycleService;

  Future<WorkflowResult<WorkflowTransitionPlan>> planWithdraw({
    required WorkflowRequest request,
    required WorkflowActor actor,
    required WorkflowPermissionPort permissionPort,
    required String auditId,
    required DateTime occurredAt,
    int? expectedRevision,
    String? notes,
  }) {
    return _lifecycleService.planTransition(
      request: request,
      action: WorkflowAction.withdraw,
      actor: actor,
      permissionPort: permissionPort,
      auditId: auditId,
      occurredAt: occurredAt,
      expectedRevision: expectedRevision,
      notes: notes,
    );
  }
}
