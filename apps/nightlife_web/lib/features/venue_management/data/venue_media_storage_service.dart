import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:vex_core/vex_core.dart';

import '../../../core/firebase/vexda_firebase.dart';
import '../../../core/vexcore/web_vexcore.dart';

/// Uploads venue media bytes to Firebase Storage under venue-scoped paths.
class VenueMediaStorageService {
  VenueMediaStorageService({
    FirebaseStorage? storage,
    VexStorageService? vexStorage,
    Future<({String downloadUrl, String storagePath})> Function({
      required String storagePath,
      required Uint8List bytes,
      required String contentType,
    })?
    uploadOverride,
    Future<void> Function(String storagePath)? deleteOverride,
  }) : _storageOverride = storage,
       _vexStorage = vexStorage,
       _uploadOverride = uploadOverride,
       _deleteOverride = deleteOverride;

  final FirebaseStorage? _storageOverride;
  final VexStorageService? _vexStorage;
  final Future<({String downloadUrl, String storagePath})> Function({
    required String storagePath,
    required Uint8List bytes,
    required String contentType,
  })?
  _uploadOverride;
  final Future<void> Function(String storagePath)?   _deleteOverride;

  VexStorageService get _resolvedVexStorage =>
      _vexStorage ?? WebVexCore.storage;

  FirebaseStorage? _resolveStorage() {
    if (_storageOverride != null) return _storageOverride;
    if (!VexdaFirebase.isReady) return null;
    return FirebaseStorage.instance;
  }

  Future<({String downloadUrl, String storagePath})> uploadBytes({
    required String storagePath,
    required Uint8List bytes,
    required String contentType,
  }) async {
    if (_uploadOverride != null) {
      return _uploadOverride!(
        storagePath: storagePath,
        bytes: bytes,
        contentType: contentType,
      );
    }

    try {
      final result = await _resolvedVexStorage.putBytes(
        path: storagePath,
        bytes: bytes,
        contentType: contentType,
      );
      final downloadUrl = result.downloadUrl?.toString() ?? '';
      if (downloadUrl.trim().isEmpty) {
        throw StateError('Storage upload returned an empty download URL.');
      }
      return (downloadUrl: downloadUrl, storagePath: storagePath);
    } on FirebaseException catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[VenueMediaStorageService] upload failed path=$storagePath '
          'code=${error.code} plugin=${error.plugin} message=${error.message}',
        );
        debugPrint('$stackTrace');
      }
      rethrow;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[VenueMediaStorageService] upload failed path=$storagePath error=$error',
        );
        debugPrint('$stackTrace');
      }
      rethrow;
    }
  }

  Future<void> deleteAtPath(String storagePath) async {
    if (storagePath.trim().isEmpty) return;

    if (_deleteOverride != null) {
      await _deleteOverride!(storagePath);
      return;
    }

    await _resolvedVexStorage.delete(storagePath);
  }

  Future<bool> objectExistsAtPath(String storagePath) async {
    final path = storagePath.trim();
    if (path.isEmpty) return false;

    if (_uploadOverride != null) return true;

    final storage = _resolveStorage();
    if (storage == null) return false;

    try {
      await storage.ref(path).getMetadata();
      return true;
    } on FirebaseException catch (error) {
      if (error.code == 'object-not-found') return false;
      if (kDebugMode) {
        debugPrint(
          '[VenueMediaStorageService] metadata check failed path=$path '
          'code=${error.code}',
        );
      }
      return false;
    }
  }

  Future<String?> downloadUrlForPath(String storagePath) async {
    final path = storagePath.trim();
    if (path.isEmpty) return null;

    try {
      final url = await _resolvedVexStorage.downloadUrl(path);
      return url.toString();
    } on FirebaseException catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[VenueMediaStorageService] download URL failed '
          'path=$path code=${error.code} message=${error.message}',
        );
        debugPrint('$stackTrace');
      }
      return null;
    }
  }
}
