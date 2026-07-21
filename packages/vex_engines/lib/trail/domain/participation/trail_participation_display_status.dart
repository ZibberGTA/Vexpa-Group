import '../../../workflow/domain/workflow_status.dart';

/// User-facing participation application status derived from workflow status.
enum TrailParticipationDisplayStatus {
  draft,
  submitted,
  underReview,
  informationRequested,
  approved,
  rejected,
  withdrawn,
  cancelled,
  expired,
  unknown,
}

abstract final class TrailParticipationDisplayStatusMapper {
  static TrailParticipationDisplayStatus fromWorkflowStatus(
    WorkflowStatus status,
  ) {
    return switch (status) {
      WorkflowStatus.draft => TrailParticipationDisplayStatus.draft,
      WorkflowStatus.submitted => TrailParticipationDisplayStatus.submitted,
      WorkflowStatus.underReview => TrailParticipationDisplayStatus.underReview,
      WorkflowStatus.informationRequested =>
        TrailParticipationDisplayStatus.informationRequested,
      WorkflowStatus.approved => TrailParticipationDisplayStatus.approved,
      WorkflowStatus.rejected => TrailParticipationDisplayStatus.rejected,
      WorkflowStatus.withdrawn => TrailParticipationDisplayStatus.withdrawn,
      WorkflowStatus.cancelled => TrailParticipationDisplayStatus.cancelled,
      WorkflowStatus.expired => TrailParticipationDisplayStatus.expired,
    };
  }

  static String label(TrailParticipationDisplayStatus status) {
    return switch (status) {
      TrailParticipationDisplayStatus.draft => 'Draft',
      TrailParticipationDisplayStatus.submitted => 'Submitted',
      TrailParticipationDisplayStatus.underReview => 'Under review',
      TrailParticipationDisplayStatus.informationRequested =>
        'Information requested',
      TrailParticipationDisplayStatus.approved => 'Approved',
      TrailParticipationDisplayStatus.rejected => 'Rejected',
      TrailParticipationDisplayStatus.withdrawn => 'Withdrawn',
      TrailParticipationDisplayStatus.cancelled => 'Cancelled',
      TrailParticipationDisplayStatus.expired => 'Expired',
      TrailParticipationDisplayStatus.unknown => 'Unknown',
    };
  }

  static String actionGuidance(TrailParticipationDisplayStatus status) {
    return switch (status) {
      TrailParticipationDisplayStatus.draft =>
        'Complete your application and submit it for review.',
      TrailParticipationDisplayStatus.informationRequested =>
        'Update the requested details and resubmit your application.',
      TrailParticipationDisplayStatus.rejected =>
        'You may submit a new application if the trail is still accepting venues.',
      TrailParticipationDisplayStatus.approved =>
        'Your application was approved. Trail placement will be confirmed separately.',
      TrailParticipationDisplayStatus.submitted ||
      TrailParticipationDisplayStatus.underReview =>
        'Your application is being reviewed. You will be notified when there is an update.',
      TrailParticipationDisplayStatus.withdrawn =>
        'You withdrew this application. You may apply again if eligible.',
      TrailParticipationDisplayStatus.cancelled ||
      TrailParticipationDisplayStatus.expired =>
        'This application is closed. You may apply again if eligible.',
      TrailParticipationDisplayStatus.unknown => '',
    };
  }
}
