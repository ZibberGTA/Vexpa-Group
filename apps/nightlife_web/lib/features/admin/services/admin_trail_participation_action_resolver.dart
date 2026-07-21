import 'package:vex_engines/workflow/domain/workflow_status.dart';

/// Administrator actions for trail participation review.
enum AdminTrailParticipationAction {
  view,
  requestInformation,
  approve,
  reject,
  refreshAfterConflict,
}

/// Resolves privileged participation review actions from workflow state.
abstract final class AdminTrailParticipationActionResolver {
  static List<AdminTrailParticipationAction> forRequest({
    required WorkflowStatus workflowStatus,
    required bool canManage,
    bool revisionConflict = false,
  }) {
    if (revisionConflict) {
      return const [AdminTrailParticipationAction.refreshAfterConflict];
    }

    if (!canManage) {
      return const [AdminTrailParticipationAction.view];
    }

    return switch (workflowStatus) {
      WorkflowStatus.submitted || WorkflowStatus.underReview => const [
        AdminTrailParticipationAction.view,
        AdminTrailParticipationAction.requestInformation,
        AdminTrailParticipationAction.approve,
        AdminTrailParticipationAction.reject,
      ],
      WorkflowStatus.informationRequested => const [
        AdminTrailParticipationAction.view,
        AdminTrailParticipationAction.reject,
      ],
      _ => const [AdminTrailParticipationAction.view],
    };
  }

  static String label(AdminTrailParticipationAction action) {
    return switch (action) {
      AdminTrailParticipationAction.view => 'View',
      AdminTrailParticipationAction.requestInformation =>
        'Request information',
      AdminTrailParticipationAction.approve => 'Approve',
      AdminTrailParticipationAction.reject => 'Reject',
      AdminTrailParticipationAction.refreshAfterConflict => 'Refresh',
    };
  }

  static AdminTrailParticipationAction? primaryAction(
    List<AdminTrailParticipationAction> actions,
  ) {
    for (final action in actions) {
      if (action == AdminTrailParticipationAction.view) continue;
      if (action == AdminTrailParticipationAction.refreshAfterConflict) {
        return action;
      }
      return action;
    }
    return actions.isEmpty ? null : AdminTrailParticipationAction.view;
  }

  static bool allowsDecision(AdminTrailParticipationAction action) {
    return switch (action) {
      AdminTrailParticipationAction.approve ||
      AdminTrailParticipationAction.reject ||
      AdminTrailParticipationAction.requestInformation => true,
      _ => false,
    };
  }
}
