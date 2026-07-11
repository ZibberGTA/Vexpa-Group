import 'dart:typed_data';

import 'package:vex_core/vex_core.dart';
import 'package:vex_engines/claim/application/claim_evidence_document_policy.dart';
import 'package:vex_engines/claim/domain/claim_evidence_paths.dart';
import 'package:vex_engines/claim/domain/claim_result.dart';

import '../../../core/vexcore/web_vexcore.dart';

/// Uploads claim evidence documents through VexCore document storage contracts.
final class ClaimEvidenceUploadService {
  ClaimEvidenceUploadService({
    VexDocumentStorageService? documentStorage,
    ClaimEvidenceDocumentPolicy documentPolicy = const ClaimEvidenceDocumentPolicy(),
  })  : _documentStorage = documentStorage ?? WebVexCore.documentStorage,
        _documentPolicy = documentPolicy;

  final VexDocumentStorageService _documentStorage;
  final ClaimEvidenceDocumentPolicy _documentPolicy;

  Future<DataResult<Uri>> uploadDocument({
    required VexIdentity identity,
    required Uint8List bytes,
    required String fileName,
    required String documentId,
  }) async {
    final validation = _documentPolicy.validateFile(
      bytes: bytes,
      fileName: fileName,
    );
    if (validation is ClaimFailure<({String extension, String contentType})>) {
      return DataFailure(
        VexException(validation.message, code: validation.code),
      );
    }

    final validated =
        (validation as ClaimSuccess<({String extension, String contentType})>).value;
    final path = ClaimEvidencePaths.objectPath(
      claimantUid: identity.uid,
      documentId: documentId,
      extension: validated.extension,
    );
    final metadata = VexDocumentMetadata(
      path: path,
      ownerId: identity.uid,
      contentType: validated.contentType,
      byteLength: bytes.length,
      labels: const {'kind': 'claim-evidence'},
    );

    final access = _documentStorage.evaluateAccess(
      identity: identity,
      metadata: metadata,
    );
    if (!access.allowed) {
      return DataFailure(
        VexException(
          access.reason ?? 'You do not have access to upload this document.',
          code: 'access-denied',
        ),
      );
    }

    final upload = await _documentStorage.uploadBytes(
      path: path,
      bytes: bytes,
      metadata: metadata,
      contentType: validated.contentType,
    );

    return switch (upload) {
      DataSuccess(:final value) =>
        value.downloadUrl == null
            ? const DataFailure(
                VexException(
                  'Upload succeeded but no download URL was returned.',
                  code: 'missing-download-url',
                ),
              )
            : DataSuccess(value.downloadUrl!),
      DataFailure(:final error) => DataFailure(error),
    };
  }

  Future<DataResult<void>> deleteDocument({
    required VexIdentity identity,
    required String path,
  }) async {
    final metadata = VexDocumentMetadata(path: path, ownerId: identity.uid);
    final access = _documentStorage.evaluateAccess(
      identity: identity,
      metadata: metadata,
    );
    if (!access.allowed) {
      return DataFailure(
        VexException(
          access.reason ?? 'You do not have access to delete this document.',
          code: 'access-denied',
        ),
      );
    }

    return _documentStorage.deleteDocument(path);
  }
}

/// Generates stable evidence document ids for storage paths.
String generateClaimEvidenceDocumentId() {
  return DateTime.now().microsecondsSinceEpoch.toRadixString(36);
}
