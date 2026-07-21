/// Firestore collection paths for VexWorkflow persistence.
abstract final class WorkflowPaths {
  static const workflowRequestsCollection = 'workflow_requests';

  static String requestDocument(String requestId) =>
      '$workflowRequestsCollection/${requestId.trim()}';

  static String auditCollection(String requestId) =>
      '${requestDocument(requestId)}/audit';

  static String auditDocument(String requestId, String auditId) =>
      '${auditCollection(requestId)}/${auditId.trim()}';
}
