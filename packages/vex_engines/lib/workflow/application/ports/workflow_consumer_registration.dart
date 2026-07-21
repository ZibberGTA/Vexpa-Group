import '../../domain/workflow_type_id.dart';
import 'workflow_consumer_handlers.dart';
import 'workflow_payload_validator_port.dart';
import 'workflow_permission_port.dart';

/// Registration contract for a consumer engine workflow type.
final class WorkflowConsumerRegistration {
  const WorkflowConsumerRegistration({
    required this.workflowType,
    required this.permissionPort,
    required this.payloadValidator,
    required this.onApproved,
    required this.onRejected,
    this.onWithdrawn,
    this.onExpired,
    this.onInformationRequested,
  });

  final WorkflowTypeId workflowType;
  final WorkflowPermissionPort permissionPort;
  final WorkflowPayloadValidatorPort payloadValidator;
  final WorkflowApprovedHandler onApproved;
  final WorkflowRejectedHandler onRejected;
  final WorkflowWithdrawnHandler? onWithdrawn;
  final WorkflowExpiredHandler? onExpired;
  final WorkflowInformationRequestedHandler? onInformationRequested;
}
