import '../data/data_result.dart';
import 'workflow_commands.dart';
import 'workflow_list_query.dart';
import 'workflow_snapshots.dart';

/// Read/write access for workflow request documents.
abstract interface class WorkflowRequestRepository {
  Future<DataResult<WorkflowRequestSnapshot>> get(String requestId);

  Stream<DataResult<WorkflowRequestSnapshot>> watch(String requestId);

  Future<DataResult<WorkflowRequestSnapshot>> createDraft(
    CreateWorkflowDraftCommand command,
  );

  Future<DataResult<WorkflowRequestSnapshot>> updateDraft(
    UpdateWorkflowDraftCommand command,
  );

  Future<DataResult<WorkflowRequestSnapshot>> submit(
    SubmitWorkflowCommand command,
  );

  Future<DataResult<WorkflowRequestSnapshot>> resubmit(
    ResubmitWorkflowCommand command,
  );

  Future<DataResult<WorkflowRequestSnapshot>> withdraw(
    WithdrawWorkflowCommand command,
  );

  Future<DataResult<List<WorkflowRequestSnapshot>>> list(
    WorkflowListQuery query,
  );

  Stream<DataResult<List<WorkflowRequestSnapshot>>> watchList(
    WorkflowListQuery query,
  );
}

/// Read access for workflow audit history.
abstract interface class WorkflowAuditRepository {
  Future<DataResult<List<WorkflowAuditEntrySnapshot>>> list(String requestId);

  Stream<DataResult<List<WorkflowAuditEntrySnapshot>>> watch(String requestId);
}

/// Trusted gateway for privileged workflow commands.
abstract interface class WorkflowCommandGateway {
  Future<DataResult<WorkflowRequestSnapshot>> invoke(
    WorkflowPrivilegedCommand command,
  );
}
