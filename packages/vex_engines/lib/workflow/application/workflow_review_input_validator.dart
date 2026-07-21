import '../domain/workflow_action.dart';
import '../domain/workflow_result.dart';

/// Validates notes and decision reasons required by review rules.
final class WorkflowReviewInputValidator {
  const WorkflowReviewInputValidator();

  WorkflowResult<void> validate({
    required WorkflowAction action,
    String? notes,
    String? reason,
    String? decisionCode,
  }) {
    return switch (action) {
      WorkflowAction.requestInformation => _requireNotes(notes),
      WorkflowAction.reject || WorkflowAction.cancel => _requireDecisionReason(
        reason: reason,
        decisionCode: decisionCode,
      ),
      _ => const WorkflowSuccess(null),
    };
  }

  WorkflowResult<void> _requireNotes(String? notes) {
    if (notes == null || notes.trim().isEmpty) {
      return const WorkflowFailure(
        WorkflowFailureCodes.notesRequired,
        'Review notes are required.',
      );
    }
    return const WorkflowSuccess(null);
  }

  WorkflowResult<void> _requireDecisionReason({
    String? reason,
    String? decisionCode,
  }) {
    final hasReason = reason != null && reason.trim().isNotEmpty;
    final hasCode = decisionCode != null && decisionCode.trim().isNotEmpty;
    if (!hasReason && !hasCode) {
      return const WorkflowFailure(
        WorkflowFailureCodes.decisionReasonRequired,
        'A decision reason or decision code is required.',
      );
    }
    return const WorkflowSuccess(null);
  }
}
