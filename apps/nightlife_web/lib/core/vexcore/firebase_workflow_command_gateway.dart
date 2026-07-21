import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vex_core/data/data_result.dart';
import 'package:vex_core/shared/vex_exception.dart';
import 'package:vex_core/workflow/workflow.dart';
import 'package:vex_engines/trail/application/participation/trail_participation_permission_port.dart';
import 'package:vex_engines/workflow/application/workflow_assignment_service.dart';
import 'package:vex_engines/workflow/application/workflow_cancellation_service.dart';
import 'package:vex_engines/workflow/application/workflow_expiration_service.dart';
import 'package:vex_engines/workflow/application/workflow_review_service.dart';
import 'package:vex_engines/workflow/domain/workflow_actor.dart';
import 'package:vex_engines/workflow/domain/workflow_audit_entry.dart';
import 'package:vex_engines/workflow/domain/workflow_request.dart';
import 'package:vex_engines/workflow/domain/workflow_result.dart';
import 'package:vex_engines/workflow/domain/workflow_transition_plan.dart';
import 'package:vex_engines/workflow/shared/workflow_snapshot_mapper.dart';

import 'firebase_workflow_document_mapper.dart';
import 'firebase_workflow_request_repository.dart';

/// Executes privileged workflow commands for authorised admin/reviewer actors.
final class FirebaseWorkflowCommandGateway implements WorkflowCommandGateway {
  FirebaseWorkflowCommandGateway({
    FirebaseFirestore? firestore,
    FirebaseWorkflowRequestRepository? requestRepository,
    WorkflowReviewService? reviewService,
    WorkflowAssignmentService? assignmentService,
    WorkflowCancellationService? cancellationService,
    WorkflowExpirationService? expirationService,
  }) : _firestoreOverride = firestore,
       _requestRepository =
           requestRepository ?? FirebaseWorkflowRequestRepository(),
       _reviewService = reviewService ?? const WorkflowReviewService(),
       _assignmentService =
           assignmentService ?? const WorkflowAssignmentService(),
       _cancellationService =
           cancellationService ?? const WorkflowCancellationService(),
       _expirationService =
           expirationService ?? const WorkflowExpirationService();

  final FirebaseFirestore? _firestoreOverride;
  final FirebaseWorkflowRequestRepository _requestRepository;
  final WorkflowReviewService _reviewService;
  final WorkflowAssignmentService _assignmentService;
  final WorkflowCancellationService _cancellationService;
  final WorkflowExpirationService _expirationService;
  FirebaseFirestore? _firestore;

  FirebaseFirestore get _db =>
      _firestoreOverride ?? (_firestore ??= FirebaseFirestore.instance);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection(WorkflowPaths.workflowRequestsCollection);

  @override
  Future<DataResult<WorkflowRequestSnapshot>> invoke(
    WorkflowPrivilegedCommand command,
  ) async {
    final actor = _parseActor(command.actor);
    if (actor == null) {
      return DataFailure(
        VexException(
          'Privileged workflow commands require an admin or reviewer actor.',
          code: 'workflow-privileged-unavailable',
        ),
      );
    }

    try {
      final currentResult = await _requestRepository.get(command.requestId);
      if (currentResult case DataFailure(error: final error)) {
        return DataFailure(error);
      }
      final current = WorkflowSnapshotMapper.toDomain(
        (currentResult as DataSuccess).value,
      );
      final permissionPort = _reviewerPermissionPort(actor.uid);
      final occurredAt = DateTime.now().toUtc();
      final auditId = _auditId(
        command.requestId,
        current.revision + 1,
        command.runtimeType.toString(),
      );

      final WorkflowResult<WorkflowTransitionPlan> planResult =
          switch (command) {
        StartWorkflowReviewCommand(:final notes) =>
          await _reviewService.planStartReview(
            request: current,
            actor: actor,
            permissionPort: permissionPort,
            auditId: auditId,
            occurredAt: occurredAt,
            expectedRevision: command.expectedRevision,
            notes: notes,
          ),
        RequestWorkflowInformationCommand(:final notes) =>
          await _reviewService.planRequestInformation(
            request: current,
            actor: actor,
            permissionPort: permissionPort,
            auditId: auditId,
            occurredAt: occurredAt,
            expectedRevision: command.expectedRevision,
            notes: notes,
          ),
        ApproveWorkflowCommand(
          :final notes,
          :final reason,
          :final decisionCode,
        ) =>
          await _reviewService.planApprove(
            request: current,
            actor: actor,
            permissionPort: permissionPort,
            auditId: auditId,
            occurredAt: occurredAt,
            expectedRevision: command.expectedRevision,
            notes: notes,
            reason: reason,
            decisionCode: decisionCode,
          ),
        RejectWorkflowCommand(:final notes, :final reason, :final decisionCode) =>
          await _reviewService.planReject(
            request: current,
            actor: actor,
            permissionPort: permissionPort,
            auditId: auditId,
            occurredAt: occurredAt,
            expectedRevision: command.expectedRevision,
            notes: notes,
            reason: reason,
            decisionCode: decisionCode,
          ),
        CancelWorkflowCommand(:final notes, :final reason, :final decisionCode) =>
          await _cancellationService.planCancel(
            request: current,
            actor: actor,
            permissionPort: permissionPort,
            auditId: auditId,
            occurredAt: occurredAt,
            expectedRevision: command.expectedRevision,
            notes: notes,
            reason: reason,
            decisionCode: decisionCode,
          ),
        AssignWorkflowReviewerCommand(
          :final assignedReviewerUid,
          :final notes,
        ) =>
          await _assignmentService.planAssignReviewer(
            request: current,
            actor: actor,
            permissionPort: permissionPort,
            auditId: auditId,
            occurredAt: occurredAt,
            expectedRevision: command.expectedRevision,
            assignedReviewerUid: assignedReviewerUid,
            notes: notes,
          ),
        ExpireWorkflowCommand(:final reason) =>
          await _expirationService.planExpire(
            request: current,
            systemActor: WorkflowActor(
              uid: actor.uid,
              kind: WorkflowActorKind.system,
            ),
            permissionPort: permissionPort,
            auditId: auditId,
            occurredAt: occurredAt,
            expectedRevision: command.expectedRevision,
            reason: reason,
          ),
      };

      if (planResult case WorkflowFailure(:final code, :final message)) {
        return DataFailure(
          VexException(message, code: _mapFailureCode(code)),
        );
      }

      final plan =
          (planResult as WorkflowSuccess<WorkflowTransitionPlan>).value;
      final request = current.applyPatch(plan.requestPatch);
      await _persistTransition(
        request: request,
        auditEntry: plan.auditEntry,
      );
      return _requestRepository.get(command.requestId);
    } on Object catch (error, _) {
      return DataFailure(
        VexException(
          'Privileged workflow command failed: $error',
          code: 'workflow-privileged-failed',
          cause: error,
        ),
      );
    }
  }

  Future<void> _persistTransition({
    required WorkflowRequest request,
    required WorkflowAuditEntry auditEntry,
  }) async {
    final batch = _db.batch();
    final requestRef = _collection.doc(request.requestId);
    batch.set(
      requestRef,
      FirebaseWorkflowDocumentMapper.requestWriteData(
        request: request,
        isCreate: false,
      ),
      SetOptions(merge: true),
    );
    batch.set(
      requestRef.collection('audit').doc(auditEntry.auditId),
      FirebaseWorkflowDocumentMapper.auditWriteData(auditEntry),
    );
    await batch.commit();
  }

  TrailParticipationPermissionPort _reviewerPermissionPort(String actorUid) {
    return TrailParticipationPermissionPort(
      facts: TrailParticipationPermissionFacts(
        actorUid: actorUid,
        managesVenue: false,
        ownsRequest: false,
        isAuthorisedReviewer: true,
      ),
    );
  }

  WorkflowActor? _parseActor(WorkflowActorContext actor) {
    final kind = switch (actor.kind) {
      'reviewer' => WorkflowActorKind.reviewer,
      'admin' => WorkflowActorKind.admin,
      _ => null,
    };
    if (kind == null) return null;
    return WorkflowActor(uid: actor.uid, kind: kind);
  }

  String _auditId(String requestId, int revision, String action) {
    final slug = action.replaceAll(RegExp(r'[^a-zA-Z]'), '').toLowerCase();
    return '$requestId-$revision-$slug';
  }

  String _mapFailureCode(String code) {
    if (code == WorkflowFailureCodes.revisionConflict) {
      return 'workflow-revision-conflict';
    }
    if (code == WorkflowFailureCodes.permissionDenied) {
      return 'workflow-permission-denied';
    }
    return 'workflow-plan-failed';
  }
}
