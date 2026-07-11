import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:vex_core/vex_core.dart';

import 'firebase_vex_storage_service.dart';

/// Firebase-backed [VexDocumentStorageService] using [VexStorageService].
final class FirebaseVexDocumentStorageService implements VexDocumentStorageService {
  FirebaseVexDocumentStorageService({
    VexStorageService? storage,
  }) : _storage = storage ?? FirebaseVexStorageService();

  final VexStorageService _storage;

  @override
  DocumentAccessDecision evaluateAccess({
    required VexIdentity identity,
    required VexDocumentMetadata metadata,
  }) {
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
    try {
      final result = await _storage.putBytes(
        path: path,
        bytes: bytes,
        contentType: contentType ?? metadata.contentType,
      );
      return DataSuccess(result);
    } on FirebaseException catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[FirebaseVexDocumentStorageService] upload failed path=$path '
          'code=${error.code}',
        );
        debugPrint('$stackTrace');
      }
      return DataFailure(
        VexException(
          error.message ?? 'Document upload failed.',
          code: error.code,
          cause: error,
        ),
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[FirebaseVexDocumentStorageService] upload failed path=$path error=$error',
        );
        debugPrint('$stackTrace');
      }
      return DataFailure(
        VexException(
          'Document upload failed.',
          cause: error,
        ),
      );
    }
  }

  @override
  Future<DataResult<VexDocumentReference>> resolveReference(String path) async {
    try {
      final url = await _storage.downloadUrl(path);
      return DataSuccess(
        VexDocumentReference(
          path: path,
          downloadUrl: url,
          metadata: VexDocumentMetadata(path: path, ownerId: ''),
        ),
      );
    } on FirebaseException catch (error) {
      return DataFailure(
        VexException(
          error.message ?? 'Document reference lookup failed.',
          code: error.code,
          cause: error,
        ),
      );
    } catch (error) {
      return DataFailure(
        VexException('Document reference lookup failed.', cause: error),
      );
    }
  }

  @override
  Future<DataResult<void>> deleteDocument(String path) async {
    try {
      await _storage.delete(path);
      return const DataSuccess(null);
    } on FirebaseException catch (error) {
      return DataFailure(
        VexException(
          error.message ?? 'Document delete failed.',
          code: error.code,
          cause: error,
        ),
      );
    } catch (error) {
      return DataFailure(
        VexException('Document delete failed.', cause: error),
      );
    }
  }
}
