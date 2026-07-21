import '../domain/workflow_action.dart';
import '../domain/workflow_actor.dart';
import '../domain/workflow_request.dart';
import '../domain/workflow_result.dart';
import '../domain/workflow_transition_plan.dart';
import 'ports/workflow_permission_port.dart';
import 'workflow_lifecycle_service.dart';

/// Plans reviewer assignment without lifecycle status changes.
final class WorkflowAssignmentService {
  const WorkflowAssignmentService({
    WorkflowLifecycleService lifecycleService =
        const WorkflowLifecycleService(),
  }) : _lifecycleService = lifecycleService;

  final WorkflowLifecycleService _lifecycleService;

  Future<WorkflowResult<WorkflowTransitionPlan>> planAssignReviewer({
    required WorkflowRequest request,
    required WorkflowActor actor,
    required WorkflowPermissionPort permissionPort,
    required String assignedReviewerUid,
    required String auditId,
    required DateTime occurredAt,
    int? expectedRevision,
    String? notes,
  }) {
    if (assignedReviewerUid.trim().isEmpty) {
      return Future.value(
        const WorkflowFailure(
          WorkflowFailureCodes.invalidActor,
          'Assigned reviewer uid is required.',
        ),
      );
    }

    return _lifecycleService.planTransition(
      request: request,
      action: WorkflowAction.assignReviewer,
      actor: actor,
      permissionPort: permissionPort,
      auditId: auditId,
      occurredAt: occurredAt,
      expectedRevision: expectedRevision,
      notes: notes,
      assignedReviewerUid: assignedReviewerUid.trim(),
    );
  }
}
