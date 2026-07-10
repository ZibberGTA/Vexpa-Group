import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/vexda_firebase.dart';

/// Uploads venue media bytes to Firebase Storage under venue-scoped paths.
class VenueMediaStorageService {
  VenueMediaStorageService({
    FirebaseStorage? storage,
    Future<({String downloadUrl, String storagePath})> Function({
      required String storagePath,
      required Uint8List bytes,
      required String contentType,
    })?
    uploadOverride,
    Future<void> Function(String storagePath)? deleteOverride,
  }) : _storageOverride = storage,
       _uploadOverride = uploadOverride,
       _deleteOverride = deleteOverride;

  final FirebaseStorage? _storageOverride;
  final Future<({String downloadUrl, String storagePath})> Function({
    required String storagePath,
    required Uint8List bytes,
    required String contentType,
  })?
  _uploadOverride;
  final Future<void> Function(String storagePath)? _deleteOverride;

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

    final storage = _resolveStorage();
    if (storage == null) {
      throw StateError('Firebase Storage is not available.');
    }

    try {
      final ref = storage.ref(storagePath);
      await ref.putData(bytes, SettableMetadata(contentType: contentType));
      final downloadUrl = await ref.getDownloadURL();
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

    final storage = _resolveStorage();
    if (storage == null) return;

    try {
      await storage.ref(storagePath).delete();
    } on FirebaseException catch (error) {
      if (error.code == 'object-not-found') return;
      rethrow;
    }
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

    final storage = _resolveStorage();
    if (storage == null) return null;

    try {
      final downloadUrl = await storage.ref(path).getDownloadURL();
      return downloadUrl.trim().isEmpty ? null : downloadUrl;
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
