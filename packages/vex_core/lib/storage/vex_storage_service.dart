import 'storage_result.dart';

abstract interface class VexStorageService {
  Future<StorageResult> putBytes({
    required String path,
    required List<int> bytes,
    String? contentType,
  });

  Future<Uri> downloadUrl(String path);

  Future<void> delete(String path);
}
