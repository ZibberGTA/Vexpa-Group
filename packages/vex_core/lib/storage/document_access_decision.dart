/// Result of a document access evaluation.
final class DocumentAccessDecision {
  const DocumentAccessDecision.allowed()
      : allowed = true,
        reason = null;

  const DocumentAccessDecision.denied(this.reason) : allowed = false;

  final bool allowed;
  final String? reason;
}
