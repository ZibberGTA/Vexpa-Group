import '../domain/claim_evidence.dart';
import '../domain/claim_result.dart';

/// Validates claimant evidence before submission.
final class ClaimEvidenceValidator {
  const ClaimEvidenceValidator();

  ClaimResult<ClaimEvidence> validate(ClaimEvidence evidence) {
    if (!evidence.hasAnyContactEvidence) {
      return const ClaimFailure(
        'evidence-required',
        'Provide at least one contact detail to verify ownership.',
      );
    }

    if (evidence.hasBusinessEmail &&
        !_looksLikeEmail(evidence.businessEmail)) {
      return const ClaimFailure(
        'invalid-email',
        'Enter a valid business email address.',
      );
    }

    if (evidence.hasWebsite && !_looksLikeWebsite(evidence.website)) {
      return const ClaimFailure(
        'invalid-website',
        'Enter a valid website address.',
      );
    }

    return ClaimSuccess(evidence);
  }

  static bool _looksLikeEmail(String value) {
    final trimmed = value.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed);
  }

  static bool _looksLikeWebsite(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    return trimmed.contains('.') || trimmed.startsWith('http');
  }
}
