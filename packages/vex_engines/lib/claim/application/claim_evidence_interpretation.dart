import '../domain/claim_evidence.dart';
import 'claim_evidence_document_policy.dart';

/// Labelled evidence field for admin review panels.
final class ClaimEvidenceReviewField {
  const ClaimEvidenceReviewField({
    required this.label,
    required this.displayValue,
  });

  final String label;
  final String displayValue;
}

/// Evidence completeness classification for claim workflow.
enum ClaimEvidenceCompleteness {
  complete,
  missingContactEvidence,
  tooManyDocuments,
}

/// Interprets submitted evidence for review and storage reference checks.
final class ClaimEvidenceInterpretation {
  const ClaimEvidenceInterpretation();

  List<ClaimEvidenceReviewField> reviewFields(ClaimEvidence evidence) {
    return [
      ClaimEvidenceReviewField(
        label: 'Business Email',
        displayValue: _displayValue(evidence.businessEmail),
      ),
      ClaimEvidenceReviewField(
        label: 'Website',
        displayValue: _displayValue(evidence.website),
      ),
      ClaimEvidenceReviewField(
        label: 'Phone',
        displayValue: _displayValue(evidence.phone),
      ),
      ClaimEvidenceReviewField(
        label: 'Company Registration',
        displayValue: _displayValue(evidence.companyRegistration),
      ),
      ClaimEvidenceReviewField(
        label: 'Notes',
        displayValue: _displayValue(evidence.notes),
      ),
      ClaimEvidenceReviewField(
        label: 'Uploaded Documents',
        displayValue: evidence.documentUrls.isEmpty
            ? 'None'
            : evidence.documentUrls.join('\n'),
      ),
    ];
  }

  ClaimEvidenceCompleteness completeness(ClaimEvidence evidence) {
    if (!evidence.hasAnyContactEvidence) {
      return ClaimEvidenceCompleteness.missingContactEvidence;
    }
    if (evidence.documentUrls.length >
        ClaimEvidenceDocumentPolicy.maxDocumentCount) {
      return ClaimEvidenceCompleteness.tooManyDocuments;
    }
    return ClaimEvidenceCompleteness.complete;
  }

  /// Returns true when every document reference is scoped to the claimant.
  bool referencesBelongToClaimant({
    required Iterable<String> documentUrls,
    required String claimantUid,
  }) {
    final uid = claimantUid.trim();
    if (uid.isEmpty) {
      return false;
    }
    final prefix = 'claims/$uid/evidence/';
    for (final url in documentUrls) {
      final path = extractStoragePath(url);
      if (path == null) {
        continue;
      }
      if (!path.startsWith(prefix)) {
        return false;
      }
    }
    return true;
  }

  /// Whether a viewer may resolve a private evidence reference for download.
  bool canResolveEvidenceReference({
    required String viewerUid,
    required String claimantUid,
    required String reference,
  }) {
    final path = extractStoragePath(reference) ?? reference.trim();
    if (path.isEmpty) {
      return false;
    }
    if (viewerUid.trim() == claimantUid.trim()) {
      return referencesBelongToClaimant(
        documentUrls: [reference],
        claimantUid: claimantUid,
      );
    }
    return false;
  }

  /// Extracts a Firebase Storage object path from a download URL or raw path.
  static String? extractStoragePath(String reference) {
    final trimmed = reference.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (trimmed.startsWith('claims/')) {
      return trimmed.split('?').first;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null) {
      return null;
    }

    final objectIndex = uri.pathSegments.indexOf('o');
    if (objectIndex >= 0 && objectIndex + 1 < uri.pathSegments.length) {
      return Uri.decodeComponent(
        uri.pathSegments[objectIndex + 1],
      ).split('?').first;
    }

    return null;
  }

  static String _displayValue(String value) => value.trim();
}
