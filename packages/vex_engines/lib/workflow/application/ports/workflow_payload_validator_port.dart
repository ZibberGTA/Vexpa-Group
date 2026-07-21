import '../../domain/workflow_payload.dart';
import '../../domain/workflow_result.dart';

/// Single payload validation issue returned by consumer engines.
final class WorkflowPayloadValidationIssue {
  const WorkflowPayloadValidationIssue({
    required this.code,
    required this.message,
    this.field,
  });

  final String code;
  final String message;
  final String? field;
}

/// Result of consumer payload validation.
sealed class WorkflowPayloadValidationResult {
  const WorkflowPayloadValidationResult();
}

final class WorkflowPayloadValidationSuccess
    extends WorkflowPayloadValidationResult {
  const WorkflowPayloadValidationSuccess();
}

final class WorkflowPayloadValidationFailure
    extends WorkflowPayloadValidationResult {
  const WorkflowPayloadValidationFailure(this.issues);

  final List<WorkflowPayloadValidationIssue> issues;
}

extension WorkflowPayloadValidationResultX on WorkflowPayloadValidationResult {
  WorkflowResult<void> toWorkflowResult() {
    if (this is WorkflowPayloadValidationSuccess) {
      return const WorkflowSuccess(null);
    }

    final failure = this as WorkflowPayloadValidationFailure;
    final primary = failure.issues.first;
    return WorkflowFailure(
      WorkflowFailureCodes.invalidPayload,
      primary.message,
    );
  }
}

/// Consumer-owned payload validation contract.
abstract interface class WorkflowPayloadValidatorPort {
  WorkflowPayloadValidationResult validateDraft(WorkflowPayload payload);

  WorkflowPayloadValidationResult validateSubmitted(WorkflowPayload payload);

  WorkflowPayloadValidationResult validateResubmitted(WorkflowPayload payload);
}
