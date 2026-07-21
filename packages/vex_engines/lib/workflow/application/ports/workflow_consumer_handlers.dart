import '../../domain/workflow_request.dart';

/// Context passed to consumer handlers after a terminal or notable transition.
final class WorkflowHandlerContext {
  const WorkflowHandlerContext({
    required this.request,
    required this.notes,
    required this.reason,
    required this.decisionCode,
  });

  final WorkflowRequest request;
  final String? notes;
  final String? reason;
  final String? decisionCode;
}

/// Consumer handler invoked after workflow approval completes.
typedef WorkflowApprovedHandler =
    Future<void> Function(WorkflowHandlerContext context);

/// Consumer handler invoked after workflow rejection completes.
typedef WorkflowRejectedHandler =
    Future<void> Function(WorkflowHandlerContext context);

/// Consumer handler invoked after submitter withdrawal completes.
typedef WorkflowWithdrawnHandler =
    Future<void> Function(WorkflowHandlerContext context);

/// Consumer handler invoked after workflow expiry completes.
typedef WorkflowExpiredHandler =
    Future<void> Function(WorkflowHandlerContext context);

/// Consumer handler invoked after information is requested.
typedef WorkflowInformationRequestedHandler =
    Future<void> Function(WorkflowHandlerContext context);
