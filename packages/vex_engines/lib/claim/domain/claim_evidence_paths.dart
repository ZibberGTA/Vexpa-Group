/// Storage path conventions for claim evidence documents.
abstract final class ClaimEvidencePaths {
  ClaimEvidencePaths._();

  static String objectPath({
    required String claimantUid,
    required String documentId,
    required String extension,
  }) {
    final uid = claimantUid.trim();
    final id = documentId.trim();
    final ext = extension.trim().toLowerCase().replaceAll('.', '');
    if (uid.isEmpty || id.isEmpty || ext.isEmpty) {
      throw ArgumentError('Claim evidence path requires uid, document id, and extension.');
    }
    return 'claims/$uid/evidence/$id.$ext';
  }
}
