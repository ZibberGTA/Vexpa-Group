import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SoftDeleteService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> softDelete({
    required String collection,
    required String docId,
  }) async {
    final user = _auth.currentUser;

    await _db.collection(collection).doc(docId).update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'deletedBy': user?.uid,
      'deletedByEmail': user?.email,
    });
  }

  static Future<void> restore({
    required String collection,
    required String docId,
  }) async {
    await _db.collection(collection).doc(docId).update({
      'isDeleted': false,
      'deletedAt': FieldValue.delete(),
      'deletedBy': FieldValue.delete(),
      'deletedByEmail': FieldValue.delete(),
    });
  }
}