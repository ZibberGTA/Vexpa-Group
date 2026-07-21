import '../../../workflow/application/ports/workflow_consumer_registration.dart';
import '../../../workflow/application/ports/workflow_payload_validator_port.dart';
import '../../../workflow/domain/workflow_type_id.dart';
import '../../../workflow/shared/shared.dart';
import 'trail_participation_approved_handler.dart';
import 'trail_participation_payload_validator.dart';
import 'trail_participation_permission_port.dart';

/// Registers the VexTrail consumer for `trail.venue_participation`.
abstract final class TrailParticipationWorkflowRegistration {
  static WorkflowConsumerRegistration create({
    required TrailParticipationPermissionFacts permissionFacts,
    WorkflowPayloadValidatorPort? payloadValidator,
  }) {
    return WorkflowConsumerRegistration(
      workflowType: const WorkflowTypeId(
        WorkflowTypeIds.trailVenueParticipation,
      ),
      permissionPort: TrailParticipationPermissionPort(facts: permissionFacts),
      payloadValidator:
          payloadValidator ?? const TrailParticipationPayloadValidator(),
      onApproved: TrailParticipationApprovedHandler.handle,
      onRejected: TrailParticipationRejectedHandler.handle,
      onWithdrawn: TrailParticipationWithdrawnHandler.handle,
      onInformationRequested:
          TrailParticipationInformationRequestedHandler.handle,
    );
  }
}
