import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/vexda_firebase.dart';
import '../../venues/models/image_position_metadata.dart';

/// Reads and writes venue image URLs and positioning metadata.
class VenueImagesRepository {
  VenueImagesRepository({FirebaseFirestore? firestore})
      : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  FirebaseFirestore? _resolveFirestore() {
    if (_firestoreOverride != null) return _firestoreOverride;
    if (!VexdaFirebase.isReady) return null;
    return FirebaseFirestore.instance;
  }

  Stream<Map<String, dynamic>?> watchVenueDocument(String venueId) async* {
    final firestore = _resolveFirestore();
    if (firestore == null) {
      yield null;
      return;
    }

    yield* firestore.collection('venues').doc(venueId).snapshots().map(
          (snapshot) => snapshot.data(),
        );
  }

  Future<void> saveImagePosition({
    required String venueId,
    required ImageFrameKind frameKind,
    required ImagePositionMetadata metadata,
    String? galleryIndexKey,
  }) async {
    final firestore = _resolveFirestore();
    if (firestore == null) {
      throw StateError('Firestore is not available.');
    }

    try {
      if (frameKind == ImageFrameKind.galleryCover && galleryIndexKey != null) {
        await firestore.collection('venues').doc(venueId).set(
              {
                'galleryImagePositions': {
                  galleryIndexKey: metadata.toMap(),
                },
                'updatedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );
      } else {
        await firestore.collection('venues').doc(venueId).set(
              {
                frameKind.firestoreKey: metadata.toMap(),
                'updatedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );
      }
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint('[VenueImagesRepository] save position failed (${error.code})');
      }
      rethrow;
    }
  }

  Future<void> saveImageUrl({
    required String venueId,
    required String fieldName,
    required String url,
  }) async {
    final firestore = _resolveFirestore();
    if (firestore == null) {
      throw StateError('Firestore is not available.');
    }

    await firestore.collection('venues').doc(venueId).set(
          {
            fieldName: url,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
  }
}

ImagePositionMetadata? parseImagePositionField(
  Map<String, dynamic>? data,
  String fieldName,
) {
  if (data == null) return null;
  final raw = data[fieldName];
  if (raw is Map) {
    return ImagePositionMetadata.fromMap(Map<String, dynamic>.from(raw));
  }
  return null;
}

ImagePositionMetadata? parseGalleryImagePosition(
  Map<String, dynamic>? data,
  String indexKey,
) {
  if (data == null) return null;
  final raw = data['galleryImagePositions'];
  if (raw is! Map) return null;
  final entry = raw[indexKey];
  if (entry is Map) {
    return ImagePositionMetadata.fromMap(Map<String, dynamic>.from(entry));
  }
  return null;
}
