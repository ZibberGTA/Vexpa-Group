import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/services/auth_service.dart';

class NotificationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Stream<int> unreadCountStream() {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return Stream.value(0);

    return _db
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }


  static Stream<int> userUnreadCountStream() {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return Stream.value(0);

    return _db
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) => (doc.data()['audience'] ?? 'user') != 'business')
            .length);
  }

  static Stream<int> businessUnreadCountStream() {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return Stream.value(0);

    return _db
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) => (doc.data()['audience'] ?? '') == 'business')
            .length);
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamForAudience(String audience) {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) throw Exception('Not logged in');

    return _db
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('audience', isEqualTo: audience)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<void> createBusinessNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    required String relatedId,
    String? venueId,
  }) async {
    if (userId.trim().isEmpty) return;

    await _db.collection('notifications').add({
      'userId': userId,
      'title': title.trim(),
      'body': body.trim(),
      'type': type.trim(),
      'relatedId': relatedId.trim(),
      if (venueId != null) 'venueId': venueId.trim(),
      'audience': 'business',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    required String relatedId,
  }) async {
    if (userId.trim().isEmpty) return;

    await _db.collection('notifications').add({
      'userId': userId,
      'title': title.trim(),
      'body': body.trim(),
      'type': type.trim(),
      'relatedId': relatedId.trim(),
      'audience': 'user',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> markRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  static Future<void> markAllRead() async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await _db
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
