import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:vex_core/vex_core.dart';

import '../firebase/vexda_firebase.dart';

/// Firebase Storage adapter for [VexStorageService].
final class FirebaseVexStorageService implements VexStorageService {
  FirebaseVexStorageService({FirebaseStorage? storage}) : _storageOverride = storage;

  final FirebaseStorage? _storageOverride;

  FirebaseStorage? _resolveStorage() {
    if (_storageOverride != null) return _storageOverride;
    if (!VexdaFirebase.isReady) return null;
    return FirebaseStorage.instance;
  }

  @override
  Future<StorageResult> putBytes({
    required String path,
    required List<int> bytes,
    String? contentType,
  }) async {
    final storage = _resolveStorage();
    if (storage == null) {
      throw StateError('Firebase Storage is not available.');
    }

    try {
      final ref = storage.ref(path);
      await ref.putData(
        Uint8List.fromList(bytes),
        SettableMetadata(contentType: contentType),
      );
      final downloadUrl = await ref.getDownloadURL();
      if (downloadUrl.trim().isEmpty) {
        throw StateError('Storage upload returned an empty download URL.');
      }
      return StorageResult(
        path: path,
        downloadUrl: Uri.parse(downloadUrl),
      );
    } on FirebaseException catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[FirebaseVexStorageService] upload failed path=$path '
          'code=${error.code} plugin=${error.plugin} message=${error.message}',
        );
        debugPrint('$stackTrace');
      }
      rethrow;
    }
  }

  @override
  Future<Uri> downloadUrl(String path) async {
    final storage = _resolveStorage();
    if (storage == null) {
      throw StateError('Firebase Storage is not available.');
    }

    try {
      final url = await storage.ref(path).getDownloadURL();
      if (url.trim().isEmpty) {
        throw StateError('Storage returned an empty download URL.');
      }
      return Uri.parse(url);
    } on FirebaseException catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[FirebaseVexStorageService] download URL failed path=$path '
          'code=${error.code} message=${error.message}',
        );
        debugPrint('$stackTrace');
      }
      rethrow;
    }
  }

  @override
  Future<void> delete(String path) async {
    if (path.trim().isEmpty) return;

    final storage = _resolveStorage();
    if (storage == null) return;

    try {
      await storage.ref(path).delete();
    } on FirebaseException catch (error) {
      if (error.code == 'object-not-found') return;
      rethrow;
    }
  }
}
