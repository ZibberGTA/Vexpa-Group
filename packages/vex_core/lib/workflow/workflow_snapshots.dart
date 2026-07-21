/// Immutable workflow payload snapshot for repository boundaries.
final class WorkflowPayloadSnapshot {
  const WorkflowPayloadSnapshot({
    required this.values,
    required this.schemaVersion,
  });

  final Map<String, Object?> values;
  final int schemaVersion;
}

/// Generic subject references snapshot.
final class WorkflowSubjectRefsSnapshot {
  const WorkflowSubjectRefsSnapshot(this.values);

  final Map<String, String> values;
}

/// Immutable workflow request snapshot returned by repositories.
final class WorkflowRequestSnapshot {
  const WorkflowRequestSnapshot({
    required this.requestId,
    required this.workflowType,
    required this.status,
    required this.submittedByUid,
    required this.subjectRefs,
    required this.payload,
    required this.createdAt,
    required this.updatedAt,
    required this.revision,
    this.assignedReviewerUid,
    this.assignedReviewerUids = const [],
    this.reviewNotesSummary,
    this.decisionReason,
    this.decisionCode,
    this.expiresAt,
    this.submittedAt,
    this.decidedAt,
  });

  final String requestId;
  final String workflowType;
  final String status;
  final String submittedByUid;
  final WorkflowSubjectRefsSnapshot subjectRefs;
  final WorkflowPayloadSnapshot payload;
  final String? assignedReviewerUid;
  final List<String> assignedReviewerUids;
  final String? reviewNotesSummary;
  final String? decisionReason;
  final String? decisionCode;
  final DateTime? expiresAt;
  final DateTime? submittedAt;
  final DateTime? decidedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int revision;
}

/// Immutable workflow audit snapshot returned by repositories.
final class WorkflowAuditEntrySnapshot {
  const WorkflowAuditEntrySnapshot({
    required this.auditId,
    required this.requestId,
    required this.action,
    required this.fromStatus,
    required this.toStatus,
    required this.actorUid,
    required this.actorKind,
    required this.createdAt,
    this.notes,
    this.reason,
    this.metadata = const {},
  });

  final String auditId;
  final String requestId;
  final String action;
  final String fromStatus;
  final String toStatus;
  final String actorUid;
  final String actorKind;
  final String? notes;
  final String? reason;
  final Map<String, Object?> metadata;
  final DateTime createdAt;
}
