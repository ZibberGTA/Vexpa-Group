import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/services/auth_service.dart';

class OwnerArtistApplicationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String? get currentUserId => AuthService.currentUser?.uid;

  static Stream<DocumentSnapshot<Map<String, dynamic>>> artistProfileStream(
    String artistId,
  ) {
    return _db.collection('artist_profiles').doc(artistId).snapshots();
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> myThumbsUpStream(
    String artistId,
  ) {
    final ownerId = currentUserId;

    if (ownerId == null) {
      throw Exception('Not logged in');
    }

    return _db
        .collection('artist_profiles')
        .doc(artistId)
        .collection('thumbs_up')
        .doc(ownerId)
        .snapshots();
  }

  static Future<void> thumbsUpArtist(String artistId) async {
    final ownerId = currentUserId;
    if (ownerId == null) return;

    final artistRef = _db.collection('artist_profiles').doc(artistId);
    final thumbsRef = artistRef.collection('thumbs_up').doc(ownerId);

    await _db.runTransaction((transaction) async {
      final existingThumb = await transaction.get(thumbsRef);

      if (existingThumb.exists) {
        return;
      }

      transaction.set(thumbsRef, {
        'ownerId': ownerId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.set(
        artistRef,
        {
          'thumbsUpCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  static Future<void> removeThumbsUpArtist(String artistId) async {
    final ownerId = currentUserId;
    if (ownerId == null) return;

    final artistRef = _db.collection('artist_profiles').doc(artistId);
    final thumbsRef = artistRef.collection('thumbs_up').doc(ownerId);

    await _db.runTransaction((transaction) async {
      final existingThumb = await transaction.get(thumbsRef);

      if (!existingThumb.exists) {
        return;
      }

      transaction.delete(thumbsRef);

      transaction.set(
        artistRef,
        {
          'thumbsUpCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }
}