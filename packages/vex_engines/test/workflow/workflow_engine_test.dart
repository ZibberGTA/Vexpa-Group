import 'package:test/test.dart';
import 'package:vex_engines/workflow/application/application.dart';
import 'package:vex_engines/workflow/domain/domain.dart';
import 'package:vex_engines/workflow/shared/shared.dart';

final class _TestPermissionPort implements WorkflowPermissionPort {
  _TestPermissionPort({
    WorkflowCapabilities capabilities = const WorkflowCapabilities(
      canSubmit: true,
      canReview: true,
      canApprove: true,
      canReject: true,
      canWithdraw: true,
      canCancel: true,
      canAssignReviewer: true,
    ),
  }) : _capabilities = capabilities;

  final WorkflowCapabilities _capabilities;

  @override
  Future<WorkflowCapabilities> resolve({
    required WorkflowActor actor,
    required WorkflowRequest request,
    required WorkflowAction action,
  }) async {
    return _capabilities;
  }
}

final class _DenyAllPermissionPort implements WorkflowPermissionPort {
  @override
  Future<WorkflowCapabilities> resolve({
    required WorkflowActor actor,
    required WorkflowRequest request,
    required WorkflowAction action,
  }) async {
    return const WorkflowCapabilities();
  }
}

final class _TestPayloadValidator implements WorkflowPayloadValidatorPort {
  _TestPayloadValidator({this.fail = false});

  final bool fail;

  @override
  WorkflowPayloadValidationResult validateDraft(WorkflowPayload payload) =>
      _result();

  @override
  WorkflowPayloadValidationResult validateSubmitted(WorkflowPayload payload) =>
      _result();

  @override
  WorkflowPayloadValidationResult validateResubmitted(
    WorkflowPayload payload,
  ) => _result();

  WorkflowPayloadValidationResult _result() {
    if (fail) {
      return const WorkflowPayloadValidationFailure([
        WorkflowPayloadValidationIssue(
          code: 'invalid-field',
          message: 'Payload invalid.',
        ),
      ]);
    }
    return const WorkflowPayloadValidationSuccess();
  }
}

WorkflowRequest _request({
  WorkflowStatus status = WorkflowStatus.draft,
  int revision = 1,
}) {
  return WorkflowRequest(
    requestId: 'req-1',
    workflowType: const WorkflowTypeId(WorkflowTypeIds.trailVenueParticipation),
    status: status,
    submittedByUid: 'user-1',
    subjectRefs: const WorkflowSubjectRefs({
      'trailId': 'trail-1',
      'venueId': 'venue-1',
    }),
    payload: const WorkflowPayload(
      values: {'message': 'join'},
      schemaVersion: 1,
    ),
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
    revision: revision,
  );
}

WorkflowActor _submitter() =>
    const WorkflowActor(uid: 'user-1', kind: WorkflowActorKind.submitter);

WorkflowActor _reviewer() =>
    const WorkflowActor(uid: 'staff-1', kind: WorkflowActorKind.reviewer);

WorkflowActor _admin() =>
    const WorkflowActor(uid: 'admin-1', kind: WorkflowActorKind.admin);

WorkflowActor _system() =>
    const WorkflowActor(uid: 'system', kind: WorkflowActorKind.system);

void main() {
  final lifecycle = WorkflowLifecycleService();
  final submission = WorkflowSubmissionService();
  final review = WorkflowReviewService();
  final withdrawal = WorkflowWithdrawalService();
  final cancellation = WorkflowCancellationService();
  final expiration = WorkflowExpirationService();
  final assignment = WorkflowAssignmentService();
  final permissionPort = _TestPermissionPort();
  final validator = _TestPayloadValidator();

  group('WorkflowStatusTransitions', () {
    test('parses known persistence values', () {
      final result = WorkflowStatusTransitions.parsePersistenceValue(
        'under_review',
      );
      expect(result, isA<WorkflowSuccess<WorkflowStatus>>());
      expect((result as WorkflowSuccess).value, WorkflowStatus.underReview);
    });

    test('rejects unknown persistence values', () {
      final result = WorkflowStatusTransitions.parsePersistenceValue('unknown');
      expect(result, isA<WorkflowFailure<WorkflowStatus>>());
      expect(
        (result as WorkflowFailure).code,
        WorkflowFailureCodes.invalidStatus,
      );
    });

    test('identifies open and terminal statuses', () {
      expect(
        WorkflowStatusTransitions.isOpen(WorkflowStatus.submitted),
        isTrue,
      );
      expect(
        WorkflowStatusTransitions.isTerminal(WorkflowStatus.approved),
        isTrue,
      );
    });

    final allowed = <(WorkflowStatus, WorkflowAction, WorkflowStatus)>{
      (WorkflowStatus.draft, WorkflowAction.submit, WorkflowStatus.submitted),
      (WorkflowStatus.draft, WorkflowAction.withdraw, WorkflowStatus.withdrawn),
      (WorkflowStatus.draft, WorkflowAction.cancel, WorkflowStatus.cancelled),
      (
        WorkflowStatus.submitted,
        WorkflowAction.startReview,
        WorkflowStatus.underReview,
      ),
      (
        WorkflowStatus.submitted,
        WorkflowAction.requestInformation,
        WorkflowStatus.informationRequested,
      ),
      (
        WorkflowStatus.submitted,
        WorkflowAction.approve,
        WorkflowStatus.approved,
      ),
      (
        WorkflowStatus.submitted,
        WorkflowAction.reject,
        WorkflowStatus.rejected,
      ),
      (
        WorkflowStatus.submitted,
        WorkflowAction.withdraw,
        WorkflowStatus.withdrawn,
      ),
      (
        WorkflowStatus.submitted,
        WorkflowAction.cancel,
        WorkflowStatus.cancelled,
      ),
      (WorkflowStatus.submitted, WorkflowAction.expire, WorkflowStatus.expired),
      (
        WorkflowStatus.underReview,
        WorkflowAction.requestInformation,
        WorkflowStatus.informationRequested,
      ),
      (
        WorkflowStatus.underReview,
        WorkflowAction.approve,
        WorkflowStatus.approved,
      ),
      (
        WorkflowStatus.underReview,
        WorkflowAction.reject,
        WorkflowStatus.rejected,
      ),
      (
        WorkflowStatus.underReview,
        WorkflowAction.withdraw,
        WorkflowStatus.withdrawn,
      ),
      (
        WorkflowStatus.underReview,
        WorkflowAction.cancel,
        WorkflowStatus.cancelled,
      ),
      (
        WorkflowStatus.underReview,
        WorkflowAction.expire,
        WorkflowStatus.expired,
      ),
      (
        WorkflowStatus.informationRequested,
        WorkflowAction.resubmit,
        WorkflowStatus.submitted,
      ),
      (
        WorkflowStatus.informationRequested,
        WorkflowAction.reject,
        WorkflowStatus.rejected,
      ),
      (
        WorkflowStatus.informationRequested,
        WorkflowAction.withdraw,
        WorkflowStatus.withdrawn,
      ),
      (
        WorkflowStatus.informationRequested,
        WorkflowAction.cancel,
        WorkflowStatus.cancelled,
      ),
      (
        WorkflowStatus.informationRequested,
        WorkflowAction.expire,
        WorkflowStatus.expired,
      ),
    };

    for (final (current, action, expected) in allowed) {
      test('allows $action from $current', () {
        final result = WorkflowStatusTransitions.resolveNextStatus(
          current: current,
          action: action,
        );
        expect(result, isA<WorkflowSuccess<WorkflowStatus>>());
        expect((result as WorkflowSuccess).value, expected);
      });
    }

    test('blocks transitions from terminal statuses', () {
      for (final status in WorkflowStatusTransitions.terminalStatuses) {
        final result = WorkflowStatusTransitions.resolveNextStatus(
          current: status,
          action: WorkflowAction.approve,
        );
        expect(result, isA<WorkflowFailure<WorkflowStatus>>());
        expect(
          (result as WorkflowFailure).code,
          WorkflowFailureCodes.terminalRequest,
        );
      }
    });

    test('blocks illegal transition submitted -> resubmit', () {
      final result = WorkflowStatusTransitions.resolveNextStatus(
        current: WorkflowStatus.submitted,
        action: WorkflowAction.resubmit,
      );
      expect(
        (result as WorkflowFailure).code,
        WorkflowFailureCodes.invalidTransition,
      );
    });
  });

  group('WorkflowTypeId', () {
    test('rejects empty workflow type id', () {
      final result = WorkflowTypeId.parse('  ');
      expect(
        (result as WorkflowFailure).code,
        WorkflowFailureCodes.invalidWorkflowType,
      );
    });
  });

  group('WorkflowSubjectRefs and WorkflowPayload', () {
    test('subject refs lookup returns trimmed values', () {
      const refs = WorkflowSubjectRefs({'venueId': ' venue-1 '});
      expect(refs.ref('venueId'), 'venue-1');
      expect(refs.ref('missing'), isNull);
    });

    test('payload copyWith preserves schema version', () {
      const payload = WorkflowPayload(values: {'a': 1}, schemaVersion: 2);
      expect(payload.copyWith(values: {'b': 2}).schemaVersion, 2);
    });
  });

  group('WorkflowLifecycleService', () {
    test('denies action when permission port rejects', () async {
      final result = await lifecycle.planTransition(
        request: _request(status: WorkflowStatus.submitted),
        action: WorkflowAction.approve,
        actor: _reviewer(),
        permissionPort: _DenyAllPermissionPort(),
        auditId: 'audit-1',
        occurredAt: DateTime.utc(2026, 1, 2),
      );

      expect(
        (result as WorkflowFailure).code,
        WorkflowFailureCodes.permissionDenied,
      );
    });

    test('requires notes for requestInformation', () async {
      final result = await lifecycle.planTransition(
        request: _request(status: WorkflowStatus.submitted),
        action: WorkflowAction.requestInformation,
        actor: _reviewer(),
        permissionPort: permissionPort,
        auditId: 'audit-1',
        occurredAt: DateTime.utc(2026, 1, 2),
      );

      expect(
        (result as WorkflowFailure).code,
        WorkflowFailureCodes.notesRequired,
      );
    });

    test('requires decision reason for reject', () async {
      final result = await lifecycle.planTransition(
        request: _request(status: WorkflowStatus.submitted),
        action: WorkflowAction.reject,
        actor: _reviewer(),
        permissionPort: permissionPort,
        auditId: 'audit-1',
        occurredAt: DateTime.utc(2026, 1, 2),
      );

      expect(
        (result as WorkflowFailure).code,
        WorkflowFailureCodes.decisionReasonRequired,
      );
    });

    test('requires decision reason for cancel', () async {
      final result = await lifecycle.planTransition(
        request: _request(status: WorkflowStatus.submitted),
        action: WorkflowAction.cancel,
        actor: _admin(),
        permissionPort: permissionPort,
        auditId: 'audit-1',
        occurredAt: DateTime.utc(2026, 1, 2),
      );

      expect(
        (result as WorkflowFailure).code,
        WorkflowFailureCodes.decisionReasonRequired,
      );
    });

    test('approve emits WorkflowApprovedEvent', () async {
      final result = await lifecycle.planTransition(
        request: _request(status: WorkflowStatus.submitted),
        action: WorkflowAction.approve,
        actor: _reviewer(),
        permissionPort: permissionPort,
        auditId: 'audit-1',
        occurredAt: DateTime.utc(2026, 1, 2),
        notes: 'Looks good',
      );

      final plan = (result as WorkflowSuccess<WorkflowTransitionPlan>).value;
      expect(plan.nextStatus, WorkflowStatus.approved);
      expect(plan.events, hasLength(1));
      expect(plan.events.first.type, 'workflow.approved');
      expect(plan.auditEntry.action, WorkflowAuditAction.approved);
    });

    test('detects revision conflict', () async {
      final result = await lifecycle.planTransition(
        request: _request(status: WorkflowStatus.submitted, revision: 2),
        action: WorkflowAction.approve,
        actor: _reviewer(),
        permissionPort: permissionPort,
        auditId: 'audit-1',
        occurredAt: DateTime.utc(2026, 1, 2),
        expectedRevision: 1,
        notes: 'ok',
      );

      expect(
        (result as WorkflowFailure).code,
        WorkflowFailureCodes.revisionConflict,
      );
    });
  });

  group('WorkflowSubmissionService', () {
    test('creates draft plan with draftCreated audit', () async {
      final result = await submission.planCreateDraft(
        requestId: 'req-1',
        workflowType: const WorkflowTypeId(
          WorkflowTypeIds.trailVenueParticipation,
        ),
        submittedByUid: 'user-1',
        subjectRefs: const WorkflowSubjectRefs({'venueId': 'venue-1'}),
        payload: const WorkflowPayload(values: {}, schemaVersion: 1),
        actor: _submitter(),
        permissionPort: permissionPort,
        payloadValidator: validator,
        auditId: 'audit-1',
        occurredAt: DateTime.utc(2026, 1, 1),
      );

      final plan = (result as WorkflowSuccess<WorkflowTransitionPlan>).value;
      expect(plan.proposedRequest?.status, WorkflowStatus.draft);
      expect(plan.auditEntry.action, WorkflowAuditAction.draftCreated);
    });

    test('rejects invalid payload on submit', () async {
      final result = await submission.planSubmit(
        request: _request(),
        actor: _submitter(),
        permissionPort: permissionPort,
        payloadValidator: _TestPayloadValidator(fail: true),
        auditId: 'audit-1',
        occurredAt: DateTime.utc(2026, 1, 2),
      );

      expect(
        (result as WorkflowFailure).code,
        WorkflowFailureCodes.invalidPayload,
      );
    });

    test('resubmit returns to submitted with resubmitted audit', () async {
      final result = await submission.planResubmit(
        request: _request(status: WorkflowStatus.informationRequested),
        payload: const WorkflowPayload(
          values: {'message': 'updated'},
          schemaVersion: 1,
        ),
        actor: _submitter(),
        permissionPort: permissionPort,
        payloadValidator: validator,
        auditId: 'audit-2',
        occurredAt: DateTime.utc(2026, 1, 3),
      );

      final plan = (result as WorkflowSuccess<WorkflowTransitionPlan>).value;
      expect(plan.nextStatus, WorkflowStatus.submitted);
      expect(plan.auditEntry.action, WorkflowAuditAction.resubmitted);
      expect(plan.events.first.type, 'workflow.submitted');
    });
  });

  group('WorkflowReviewService', () {
    test('startReview moves submitted to underReview', () async {
      final result = await review.planStartReview(
        request: _request(status: WorkflowStatus.submitted),
        actor: _reviewer(),
        permissionPort: permissionPort,
        auditId: 'audit-1',
        occurredAt: DateTime.utc(2026, 1, 2),
      );

      final plan = (result as WorkflowSuccess<WorkflowTransitionPlan>).value;
      expect(plan.nextStatus, WorkflowStatus.underReview);
      expect(plan.events.first.type, 'workflow.review_started');
    });
  });

  group('WorkflowWithdrawalService', () {
    test('withdraw from submitted succeeds', () async {
      final result = await withdrawal.planWithdraw(
        request: _request(status: WorkflowStatus.submitted),
        actor: _submitter(),
        permissionPort: permissionPort,
        auditId: 'audit-1',
        occurredAt: DateTime.utc(2026, 1, 2),
      );

      final plan = (result as WorkflowSuccess<WorkflowTransitionPlan>).value;
      expect(plan.nextStatus, WorkflowStatus.withdrawn);
    });
  });

  group('WorkflowAssignmentService', () {
    test('assignReviewer does not change status', () async {
      final result = await assignment.planAssignReviewer(
        request: _request(status: WorkflowStatus.submitted),
        actor: _admin(),
        permissionPort: permissionPort,
        assignedReviewerUid: 'staff-2',
        auditId: 'audit-1',
        occurredAt: DateTime.utc(2026, 1, 2),
      );

      final plan = (result as WorkflowSuccess<WorkflowTransitionPlan>).value;
      expect(plan.currentStatus, WorkflowStatus.submitted);
      expect(plan.nextStatus, WorkflowStatus.submitted);
      expect(plan.proposedRequest?.assignedReviewerUid, 'staff-2');
      expect(plan.auditEntry.action, WorkflowAuditAction.reviewerAssigned);
    });
  });

  group('WorkflowExpirationService', () {
    test('expire requires system actor', () async {
      final result = await expiration.planExpire(
        request: _request(status: WorkflowStatus.submitted),
        systemActor: _reviewer(),
        permissionPort: permissionPort,
        auditId: 'audit-1',
        occurredAt: DateTime.utc(2026, 1, 2),
      );

      expect(
        (result as WorkflowFailure).code,
        WorkflowFailureCodes.invalidActor,
      );
    });

    test('expire from submitted succeeds for system actor', () async {
      final result = await expiration.planExpire(
        request: _request(status: WorkflowStatus.submitted),
        systemActor: _system(),
        permissionPort: permissionPort,
        auditId: 'audit-1',
        occurredAt: DateTime.utc(2026, 1, 2),
        reason: 'timeout',
      );

      final plan = (result as WorkflowSuccess<WorkflowTransitionPlan>).value;
      expect(plan.nextStatus, WorkflowStatus.expired);
      expect(plan.events.first.type, 'workflow.expired');
    });
  });

  group('WorkflowCancellationService', () {
    test('cancel requires decision reason', () async {
      final result = await cancellation.planCancel(
        request: _request(status: WorkflowStatus.submitted),
        actor: _admin(),
        permissionPort: permissionPort,
        auditId: 'audit-1',
        occurredAt: DateTime.utc(2026, 1, 2),
      );

      expect(
        (result as WorkflowFailure).code,
        WorkflowFailureCodes.decisionReasonRequired,
      );
    });
  });

  group('permission capabilities', () {
    test('maps actions to capabilities', () {
      const capabilities = WorkflowCapabilities(
        canSubmit: true,
        canReview: true,
        canApprove: true,
        canReject: true,
        canWithdraw: true,
        canCancel: true,
        canAssignReviewer: true,
      );

      expect(capabilities.allows(WorkflowAction.submit), isTrue);
      expect(capabilities.allows(WorkflowAction.approve), isTrue);
      expect(capabilities.allows(WorkflowAction.assignReviewer), isTrue);
      expect(
        const WorkflowCapabilities().allows(WorkflowAction.submit),
        isFalse,
      );
    });
  });
}
