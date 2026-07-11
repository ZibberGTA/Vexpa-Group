import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/core/vexcore/web_vexcore.dart';
import 'package:nightlife_web/features/venue_claims/data/claim_evidence_upload_service.dart';
import 'package:vex_core/vex_core.dart';
import 'package:vex_engines/claim/domain/claim_evidence_paths.dart';

void main() {
  tearDown(() {
    WebVexCore.storageOverride = null;
    WebVexCore.documentStorageOverride = null;
  });

  test('WebVexCore exposes stable storage adapter singletons', () {
    expect(identical(WebVexCore.storage, WebVexCore.storage), isTrue);
    expect(
      identical(WebVexCore.documentStorage, WebVexCore.documentStorage),
      isTrue,
    );
  });

  group('ClaimEvidenceUploadService', () {
    late _RecordingDocumentStorage storage;
    late ClaimEvidenceUploadService service;

    setUp(() {
      storage = _RecordingDocumentStorage();
      WebVexCore.documentStorageOverride = storage;
      service = ClaimEvidenceUploadService();
    });

    test('uploads one document for claimant identity', () async {
      final identity = VexIdentity.fromProfile(
        uid: 'claimant-1',
        dashboardRole: DashboardRole.regularUser,
      );

      final result = await service.uploadDocument(
        identity: identity,
        bytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'license.pdf',
        documentId: 'doc-1',
      );

      expect(result, isA<DataSuccess<Uri>>());
      expect(storage.uploadCalls, 1);
      expect(storage.lastPath, 'claims/claimant-1/evidence/doc-1.pdf');
      expect(storage.lastOwnerId, 'claimant-1');
    });

    test('denies upload without calling storage when access fails', () async {
      storage.forceDenied = true;
      final identity = VexIdentity.fromProfile(
        uid: 'claimant-1',
        dashboardRole: DashboardRole.regularUser,
      );

      final result = await service.uploadDocument(
        identity: identity,
        bytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'license.pdf',
        documentId: 'doc-1',
      );

      expect(result, isA<DataFailure<Uri>>());
      expect(storage.uploadCalls, 0);
    });

    test('rejects oversized files before upload', () async {
      final identity = VexIdentity.fromProfile(
        uid: 'claimant-1',
        dashboardRole: DashboardRole.regularUser,
      );

      final result = await service.uploadDocument(
        identity: identity,
        bytes: Uint8List(11 * 1024 * 1024),
        fileName: 'large.pdf',
        documentId: 'doc-1',
      );

      expect(result, isA<DataFailure<Uri>>());
      expect(storage.uploadCalls, 0);
    });

    test('uses claim evidence path convention', () {
      expect(
        ClaimEvidencePaths.objectPath(
          claimantUid: 'user-1',
          documentId: 'abc',
          extension: 'png',
        ),
        'claims/user-1/evidence/abc.png',
      );
    });
  });
}

final class _RecordingDocumentStorage implements VexDocumentStorageService {
  int uploadCalls = 0;
  String? lastPath;
  String? lastOwnerId;
  bool forceDenied = false;

  @override
  DocumentAccessDecision evaluateAccess({
    required VexIdentity identity,
    required VexDocumentMetadata metadata,
  }) {
    if (forceDenied) {
      return const DocumentAccessDecision.denied('Denied for test.');
    }
    return DocumentAccessEvaluator.evaluate(
      identity: identity,
      metadata: metadata,
    );
  }

  @override
  Future<DataResult<StorageResult>> uploadBytes({
    required String path,
    required List<int> bytes,
    required VexDocumentMetadata metadata,
    String? contentType,
  }) async {
    uploadCalls++;
    lastPath = path;
    lastOwnerId = metadata.ownerId;
    return DataSuccess(
      StorageResult(
        path: path,
        downloadUrl: Uri.parse('https://storage.example.com/$path'),
      ),
    );
  }

  @override
  Future<DataResult<VexDocumentReference>> resolveReference(String path) async {
    return DataSuccess(
      VexDocumentReference(
        path: path,
        downloadUrl: Uri.parse('https://storage.example.com/$path'),
        metadata: VexDocumentMetadata(path: path, ownerId: 'claimant-1'),
      ),
    );
  }

  @override
  Future<DataResult<void>> deleteDocument(String path) async {
    return const DataSuccess(null);
  }
}
