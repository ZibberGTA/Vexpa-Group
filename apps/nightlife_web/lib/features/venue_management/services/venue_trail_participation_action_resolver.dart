import 'package:vex_engines/trail/domain/participation/trail_participation_display_status.dart';
import 'package:vex_engines/trail/domain/participation/trail_participation_duplicate_policy.dart';
import 'package:vex_engines/workflow/domain/workflow_status.dart';

/// Venue-facing actions for a participation application.
enum VenueTrailParticipationAction {
  view,
  editDraft,
  submit,
  respond,
  resubmit,
  withdraw,
  reapply,
}

/// Resolves allowed participation actions from workflow state and eligibility.
abstract final class VenueTrailParticipationActionResolver {
  static List<VenueTrailParticipationAction> forApplication({
    required WorkflowStatus workflowStatus,
    required bool managesVenue,
    required bool ownsRequest,
    required bool trailEligibleForNewApplication,
  }) {
    if (!managesVenue || !ownsRequest) return const [];

    return switch (workflowStatus) {
      WorkflowStatus.draft => [
        VenueTrailParticipationAction.view,
        VenueTrailParticipationAction.editDraft,
        VenueTrailParticipationAction.submit,
      ],
      WorkflowStatus.submitted || WorkflowStatus.underReview => [
        VenueTrailParticipationAction.view,
        VenueTrailParticipationAction.withdraw,
      ],
      WorkflowStatus.informationRequested => [
        VenueTrailParticipationAction.view,
        VenueTrailParticipationAction.respond,
        VenueTrailParticipationAction.resubmit,
        VenueTrailParticipationAction.withdraw,
      ],
      WorkflowStatus.approved => [VenueTrailParticipationAction.view],
      WorkflowStatus.rejected ||
      WorkflowStatus.withdrawn ||
      WorkflowStatus.cancelled ||
      WorkflowStatus.expired => [
        VenueTrailParticipationAction.view,
        if (trailEligibleForNewApplication &&
            TrailParticipationDuplicatePolicy.allowsReapply(workflowStatus))
          VenueTrailParticipationAction.reapply,
      ],
    };
  }

  static String label(VenueTrailParticipationAction action) {
    return switch (action) {
      VenueTrailParticipationAction.view => 'View',
      VenueTrailParticipationAction.editDraft => 'Continue',
      VenueTrailParticipationAction.submit => 'Submit',
      VenueTrailParticipationAction.respond => 'Respond',
      VenueTrailParticipationAction.resubmit => 'Resubmit',
      VenueTrailParticipationAction.withdraw => 'Withdraw',
      VenueTrailParticipationAction.reapply => 'Apply again',
    };
  }

  static String labelForDisplayStatus(TrailParticipationDisplayStatus status) {
    return switch (status) {
      TrailParticipationDisplayStatus.draft => 'Continue',
      TrailParticipationDisplayStatus.informationRequested => 'Respond',
      TrailParticipationDisplayStatus.submitted ||
      TrailParticipationDisplayStatus.underReview => 'View',
      TrailParticipationDisplayStatus.withdrawn ||
      TrailParticipationDisplayStatus.rejected => 'Apply again',
      _ => 'View',
    };
  }
}
