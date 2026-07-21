import 'package:vex_core/data/data_result.dart';
import 'package:vex_core/shared/vex_exception.dart';
import 'package:vex_core/workflow/workflow.dart';

/// Trusted gateway stub — privileged workflow commands require server execution.
final class FirebaseWorkflowCommandGateway implements WorkflowCommandGateway {
  const FirebaseWorkflowCommandGateway();

  @override
  Future<DataResult<WorkflowRequestSnapshot>> invoke(
    WorkflowPrivilegedCommand command,
  ) async {
    return DataFailure(
      VexException(
        'Privileged workflow commands are not available from venue clients.',
        code: 'workflow-privileged-unavailable',
      ),
    );
  }
}
