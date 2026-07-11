import '../domain/claim_result.dart';

/// File rules for optional claim evidence uploads.
///
/// Does not change contact-field evidence requirements in [ClaimEvidenceValidator].
final class ClaimEvidenceDocumentPolicy {
  const ClaimEvidenceDocumentPolicy();

  static const maxFileSizeBytes = 10 * 1024 * 1024;
  static const maxDocumentCount = 12;
  static const allowedExtensions = {'jpg', 'jpeg', 'png', 'webp', 'pdf'};

  /// MIME types enforced by Firebase Storage rules (`storage.rules`).
  static const allowedContentTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
    'application/pdf',
  ];

  ClaimResult<({String extension, String contentType})> validateFile({
    required List<int> bytes,
    required String fileName,
  }) {
    if (bytes.isEmpty) {
      return const ClaimFailure(
        'empty-file',
        'The selected file is empty.',
      );
    }
    if (bytes.length > maxFileSizeBytes) {
      return const ClaimFailure(
        'file-too-large',
        'Supporting documents must be 10 MB or smaller.',
      );
    }

    final extension = _extensionFor(fileName);
    if (extension == null || !allowedExtensions.contains(extension)) {
      return const ClaimFailure(
        'invalid-file-type',
        'Upload a JPG, PNG, WEBP, or PDF document.',
      );
    }

    return ClaimSuccess((
      extension: extension,
      contentType: _contentTypeFor(extension),
    ));
  }

  static String? _extensionFor(String fileName) {
    final trimmed = fileName.trim().toLowerCase();
    final dot = trimmed.lastIndexOf('.');
    if (dot <= 0 || dot >= trimmed.length - 1) return null;
    return trimmed.substring(dot + 1);
  }

  static String _contentTypeFor(String extension) {
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'pdf' => 'application/pdf',
      _ => 'application/octet-stream',
    };
  }
}
