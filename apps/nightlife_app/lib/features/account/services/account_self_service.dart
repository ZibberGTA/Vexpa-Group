import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountSelfService {
  AccountSelfService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;

  static Future<void> updateProfileDetails({
    required String displayName,
    required String phone,
    required String city,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No signed-in user.');

    await user.updateDisplayName(displayName.trim());
    await _db.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': displayName.trim(),
      'displayName': displayName.trim(),
      'email': user.email,
      'phone': phone.trim(),
      'city': city.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> updateEmailAddress(String newEmail) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No signed-in user.');

    await user.verifyBeforeUpdateEmail(newEmail.trim());
    await _db.collection('users').doc(user.uid).set({
      'pendingEmail': newEmail.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No signed-in user.');
    await user.updatePassword(newPassword.trim());
  }

  static Future<void> saveNotificationPreferences({
    required bool pushDeals,
    required bool pushEvents,
    required bool emailUpdates,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No signed-in user.');

    await _db.collection('users').doc(user.uid).set({
      'notificationPreferences': {
        'pushDeals': pushDeals,
        'pushEvents': pushEvents,
        'emailUpdates': emailUpdates,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> requestAccountDeletion({String? reason}) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No signed-in user.');

    await _db.collection('account_deletion_requests').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'reason': reason?.trim(),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _db.collection('users').doc(user.uid).set({
      'deletionRequested': true,
      'deletionRequestedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
