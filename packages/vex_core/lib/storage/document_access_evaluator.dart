import '../identity/dashboard_role.dart';
import '../identity/vex_identity.dart';
import 'document_access_decision.dart';
import 'vex_document_metadata.dart';

/// Pure document access rules shared across web and mobile adapters.
abstract final class DocumentAccessEvaluator {
  DocumentAccessEvaluator._();

  static DocumentAccessDecision evaluate({
    required VexIdentity identity,
    required VexDocumentMetadata metadata,
  }) {
    if (metadata.ownerId.trim().isEmpty) {
      return const DocumentAccessDecision.denied('Document owner is required.');
    }

    if (identity.uid == metadata.ownerId) {
      return const DocumentAccessDecision.allowed();
    }

    if (identity.venueIds.contains(metadata.ownerId)) {
      return const DocumentAccessDecision.allowed();
    }

    if (identity.dashboardRole == DashboardRole.admin) {
      return const DocumentAccessDecision.allowed();
    }

    if (identity.dashboardRole == DashboardRole.venueOwner ||
        identity.dashboardRole == DashboardRole.employee) {
      return const DocumentAccessDecision.denied(
        'Venue staff can only access documents they own.',
      );
    }

    return const DocumentAccessDecision.denied(
      'You do not have access to this document.',
    );
  }
}
