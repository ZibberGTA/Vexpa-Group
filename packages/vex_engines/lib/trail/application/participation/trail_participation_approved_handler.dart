import '../../../workflow/application/ports/workflow_consumer_handlers.dart';
import '../../domain/participation/trail_participation_approval_plan.dart';
import '../../domain/participation/trail_participation_events.dart';
import '../../domain/participation/trail_participation_submission_payload.dart';

/// Builds an approval consequence plan without mutating trail documents.
abstract final class TrailParticipationApprovedHandler {
  static Future<void> handle(WorkflowHandlerContext context) async {
    final payload = TrailParticipationSubmissionPayload.fromPayloadValues(
      context.request.payload.values,
    );
    if (payload == null) return;

    final plan = TrailParticipationApprovalPlan(
      requestId: context.request.requestId,
      trailId: payload.trailId,
      venueId: payload.venueId,
      approvedRequestedStopOrder: payload.requestedStopOrder,
      existingTrailRevision: context.request.revision,
      proposedInsertionOrder: payload.requestedStopOrder,
      requiresManualPlacement: false,
      metadata: {
        'decisionCode': context.decisionCode,
        'reason': context.reason,
      },
    );

    // Plan is not executed in this phase. Admin review will confirm placement.
    TrailParticipationApprovedEvent(
      id: '${context.request.requestId}:approved',
      requestId: context.request.requestId,
      trailId: payload.trailId,
      venueId: payload.venueId,
      occurredAt: DateTime.now().toUtc(),
      approvalPlan: plan,
    );
  }
}

abstract final class TrailParticipationRejectedHandler {
  static Future<void> handle(WorkflowHandlerContext context) async {
    final payload = TrailParticipationSubmissionPayload.fromPayloadValues(
      context.request.payload.values,
    );
    if (payload == null) return;

    TrailParticipationRejectedEvent(
      id: '${context.request.requestId}:rejected',
      requestId: context.request.requestId,
      trailId: payload.trailId,
      venueId: payload.venueId,
      occurredAt: DateTime.now().toUtc(),
      reason: context.reason,
    );
  }
}

abstract final class TrailParticipationWithdrawnHandler {
  static Future<void> handle(WorkflowHandlerContext context) async {
    final payload = TrailParticipationSubmissionPayload.fromPayloadValues(
      context.request.payload.values,
    );
    if (payload == null) return;

    TrailParticipationWithdrawnEvent(
      id: '${context.request.requestId}:withdrawn',
      requestId: context.request.requestId,
      trailId: payload.trailId,
      venueId: payload.venueId,
      occurredAt: DateTime.now().toUtc(),
    );
  }
}

abstract final class TrailParticipationInformationRequestedHandler {
  static Future<void> handle(WorkflowHandlerContext context) async {
    // No trail mutation. Reviewer note is stored on the workflow request.
  }
}
