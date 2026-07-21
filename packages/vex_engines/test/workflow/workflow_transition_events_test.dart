import 'package:test/test.dart';
import 'package:vex_engines/workflow/application/application.dart';
import 'package:vex_engines/workflow/domain/domain.dart';

final class _CapabilityPort implements WorkflowPermissionPort {
  _CapabilityPort(this.capabilities);

  final WorkflowCapabilities capabilities;

  @override
  Future<WorkflowCapabilities> resolve({
    required WorkflowActor actor,
    required WorkflowRequest request,
    required WorkflowAction action,
  }) async {
    return capabilities;
  }
}

WorkflowRequest _openRequest(WorkflowStatus status) {
  return WorkflowRequest(
    requestId: 'req-1',
    workflowType: const WorkflowTypeId('test.workflow'),
    status: status,
    submittedByUid: 'user-1',
    subjectRefs: const WorkflowSubjectRefs({'subjectId': 'subject-1'}),
    payload: const WorkflowPayload(values: {}, schemaVersion: 1),
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
    revision: 1,
  );
}

void main() {
  const lifecycle = WorkflowLifecycleService();
  final occurredAt = WorkflowTestClock.occurredAt;

  group('Workflow event generation', () {
    final cases = <(WorkflowStatus, WorkflowAction, String, WorkflowActorKind)>{
      (WorkflowStatus.draft, WorkflowAction.submit, 'workflow.submitted', WorkflowActorKind.submitter),
      (WorkflowStatus.submitted, WorkflowAction.startReview, 'workflow.review_started', WorkflowActorKind.reviewer),
      (
        WorkflowStatus.submitted,
        WorkflowAction.requestInformation,
        'workflow.information_requested',
        WorkflowActorKind.reviewer,
      ),
      (WorkflowStatus.submitted, WorkflowAction.approve, 'workflow.approved', WorkflowActorKind.reviewer),
      (WorkflowStatus.submitted, WorkflowAction.reject, 'workflow.rejected', WorkflowActorKind.reviewer),
      (WorkflowStatus.submitted, WorkflowAction.withdraw, 'workflow.withdrawn', WorkflowActorKind.submitter),
      (WorkflowStatus.submitted, WorkflowAction.cancel, 'workflow.cancelled', WorkflowActorKind.admin),
      (WorkflowStatus.submitted, WorkflowAction.expire, 'workflow.expired', WorkflowActorKind.system),
      (
        WorkflowStatus.informationRequested,
        WorkflowAction.resubmit,
        'workflow.submitted',
        WorkflowActorKind.submitter,
      ),
      (
        WorkflowStatus.submitted,
        WorkflowAction.assignReviewer,
        'workflow.reviewer_assigned',
        WorkflowActorKind.admin,
      ),
    };

    for (final (status, action, eventType, actorKind) in cases) {
      test('emits $eventType for $action', () async {
        final request = _openRequest(status);
        final result = await lifecycle.planTransition(
          request: request,
          action: action,
          actor: WorkflowActor(uid: 'actor-1', kind: actorKind),
          permissionPort: _CapabilityPort(
            const WorkflowCapabilities(
              canSubmit: true,
              canReview: true,
              canApprove: true,
              canReject: true,
              canWithdraw: true,
              canCancel: true,
              canAssignReviewer: true,
            ),
          ),
          auditId: 'audit-1',
          occurredAt: occurredAt,
          notes: action == WorkflowAction.requestInformation ? 'Need more info' : 'note',
          reason: action == WorkflowAction.reject || action == WorkflowAction.cancel
              ? 'reason'
              : null,
          assignedReviewerUid:
              action == WorkflowAction.assignReviewer ? 'staff-2' : null,
        );

        expect(result, isA<WorkflowSuccess<WorkflowTransitionPlan>>());
        final plan = (result as WorkflowSuccess<WorkflowTransitionPlan>).value;
        expect(plan.events, isNotEmpty);
        expect(plan.events.first.type, eventType);
      });
    }
  });

  group('Permission denial by action category', () {
    test('submit denied without canSubmit', () async {
      final result = await lifecycle.planTransition(
        request: _openRequest(WorkflowStatus.draft),
        action: WorkflowAction.submit,
        actor: const WorkflowActor(uid: 'user-1', kind: WorkflowActorKind.submitter),
        permissionPort: _CapabilityPort(const WorkflowCapabilities()),
        auditId: 'audit-1',
        occurredAt: occurredAt,
      );

      expect((result as WorkflowFailure).code, WorkflowFailureCodes.permissionDenied);
    });

    test('approve denied without canApprove', () async {
      final result = await lifecycle.planTransition(
        request: _openRequest(WorkflowStatus.submitted),
        action: WorkflowAction.approve,
        actor: const WorkflowActor(uid: 'staff-1', kind: WorkflowActorKind.reviewer),
        permissionPort: _CapabilityPort(
          const WorkflowCapabilities(canReview: true),
        ),
        auditId: 'audit-1',
        occurredAt: occurredAt,
      );

      expect((result as WorkflowFailure).code, WorkflowFailureCodes.permissionDenied);
    });

    test('assignReviewer denied without canAssignReviewer', () async {
      final result = await lifecycle.planTransition(
        request: _openRequest(WorkflowStatus.submitted),
        action: WorkflowAction.assignReviewer,
        actor: const WorkflowActor(uid: 'admin-1', kind: WorkflowActorKind.admin),
        permissionPort: _CapabilityPort(const WorkflowCapabilities(canCancel: true)),
        auditId: 'audit-1',
        occurredAt: occurredAt,
        assignedReviewerUid: 'staff-2',
      );

      expect((result as WorkflowFailure).code, WorkflowFailureCodes.permissionDenied);
    });
  });
}

/// Fixed clock for deterministic event tests.
abstract final class WorkflowTestClock {
  static final occurredAt = DateTime.utc(2026, 1, 2, 12);
}
