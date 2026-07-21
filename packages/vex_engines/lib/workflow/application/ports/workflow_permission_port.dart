import '../../domain/workflow_action.dart';
import '../../domain/workflow_actor.dart';
import '../../domain/workflow_request.dart';

/// Capability flags resolved by consumer engines for a workflow action.
final class WorkflowCapabilities {
  const WorkflowCapabilities({
    this.canSubmit = false,
    this.canReview = false,
    this.canApprove = false,
    this.canReject = false,
    this.canWithdraw = false,
    this.canCancel = false,
    this.canAssignReviewer = false,
  });

  final bool canSubmit;
  final bool canReview;
  final bool canApprove;
  final bool canReject;
  final bool canWithdraw;
  final bool canCancel;
  final bool canAssignReviewer;

  bool allows(WorkflowAction action) => switch (action) {
    WorkflowAction.createDraft ||
    WorkflowAction.updateDraft ||
    WorkflowAction.submit ||
    WorkflowAction.resubmit => canSubmit,
    WorkflowAction.startReview ||
    WorkflowAction.requestInformation => canReview,
    WorkflowAction.approve => canApprove,
    WorkflowAction.reject => canReject,
    WorkflowAction.withdraw => canWithdraw,
    WorkflowAction.cancel => canCancel,
    WorkflowAction.assignReviewer => canAssignReviewer,
    WorkflowAction.expire => true,
  };
}

/// Consumer-owned permission evaluation for workflow actions.
abstract interface class WorkflowPermissionPort {
  Future<WorkflowCapabilities> resolve({
    required WorkflowActor actor,
    required WorkflowRequest request,
    required WorkflowAction action,
  });
}
