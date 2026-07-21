/// Result of workflow validation or orchestration.
sealed class WorkflowResult<T> {
  const WorkflowResult();
}

final class WorkflowSuccess<T> extends WorkflowResult<T> {
  const WorkflowSuccess(this.value);

  final T value;
}

final class WorkflowFailure<T> extends WorkflowResult<T> {
  const WorkflowFailure(this.code, this.message);

  final String code;
  final String message;
}

/// Machine-readable workflow failure codes.
abstract final class WorkflowFailureCodes {
  static const invalidTransition = 'invalidTransition';
  static const permissionDenied = 'permissionDenied';
  static const invalidPayload = 'invalidPayload';
  static const notesRequired = 'notesRequired';
  static const decisionReasonRequired = 'decisionReasonRequired';
  static const invalidActor = 'invalidActor';
  static const invalidWorkflowType = 'invalidWorkflowType';
  static const revisionConflict = 'revisionConflict';
  static const terminalRequest = 'terminalRequest';
  static const notFound = 'notFound';
  static const invalidStatus = 'invalidStatus';
  static const requestIdRequired = 'requestIdRequired';
  static const submitterRequired = 'submitterRequired';
}
