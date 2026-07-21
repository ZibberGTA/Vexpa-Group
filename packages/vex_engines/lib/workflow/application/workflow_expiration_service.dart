import '../domain/workflow_action.dart';
import '../domain/workflow_actor.dart';
import '../domain/workflow_request.dart';
import '../domain/workflow_result.dart';
import '../domain/workflow_transition_plan.dart';
import 'ports/workflow_permission_port.dart';
import 'workflow_lifecycle_service.dart';

/// Plans trusted system expiry transitions.
final class WorkflowExpirationService {
  const WorkflowExpirationService({
    WorkflowLifecycleService lifecycleService =
        const WorkflowLifecycleService(),
  }) : _lifecycleService = lifecycleService;

  final WorkflowLifecycleService _lifecycleService;

  Future<WorkflowResult<WorkflowTransitionPlan>> planExpire({
    required WorkflowRequest request,
    required WorkflowActor systemActor,
    required WorkflowPermissionPort permissionPort,
    required String auditId,
    required DateTime occurredAt,
    int? expectedRevision,
    String? reason,
  }) {
    if (systemActor.kind != WorkflowActorKind.system) {
      return Future.value(
        const WorkflowFailure(
          WorkflowFailureCodes.invalidActor,
          'Workflow expiry must be executed by a system actor.',
        ),
      );
    }

    return _lifecycleService.planTransition(
      request: request,
      action: WorkflowAction.expire,
      actor: systemActor,
      permissionPort: permissionPort,
      auditId: auditId,
      occurredAt: occurredAt,
      expectedRevision: expectedRevision,
      reason: reason,
    );
  }
}
