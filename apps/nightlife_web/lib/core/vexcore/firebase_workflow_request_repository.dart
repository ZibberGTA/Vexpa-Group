import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vex_core/data/data_result.dart';
import 'package:vex_core/shared/vex_exception.dart';
import 'package:vex_core/workflow/workflow.dart';
import 'package:vex_engines/trail/application/participation/trail_participation_payload_validator.dart';
import 'package:vex_engines/trail/application/participation/trail_participation_permission_port.dart';
import 'package:vex_engines/workflow/application/workflow_submission_service.dart';
import 'package:vex_engines/workflow/application/workflow_withdrawal_service.dart';
import 'package:vex_engines/workflow/domain/workflow_actor.dart';
import 'package:vex_engines/workflow/domain/workflow_audit_entry.dart';
import 'package:vex_engines/workflow/domain/workflow_payload.dart';
import 'package:vex_engines/workflow/domain/workflow_request.dart';
import 'package:vex_engines/workflow/domain/workflow_result.dart';
import 'package:vex_engines/workflow/domain/workflow_subject_refs.dart';
import 'package:vex_engines/workflow/domain/workflow_transition_plan.dart';
import 'package:vex_engines/workflow/domain/workflow_type_id.dart';
import 'package:vex_engines/workflow/shared/workflow_snapshot_mapper.dart';

import 'firebase_workflow_document_mapper.dart';

enum _WorkflowClientAction { updateDraft, submit, resubmit, withdraw }

/// Firebase adapter for VexCore [WorkflowRequestRepository].
final class FirebaseWorkflowRequestRepository
    implements WorkflowRequestRepository {
  FirebaseWorkflowRequestRepository({
    FirebaseFirestore? firestore,
    WorkflowSubmissionService? submissionService,
    WorkflowWithdrawalService? withdrawalService,
  }) : _firestoreOverride = firestore,
       _submissionService =
           submissionService ?? const WorkflowSubmissionService(),
       _withdrawalService =
           withdrawalService ?? const WorkflowWithdrawalService();

  final FirebaseFirestore? _firestoreOverride;
  final WorkflowSubmissionService _submissionService;
  final WorkflowWithdrawalService _withdrawalService;
  FirebaseFirestore? _firestore;

  FirebaseFirestore get _db =>
      _firestoreOverride ?? (_firestore ??= FirebaseFirestore.instance);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection(WorkflowPaths.workflowRequestsCollection);

  @override
  Future<DataResult<WorkflowRequestSnapshot>> get(String requestId) async {
    try {
      final doc = await _collection.doc(requestId.trim()).get();
      if (!doc.exists) {
        return DataFailure(
          VexException(
            'Workflow request not found.',
            code: 'workflow-not-found',
          ),
        );
      }
      final snapshot = FirebaseWorkflowDocumentMapper.parseRequestDocument(
        doc.id,
        doc.data(),
      );
      if (snapshot == null) {
        return DataFailure(
          VexException('Workflow mapping failed.', code: 'workflow-map-failed'),
        );
      }
      return DataSuccess(snapshot);
    } on Object catch (error, stackTrace) {
      return _failure('get', error, stackTrace);
    }
  }

  @override
  Stream<DataResult<WorkflowRequestSnapshot>> watch(String requestId) {
    return _collection
        .doc(requestId.trim())
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            return DataFailure<WorkflowRequestSnapshot>(
              VexException(
                'Workflow request not found.',
                code: 'workflow-not-found',
              ),
            );
          }
          final snapshot = FirebaseWorkflowDocumentMapper.parseRequestDocument(
            doc.id,
            doc.data(),
          );
          if (snapshot == null) {
            return DataFailure<WorkflowRequestSnapshot>(
              VexException(
                'Workflow mapping failed.',
                code: 'workflow-map-failed',
              ),
            );
          }
          return DataSuccess(snapshot);
        })
        .transform(
          StreamTransformer.fromHandlers(
            handleError: (error, stackTrace, sink) {
              sink.add(_failure('watch', error, stackTrace));
            },
          ),
        );
  }

  @override
  Future<DataResult<WorkflowRequestSnapshot>> createDraft(
    CreateWorkflowDraftCommand command,
  ) async {
    try {
      final occurredAt = DateTime.now().toUtc();
      final actor = _parseActor(command.actor);
      final subjectRefs = WorkflowSubjectRefs(command.subjectRefs.values);
      final payload = WorkflowPayload(
        values: Map<String, Object?>.from(command.payload.values),
        schemaVersion: command.payload.schemaVersion,
      );
      final permissionPort = _permissionPort(
        actorUid: command.submittedByUid,
        venueId: subjectRefs.ref('venueId') ?? '',
        ownsRequest: true,
      );
      final validator = TrailParticipationPayloadValidator(
        expectedTrailId: subjectRefs.ref('trailId'),
        expectedVenueId: subjectRefs.ref('venueId'),
      );

      final planResult = await _submissionService.planCreateDraft(
        requestId: command.requestId,
        workflowType: WorkflowTypeId(command.workflowType),
        submittedByUid: command.submittedByUid,
        subjectRefs: subjectRefs,
        payload: payload,
        actor: actor,
        permissionPort: permissionPort,
        payloadValidator: validator,
        auditId: _auditId(command.requestId, 1, 'create'),
        occurredAt: occurredAt,
      );

      if (planResult case WorkflowFailure(:final message)) {
        return DataFailure(VexException(message, code: 'workflow-plan-failed'));
      }

      final plan =
          (planResult as WorkflowSuccess<WorkflowTransitionPlan>).value;
      final request = plan.proposedRequest;
      if (request == null) {
        return DataFailure(
          VexException(
            'Draft plan missing request.',
            code: 'workflow-plan-failed',
          ),
        );
      }

      await _persistTransition(
        request: request,
        auditEntry: plan.auditEntry,
        isCreate: true,
      );
      return get(command.requestId);
    } on Object catch (error, stackTrace) {
      return _failure('createDraft', error, stackTrace);
    }
  }

  @override
  Future<DataResult<WorkflowRequestSnapshot>> updateDraft(
    UpdateWorkflowDraftCommand command,
  ) async {
    return _transition(
      requestId: command.requestId,
      expectedRevision: command.expectedRevision,
      actor: _parseActor(command.actor),
      action: _WorkflowClientAction.updateDraft,
      payload: WorkflowPayload(
        values: Map<String, Object?>.from(command.payload.values),
        schemaVersion: command.payload.schemaVersion,
      ),
    );
  }

  @override
  Future<DataResult<WorkflowRequestSnapshot>> submit(
    SubmitWorkflowCommand command,
  ) async {
    return _transition(
      requestId: command.requestId,
      expectedRevision: command.expectedRevision,
      actor: _parseActor(command.actor),
      action: _WorkflowClientAction.submit,
    );
  }

  @override
  Future<DataResult<WorkflowRequestSnapshot>> resubmit(
    ResubmitWorkflowCommand command,
  ) async {
    return _transition(
      requestId: command.requestId,
      expectedRevision: command.expectedRevision,
      actor: _parseActor(command.actor),
      action: _WorkflowClientAction.resubmit,
      payload: WorkflowPayload(
        values: Map<String, Object?>.from(command.payload.values),
        schemaVersion: command.payload.schemaVersion,
      ),
    );
  }

  @override
  Future<DataResult<WorkflowRequestSnapshot>> withdraw(
    WithdrawWorkflowCommand command,
  ) async {
    return _transition(
      requestId: command.requestId,
      expectedRevision: command.expectedRevision,
      actor: _parseActor(command.actor),
      action: _WorkflowClientAction.withdraw,
      notes: command.notes,
    );
  }

  @override
  Future<DataResult<List<WorkflowRequestSnapshot>>> list(
    WorkflowListQuery query,
  ) async {
    try {
      final snapshot = await _buildQuery(query).get();
      return DataSuccess(_mapDocs(snapshot.docs));
    } on Object catch (error, stackTrace) {
      return _failure('list', error, stackTrace);
    }
  }

  @override
  Stream<DataResult<List<WorkflowRequestSnapshot>>> watchList(
    WorkflowListQuery query,
  ) {
    return _buildQuery(query)
        .snapshots()
        .map((snapshot) {
          return DataSuccess(_mapDocs(snapshot.docs));
        })
        .transform(
          StreamTransformer.fromHandlers(
            handleError: (error, stackTrace, sink) {
              sink.add(_failure('watchList', error, stackTrace));
            },
          ),
        );
  }

  Future<DataResult<WorkflowRequestSnapshot>> _transition({
    required String requestId,
    required int expectedRevision,
    required WorkflowActor actor,
    required _WorkflowClientAction action,
    WorkflowPayload? payload,
    String? notes,
  }) async {
    try {
      final currentResult = await get(requestId);
      if (currentResult case DataFailure(error: final error)) {
        return DataFailure(error);
      }
      final current = WorkflowSnapshotMapper.toDomain(
        (currentResult as DataSuccess).value,
      );
      final venueId = current.subjectRefs.ref('venueId') ?? '';
      final permissionPort = _permissionPort(
        actorUid: actor.uid,
        venueId: venueId,
        ownsRequest: current.submittedByUid == actor.uid,
      );
      final validator = TrailParticipationPayloadValidator(
        expectedTrailId: current.subjectRefs.ref('trailId'),
        expectedVenueId: venueId,
      );
      final occurredAt = DateTime.now().toUtc();
      final auditId = _auditId(requestId, current.revision + 1, action.name);

      final WorkflowResult<WorkflowTransitionPlan>
      planResult = switch (action) {
        _WorkflowClientAction.updateDraft =>
          await _submissionService.planUpdateDraft(
            request: current,
            payload: payload!,
            actor: actor,
            permissionPort: permissionPort,
            payloadValidator: validator,
            auditId: auditId,
            occurredAt: occurredAt,
            expectedRevision: expectedRevision,
          ),
        _WorkflowClientAction.submit => await _submissionService.planSubmit(
          request: current,
          actor: actor,
          permissionPort: permissionPort,
          payloadValidator: validator,
          auditId: auditId,
          occurredAt: occurredAt,
          expectedRevision: expectedRevision,
        ),
        _WorkflowClientAction.resubmit => await _submissionService.planResubmit(
          request: current,
          payload: payload!,
          actor: actor,
          permissionPort: permissionPort,
          payloadValidator: validator,
          auditId: auditId,
          occurredAt: occurredAt,
          expectedRevision: expectedRevision,
        ),
        _WorkflowClientAction.withdraw => await _withdrawalService.planWithdraw(
          request: current,
          actor: actor,
          permissionPort: permissionPort,
          auditId: auditId,
          occurredAt: occurredAt,
          expectedRevision: expectedRevision,
          notes: notes,
        ),
      };

      if (planResult case WorkflowFailure(:final message)) {
        return DataFailure(VexException(message, code: 'workflow-plan-failed'));
      }

      final plan =
          (planResult as WorkflowSuccess<WorkflowTransitionPlan>).value;
      final request = current.applyPatch(plan.requestPatch);
      await _persistTransition(
        request: request,
        auditEntry: plan.auditEntry,
        isCreate: false,
      );
      return get(requestId);
    } on Object catch (error, stackTrace) {
      return _failure(action.name, error, stackTrace);
    }
  }

  Future<void> _persistTransition({
    required WorkflowRequest request,
    required WorkflowAuditEntry auditEntry,
    required bool isCreate,
  }) async {
    final batch = _db.batch();
    final requestRef = _collection.doc(request.requestId);
    batch.set(
      requestRef,
      FirebaseWorkflowDocumentMapper.requestWriteData(
        request: request,
        isCreate: isCreate,
      ),
      SetOptions(merge: !isCreate),
    );
    batch.set(
      requestRef.collection('audit').doc(auditEntry.auditId),
      FirebaseWorkflowDocumentMapper.auditWriteData(auditEntry),
    );
    await batch.commit();
  }

  Query<Map<String, dynamic>> _buildQuery(WorkflowListQuery query) {
    Query<Map<String, dynamic>> q = _collection;
    if (query.workflowType != null) {
      q = q.where('workflowType', isEqualTo: query.workflowType);
    }
    if (query.subjectVenueId != null) {
      q = q.where('subjectVenueId', isEqualTo: query.subjectVenueId);
    }
    if (query.subjectTrailId != null) {
      q = q.where('subjectTrailId', isEqualTo: query.subjectTrailId);
    }
    if (query.submittedByUid != null) {
      q = q.where('submittedByUid', isEqualTo: query.submittedByUid);
    }
    if (query.statuses.isNotEmpty) {
      q = q.where('status', whereIn: query.statuses.take(10).toList());
    }
    if (query.orderByUpdatedAtDesc) {
      q = q.orderBy('updatedAt', descending: true);
    }
    return q.limit(query.limit);
  }

  List<WorkflowRequestSnapshot> _mapDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final mapped = <WorkflowRequestSnapshot>[];
    for (final doc in docs) {
      final snapshot = FirebaseWorkflowDocumentMapper.parseRequestDocument(
        doc.id,
        doc.data(),
      );
      if (snapshot != null) mapped.add(snapshot);
    }
    return mapped;
  }

  TrailParticipationPermissionPort _permissionPort({
    required String actorUid,
    required String venueId,
    required bool ownsRequest,
  }) {
    return TrailParticipationPermissionPort(
      facts: TrailParticipationPermissionFacts(
        actorUid: actorUid,
        managesVenue: venueId.trim().isNotEmpty,
        ownsRequest: ownsRequest,
      ),
    );
  }

  WorkflowActor _parseActor(WorkflowActorContext actor) {
    final kind = switch (actor.kind) {
      'reviewer' => WorkflowActorKind.reviewer,
      'admin' => WorkflowActorKind.admin,
      'system' => WorkflowActorKind.system,
      _ => WorkflowActorKind.submitter,
    };
    return WorkflowActor(uid: actor.uid, kind: kind);
  }

  String _auditId(String requestId, int revision, String action) {
    return '$requestId-$revision-$action';
  }

  DataFailure<T> _failure<T>(
    String operation,
    Object error,
    StackTrace stackTrace,
  ) {
    return DataFailure(
      VexException(
        'Workflow $operation failed: $error',
        code: 'workflow-$operation-failed',
        cause: error,
      ),
    );
  }
}
