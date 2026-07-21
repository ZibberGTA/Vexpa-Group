import '../domain/workflow_action.dart';
import '../domain/workflow_actor.dart';
import '../domain/workflow_payload.dart';
import '../domain/workflow_request.dart';
import '../domain/workflow_result.dart';
import '../domain/workflow_status.dart';
import '../domain/workflow_subject_refs.dart';
import '../domain/workflow_transition_plan.dart';
import '../domain/workflow_type_id.dart';
import 'ports/workflow_payload_validator_port.dart';
import 'ports/workflow_permission_port.dart';
import 'workflow_audit_composer.dart';
import 'workflow_lifecycle_service.dart';

/// Plans draft creation and submission transitions.
final class WorkflowSubmissionService {
  const WorkflowSubmissionService({
    WorkflowLifecycleService lifecycleService =
        const WorkflowLifecycleService(),
    WorkflowAuditComposer auditComposer = const WorkflowAuditComposer(),
  }) : _lifecycleService = lifecycleService,
       _auditComposer = auditComposer;

  final WorkflowLifecycleService _lifecycleService;
  final WorkflowAuditComposer _auditComposer;

  Future<WorkflowResult<WorkflowTransitionPlan>> planCreateDraft({
    required String requestId,
    required WorkflowTypeId workflowType,
    required String submittedByUid,
    required WorkflowSubjectRefs subjectRefs,
    required WorkflowPayload payload,
    required WorkflowActor actor,
    required WorkflowPermissionPort permissionPort,
    required WorkflowPayloadValidatorPort payloadValidator,
    required String auditId,
    required DateTime occurredAt,
  }) async {
    if (requestId.trim().isEmpty) {
      return const WorkflowFailure(
        WorkflowFailureCodes.requestIdRequired,
        'Workflow request id is required.',
      );
    }
    if (submittedByUid.trim().isEmpty) {
      return const WorkflowFailure(
        WorkflowFailureCodes.submitterRequired,
        'Workflow submitter uid is required.',
      );
    }

    final payloadResult = payloadValidator
        .validateDraft(payload)
        .toWorkflowResult();
    if (payloadResult is WorkflowFailure<void>) {
      return WorkflowFailure(payloadResult.code, payloadResult.message);
    }

    final draftRequest = WorkflowRequest(
      requestId: requestId.trim(),
      workflowType: workflowType,
      status: WorkflowStatus.draft,
      submittedByUid: submittedByUid.trim(),
      subjectRefs: subjectRefs,
      payload: payload,
      createdAt: occurredAt,
      updatedAt: occurredAt,
      revision: 1,
    );

    final capabilities = await permissionPort.resolve(
      actor: actor,
      request: draftRequest,
      action: WorkflowAction.createDraft,
    );
    if (!capabilities.canSubmit) {
      return const WorkflowFailure(
        WorkflowFailureCodes.permissionDenied,
        'You do not have permission to create this workflow request.',
      );
    }

    final auditEntry = _auditComposer.compose(
      auditId: auditId,
      requestId: draftRequest.requestId,
      action: WorkflowAction.createDraft,
      fromStatus: WorkflowStatus.draft,
      toStatus: WorkflowStatus.draft,
      actor: actor,
      createdAt: occurredAt,
    );

    return WorkflowSuccess(
      WorkflowTransitionPlan(
        currentStatus: WorkflowStatus.draft,
        nextStatus: WorkflowStatus.draft,
        action: WorkflowAction.createDraft,
        requestPatch: WorkflowRequestPatch(updatedAt: occurredAt, revision: 1),
        auditEntry: auditEntry,
        events: const [],
        proposedRequest: draftRequest,
      ),
    );
  }

  Future<WorkflowResult<WorkflowTransitionPlan>> planUpdateDraft({
    required WorkflowRequest request,
    required WorkflowPayload payload,
    required WorkflowActor actor,
    required WorkflowPermissionPort permissionPort,
    required WorkflowPayloadValidatorPort payloadValidator,
    required String auditId,
    required DateTime occurredAt,
    int? expectedRevision,
  }) {
    if (request.status != WorkflowStatus.draft) {
      return Future.value(
        const WorkflowFailure(
          WorkflowFailureCodes.invalidTransition,
          'Only draft workflow requests can be updated.',
        ),
      );
    }

    final payloadResult = payloadValidator
        .validateDraft(payload)
        .toWorkflowResult();
    if (payloadResult is WorkflowFailure<void>) {
      return Future.value(
        WorkflowFailure(payloadResult.code, payloadResult.message),
      );
    }

    return _lifecycleService.planTransition(
      request: request,
      action: WorkflowAction.updateDraft,
      actor: actor,
      permissionPort: permissionPort,
      auditId: auditId,
      occurredAt: occurredAt,
      expectedRevision: expectedRevision,
      payloadUpdate: payload,
    );
  }

  Future<WorkflowResult<WorkflowTransitionPlan>> planSubmit({
    required WorkflowRequest request,
    required WorkflowActor actor,
    required WorkflowPermissionPort permissionPort,
    required WorkflowPayloadValidatorPort payloadValidator,
    required String auditId,
    required DateTime occurredAt,
    int? expectedRevision,
  }) {
    final payloadResult = payloadValidator
        .validateSubmitted(request.payload)
        .toWorkflowResult();
    if (payloadResult is WorkflowFailure<void>) {
      return Future.value(
        WorkflowFailure(payloadResult.code, payloadResult.message),
      );
    }

    return _lifecycleService.planTransition(
      request: request,
      action: WorkflowAction.submit,
      actor: actor,
      permissionPort: permissionPort,
      auditId: auditId,
      occurredAt: occurredAt,
      expectedRevision: expectedRevision,
    );
  }

  Future<WorkflowResult<WorkflowTransitionPlan>> planResubmit({
    required WorkflowRequest request,
    required WorkflowPayload payload,
    required WorkflowActor actor,
    required WorkflowPermissionPort permissionPort,
    required WorkflowPayloadValidatorPort payloadValidator,
    required String auditId,
    required DateTime occurredAt,
    int? expectedRevision,
  }) {
    if (request.status != WorkflowStatus.informationRequested) {
      return Future.value(
        const WorkflowFailure(
          WorkflowFailureCodes.invalidTransition,
          'Only information-requested workflow requests can be resubmitted.',
        ),
      );
    }

    final payloadResult = payloadValidator
        .validateResubmitted(payload)
        .toWorkflowResult();
    if (payloadResult is WorkflowFailure<void>) {
      return Future.value(
        WorkflowFailure(payloadResult.code, payloadResult.message),
      );
    }

    return _lifecycleService.planTransition(
      request: request,
      action: WorkflowAction.resubmit,
      actor: actor,
      permissionPort: permissionPort,
      auditId: auditId,
      occurredAt: occurredAt,
      expectedRevision: expectedRevision,
      payloadUpdate: payload,
    );
  }
}
