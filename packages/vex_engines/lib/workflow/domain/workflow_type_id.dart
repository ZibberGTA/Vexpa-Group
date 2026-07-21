import 'workflow_result.dart';

/// Opaque stable workflow type identifier registered by consumer engines.
final class WorkflowTypeId {
  const WorkflowTypeId(this.value);

  final String value;

  static WorkflowResult<WorkflowTypeId> parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const WorkflowFailure(
        WorkflowFailureCodes.invalidWorkflowType,
        'Workflow type must not be empty.',
      );
    }
    return WorkflowSuccess(WorkflowTypeId(trimmed));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is WorkflowTypeId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
