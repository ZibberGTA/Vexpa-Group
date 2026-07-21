import '../../../workflow/application/ports/workflow_permission_port.dart';
import '../../../workflow/domain/workflow_action.dart';
import '../../../workflow/domain/workflow_actor.dart';
import '../../../workflow/domain/workflow_request.dart';
import '../../../workflow/domain/workflow_status.dart';

/// Facts supplied by the application layer for participation permissions.
final class TrailParticipationPermissionFacts {
  const TrailParticipationPermissionFacts({
    required this.actorUid,
    required this.managesVenue,
    required this.ownsRequest,
    this.isAuthorisedReviewer = false,
  });

  final String actorUid;
  final bool managesVenue;
  final bool ownsRequest;
  final bool isAuthorisedReviewer;
}

/// Permission port for venue trail participation workflow actions.
final class TrailParticipationPermissionPort implements WorkflowPermissionPort {
  const TrailParticipationPermissionPort({required this.facts});

  final TrailParticipationPermissionFacts facts;

  @override
  Future<WorkflowCapabilities> resolve({
    required WorkflowActor actor,
    required WorkflowRequest request,
    required WorkflowAction action,
  }) async {
    final isSubmitter =
        actor.uid.trim() == request.submittedByUid.trim() &&
        facts.ownsRequest &&
        facts.managesVenue;

    final canSubmitVenueActions =
        isSubmitter &&
        facts.managesVenue &&
        actor.uid.trim() == facts.actorUid.trim();

    final canReview = facts.isAuthorisedReviewer;

    return WorkflowCapabilities(
      canSubmit:
          canSubmitVenueActions &&
          _isSubmitterAction(action, request, isSubmitter),
      canReview: canReview,
      canApprove: canReview,
      canReject: canReview,
      canWithdraw: canSubmitVenueActions && _isWithdrawAction(action),
      canCancel: canReview,
      canAssignReviewer: canReview,
    );
  }

  bool _isSubmitterAction(
    WorkflowAction action,
    WorkflowRequest request,
    bool isSubmitter,
  ) {
    if (!isSubmitter) return false;
    return switch (action) {
      WorkflowAction.createDraft => true,
      WorkflowAction.updateDraft => request.status.isOpen,
      WorkflowAction.submit => request.status.isOpen,
      WorkflowAction.resubmit =>
        request.status == WorkflowStatus.informationRequested,
      _ => false,
    };
  }

  bool _isWithdrawAction(WorkflowAction action) {
    return action == WorkflowAction.withdraw;
  }
}
