import '../data/data_result.dart';
import '../identity/vex_identity.dart';
import 'document_access_decision.dart';
import 'storage_result.dart';
import 'vex_document_metadata.dart';

/// Shared storage/document contract for claims evidence and venue media.
///
/// Claim Engine owns evidence workflows. VexCore owns upload/download/delete
/// contracts, metadata, ownership, and access decisions.
abstract interface class VexDocumentStorageService {
  Future<DataResult<StorageResult>> uploadBytes({
    required String path,
    required List<int> bytes,
    required VexDocumentMetadata metadata,
    String? contentType,
  });

  Future<DataResult<VexDocumentReference>> resolveReference(String path);

  Future<DataResult<void>> deleteDocument(String path);

  DocumentAccessDecision evaluateAccess({
    required VexIdentity identity,
    required VexDocumentMetadata metadata,
  });
}
