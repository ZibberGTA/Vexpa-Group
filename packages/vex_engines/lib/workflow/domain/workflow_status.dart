import 'workflow_action.dart';
import 'workflow_result.dart';

/// Generic workflow lifecycle status.
enum WorkflowStatus {
  draft,
  submitted,
  underReview,
  informationRequested,
  approved,
  rejected,
  withdrawn,
  cancelled,
  expired,
}

/// Firestore and API helpers for [WorkflowStatus].
extension WorkflowStatusCodec on WorkflowStatus {
  String get persistenceValue => switch (this) {
    WorkflowStatus.draft => 'draft',
    WorkflowStatus.submitted => 'submitted',
    WorkflowStatus.underReview => 'under_review',
    WorkflowStatus.informationRequested => 'information_requested',
    WorkflowStatus.approved => 'approved',
    WorkflowStatus.rejected => 'rejected',
    WorkflowStatus.withdrawn => 'withdrawn',
    WorkflowStatus.cancelled => 'cancelled',
    WorkflowStatus.expired => 'expired',
  };

  bool get isTerminal => WorkflowStatusTransitions.isTerminal(this);

  bool get isOpen => WorkflowStatusTransitions.isOpen(this);
}

/// Allowed workflow status transitions enforced by the VexWorkflow engine.
final class WorkflowStatusTransitions {
  WorkflowStatusTransitions._();

  static const openStatuses = {
    WorkflowStatus.draft,
    WorkflowStatus.submitted,
    WorkflowStatus.underReview,
    WorkflowStatus.informationRequested,
  };

  static const terminalStatuses = {
    WorkflowStatus.approved,
    WorkflowStatus.rejected,
    WorkflowStatus.withdrawn,
    WorkflowStatus.cancelled,
    WorkflowStatus.expired,
  };

  static bool isOpen(WorkflowStatus status) => openStatuses.contains(status);

  static bool isTerminal(WorkflowStatus status) =>
      terminalStatuses.contains(status);

  static WorkflowResult<WorkflowStatus> parsePersistenceValue(String value) {
    final raw = value.trim().toLowerCase();
    final status = switch (raw) {
      'draft' => WorkflowStatus.draft,
      'submitted' => WorkflowStatus.submitted,
      'under_review' => WorkflowStatus.underReview,
      'information_requested' => WorkflowStatus.informationRequested,
      'approved' => WorkflowStatus.approved,
      'rejected' => WorkflowStatus.rejected,
      'withdrawn' => WorkflowStatus.withdrawn,
      'cancelled' => WorkflowStatus.cancelled,
      'expired' => WorkflowStatus.expired,
      _ => null,
    };

    if (status == null) {
      return WorkflowFailure(
        WorkflowFailureCodes.invalidStatus,
        'Unknown workflow status: $value',
      );
    }

    return WorkflowSuccess(status);
  }

  static WorkflowResult<WorkflowStatus> resolveNextStatus({
    required WorkflowStatus current,
    required WorkflowAction action,
  }) {
    if (isTerminal(current)) {
      return const WorkflowFailure(
        WorkflowFailureCodes.terminalRequest,
        'Workflow request is already terminal.',
      );
    }

    final next = _nextStatus(current, action);
    if (next == null) {
      return WorkflowFailure(
        WorkflowFailureCodes.invalidTransition,
        'Action ${action.name} is not allowed from ${current.name}.',
      );
    }

    return WorkflowSuccess(next);
  }

  static bool isTransitionAllowed({
    required WorkflowStatus current,
    required WorkflowAction action,
  }) {
    if (isTerminal(current)) {
      return false;
    }
    return _nextStatus(current, action) != null ||
        _isNonTransitionAction(current, action);
  }

  static bool _isNonTransitionAction(
    WorkflowStatus current,
    WorkflowAction action,
  ) {
    return switch (action) {
      WorkflowAction.createDraft => current == WorkflowStatus.draft,
      WorkflowAction.updateDraft => current == WorkflowStatus.draft,
      WorkflowAction.assignReviewer => isOpen(current),
      _ => false,
    };
  }

  static WorkflowStatus? _nextStatus(
    WorkflowStatus current,
    WorkflowAction action,
  ) {
    return switch ((current, action)) {
      (WorkflowStatus.draft, WorkflowAction.submit) => WorkflowStatus.submitted,
      (WorkflowStatus.draft, WorkflowAction.withdraw) =>
        WorkflowStatus.withdrawn,
      (WorkflowStatus.draft, WorkflowAction.cancel) => WorkflowStatus.cancelled,

      (WorkflowStatus.submitted, WorkflowAction.startReview) =>
        WorkflowStatus.underReview,
      (WorkflowStatus.submitted, WorkflowAction.requestInformation) =>
        WorkflowStatus.informationRequested,
      (WorkflowStatus.submitted, WorkflowAction.approve) =>
        WorkflowStatus.approved,
      (WorkflowStatus.submitted, WorkflowAction.reject) =>
        WorkflowStatus.rejected,
      (WorkflowStatus.submitted, WorkflowAction.withdraw) =>
        WorkflowStatus.withdrawn,
      (WorkflowStatus.submitted, WorkflowAction.cancel) =>
        WorkflowStatus.cancelled,
      (WorkflowStatus.submitted, WorkflowAction.expire) =>
        WorkflowStatus.expired,

      (WorkflowStatus.underReview, WorkflowAction.requestInformation) =>
        WorkflowStatus.informationRequested,
      (WorkflowStatus.underReview, WorkflowAction.approve) =>
        WorkflowStatus.approved,
      (WorkflowStatus.underReview, WorkflowAction.reject) =>
        WorkflowStatus.rejected,
      (WorkflowStatus.underReview, WorkflowAction.withdraw) =>
        WorkflowStatus.withdrawn,
      (WorkflowStatus.underReview, WorkflowAction.cancel) =>
        WorkflowStatus.cancelled,
      (WorkflowStatus.underReview, WorkflowAction.expire) =>
        WorkflowStatus.expired,

      (WorkflowStatus.informationRequested, WorkflowAction.resubmit) =>
        WorkflowStatus.submitted,
      (WorkflowStatus.informationRequested, WorkflowAction.reject) =>
        WorkflowStatus.rejected,
      (WorkflowStatus.informationRequested, WorkflowAction.withdraw) =>
        WorkflowStatus.withdrawn,
      (WorkflowStatus.informationRequested, WorkflowAction.cancel) =>
        WorkflowStatus.cancelled,
      (WorkflowStatus.informationRequested, WorkflowAction.expire) =>
        WorkflowStatus.expired,

      _ => null,
    };
  }
}
