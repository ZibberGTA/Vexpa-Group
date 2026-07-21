import 'workflow_status.dart';

/// Terminal workflow decision recorded on a request.
final class WorkflowDecision {
  const WorkflowDecision({
    required this.status,
    required this.decidedAt,
    required this.decidedByUid,
    this.reason,
    this.decisionCode,
  });

  final WorkflowStatus status;
  final String? reason;
  final String? decisionCode;
  final DateTime decidedAt;
  final String decidedByUid;
}
