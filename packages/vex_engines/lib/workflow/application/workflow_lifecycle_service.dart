import 'package:vex_core/events/vex_event.dart';

import '../domain/workflow_action.dart';
import '../domain/workflow_actor.dart';
import '../domain/workflow_payload.dart';
import '../domain/workflow_request.dart';
import '../domain/workflow_result.dart';
import '../domain/workflow_status.dart';
import '../domain/workflow_transition_plan.dart';
import 'ports/workflow_permission_port.dart';
import 'workflow_audit_composer.dart';
import 'workflow_event_factory.dart';
import 'workflow_review_input_validator.dart';

/// Core workflow orchestration — validates transitions and builds plans.
final class WorkflowLifecycleService {
  const WorkflowLifecycleService({
    WorkflowAuditComposer auditComposer = const WorkflowAuditComposer(),
    WorkflowEventFactory eventFactory = const WorkflowEventFactory(),
    WorkflowReviewInputValidator reviewInputValidator =
        const WorkflowReviewInputValidator(),
  }) : _auditComposer = auditComposer,
       _eventFactory = eventFactory,
       _reviewInputValidator = reviewInputValidator;

  final WorkflowAuditComposer _auditComposer;
  final WorkflowEventFactory _eventFactory;
  final WorkflowReviewInputValidator _reviewInputValidator;

  Future<WorkflowResult<WorkflowTransitionPlan>> planTransition({
    required WorkflowRequest request,
    required WorkflowAction action,
    required WorkflowActor actor,
    required WorkflowPermissionPort permissionPort,
    required String auditId,
    required DateTime occurredAt,
    int? expectedRevision,
    String? notes,
    String? reason,
    String? decisionCode,
    String? assignedReviewerUid,
    WorkflowPayload? payloadUpdate,
  }) async {
    final actorResult = _validateActor(actor);
    if (actorResult is WorkflowFailure<WorkflowActor>) {
      return WorkflowFailure(actorResult.code, actorResult.message);
    }

    if (expectedRevision != null && expectedRevision != request.revision) {
      return const WorkflowFailure(
        WorkflowFailureCodes.revisionConflict,
        'Workflow request revision conflict.',
      );
    }

    if (WorkflowStatusTransitions.isTerminal(request.status) &&
        action != WorkflowAction.assignReviewer) {
      return const WorkflowFailure(
        WorkflowFailureCodes.terminalRequest,
        'Workflow request is already terminal.',
      );
    }

    final inputResult = _reviewInputValidator.validate(
      action: action,
      notes: notes,
      reason: reason,
      decisionCode: decisionCode,
    );
    if (inputResult is WorkflowFailure<void>) {
      return WorkflowFailure(inputResult.code, inputResult.message);
    }

    final nextStatusResult = _resolveNextStatus(request.status, action);
    if (nextStatusResult is WorkflowFailure<WorkflowStatus>) {
      return WorkflowFailure(nextStatusResult.code, nextStatusResult.message);
    }
    if (nextStatusResult is WorkflowFailure<WorkflowStatus>) {
      return WorkflowFailure(nextStatusResult.code, nextStatusResult.message);
    }
    final nextStatus =
        (nextStatusResult as WorkflowSuccess<WorkflowStatus>).value;

    if (!_shouldSkipPermissionCheck(action: action, actor: actor)) {
      final capabilities = await permissionPort.resolve(
        actor: actor,
        request: request,
        action: action,
      );
      if (!capabilities.allows(action)) {
        return const WorkflowFailure(
          WorkflowFailureCodes.permissionDenied,
          'You do not have permission to perform this workflow action.',
        );
      }
    }

    final patch = _buildPatch(
      request: request,
      action: action,
      nextStatus: nextStatus,
      occurredAt: occurredAt,
      notes: notes,
      reason: reason,
      decisionCode: decisionCode,
      assignedReviewerUid: assignedReviewerUid,
      payloadUpdate: payloadUpdate,
    );

    final auditEntry = _auditComposer.compose(
      auditId: auditId,
      requestId: request.requestId,
      action: action,
      fromStatus: request.status,
      toStatus: nextStatus,
      actor: actor,
      createdAt: occurredAt,
      notes: notes,
      reason: reason ?? decisionCode,
      metadata: assignedReviewerUid == null
          ? const {}
          : {'assignedReviewerUid': assignedReviewerUid},
    );

    final proposedRequest = request.applyPatch(patch);
    final events = List<VexEvent>.from(
      _eventFactory.eventsFor(
        action: action,
        proposedRequest: proposedRequest,
        occurredAt: occurredAt,
      ),
    );

    return WorkflowSuccess(
      WorkflowTransitionPlan(
        currentStatus: request.status,
        nextStatus: nextStatus,
        action: action,
        requestPatch: patch,
        auditEntry: auditEntry,
        events: events,
        proposedRequest: proposedRequest,
      ),
    );
  }

  WorkflowResult<WorkflowStatus> _resolveNextStatus(
    WorkflowStatus current,
    WorkflowAction action,
  ) {
    if (action == WorkflowAction.updateDraft ||
        action == WorkflowAction.assignReviewer) {
      return WorkflowSuccess(current);
    }

    return WorkflowStatusTransitions.resolveNextStatus(
      current: current,
      action: action,
    );
  }

  WorkflowRequestPatch _buildPatch({
    required WorkflowRequest request,
    required WorkflowAction action,
    required WorkflowStatus nextStatus,
    required DateTime occurredAt,
    String? notes,
    String? reason,
    String? decisionCode,
    String? assignedReviewerUid,
    WorkflowPayload? payloadUpdate,
  }) {
    final isTerminal = WorkflowStatusTransitions.isTerminal(nextStatus);
    final trimmedNotes = notes?.trim();
    final trimmedReason = reason?.trim();
    final trimmedCode = decisionCode?.trim();

    return WorkflowRequestPatch(
      status: nextStatus,
      payload: payloadUpdate,
      assignedReviewerUid: action == WorkflowAction.assignReviewer
          ? assignedReviewerUid
          : null,
      reviewNotesSummary: trimmedNotes != null && trimmedNotes.isNotEmpty
          ? trimmedNotes
          : null,
      decisionReason: trimmedReason != null && trimmedReason.isNotEmpty
          ? trimmedReason
          : null,
      decisionCode: trimmedCode != null && trimmedCode.isNotEmpty
          ? trimmedCode
          : null,
      submittedAt:
          action == WorkflowAction.submit || action == WorkflowAction.resubmit
          ? occurredAt
          : null,
      decidedAt: isTerminal ? occurredAt : null,
      updatedAt: occurredAt,
      revision: request.revision + 1,
    );
  }

  WorkflowResult<WorkflowActor> _validateActor(WorkflowActor actor) {
    if (actor.uid.trim().isEmpty) {
      return const WorkflowFailure(
        WorkflowFailureCodes.invalidActor,
        'Workflow actor uid is required.',
      );
    }
    return WorkflowSuccess(actor);
  }

  bool _shouldSkipPermissionCheck({
    required WorkflowAction action,
    required WorkflowActor actor,
  }) {
    return action == WorkflowAction.expire &&
        actor.kind == WorkflowActorKind.system;
  }
}
