import '../domain/workflow_action.dart';
import '../domain/workflow_actor.dart';
import '../domain/workflow_request.dart';
import '../domain/workflow_result.dart';
import '../domain/workflow_transition_plan.dart';
import 'ports/workflow_permission_port.dart';
import 'workflow_lifecycle_service.dart';

/// Plans reviewer actions for open workflow requests.
final class WorkflowReviewService {
  const WorkflowReviewService({
    WorkflowLifecycleService lifecycleService =
        const WorkflowLifecycleService(),
  }) : _lifecycleService = lifecycleService;

  final WorkflowLifecycleService _lifecycleService;

  Future<WorkflowResult<WorkflowTransitionPlan>> planStartReview({
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
      action: WorkflowAction.startReview,
      actor: actor,
      permissionPort: permissionPort,
      auditId: auditId,
      occurredAt: occurredAt,
      expectedRevision: expectedRevision,
      notes: notes,
    );
  }

  Future<WorkflowResult<WorkflowTransitionPlan>> planRequestInformation({
    required WorkflowRequest request,
    required WorkflowActor actor,
    required WorkflowPermissionPort permissionPort,
    required String auditId,
    required DateTime occurredAt,
    int? expectedRevision,
    required String notes,
  }) {
    return _lifecycleService.planTransition(
      request: request,
      action: WorkflowAction.requestInformation,
      actor: actor,
      permissionPort: permissionPort,
      auditId: auditId,
      occurredAt: occurredAt,
      expectedRevision: expectedRevision,
      notes: notes,
    );
  }

  Future<WorkflowResult<WorkflowTransitionPlan>> planApprove({
    required WorkflowRequest request,
    required WorkflowActor actor,
    required WorkflowPermissionPort permissionPort,
    required String auditId,
    required DateTime occurredAt,
    int? expectedRevision,
    String? notes,
    String? reason,
    String? decisionCode,
  }) {
    return _lifecycleService.planTransition(
      request: request,
      action: WorkflowAction.approve,
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

  Future<WorkflowResult<WorkflowTransitionPlan>> planReject({
    required WorkflowRequest request,
    required WorkflowActor actor,
    required WorkflowPermissionPort permissionPort,
    required String auditId,
    required DateTime occurredAt,
    int? expectedRevision,
    String? notes,
    String? reason,
    String? decisionCode,
  }) {
    return _lifecycleService.planTransition(
      request: request,
      action: WorkflowAction.reject,
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
