import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'admin_permission_service.dart';

class AdminOperationsService {
  AdminOperationsService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Stream<QuerySnapshot<Map<String, dynamic>>> staffStream() {
    return _db.collection('staff').orderBy('createdAt', descending: true).snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> accountsStream({
    String? search,
    SupportedAccountType? accountType,
  }) {
    // Client-side filtering is used by the screen for broad support search.
    return _db.collection('users').limit(250).snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> venuesStream() {
    return _db.collection('venues').limit(250).snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> drinksStream() {
    return _db.collection('drinks').limit(250).snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> dealsStream() {
    return _db.collection('deals').limit(250).snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> eventsStream() {
    return _db.collection('events').limit(250).snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> reportsStream() {
    return _db.collection('reports').limit(250).snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> deletedItemsStream() {
    return _db.collection('deleted_items').orderBy('deletedAt', descending: true).limit(250).snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> auditLogsStream() {
    return _db.collection('audit_logs').orderBy('createdAt', descending: true).limit(250).snapshots();
  }

  static Future<void> createStaffInvite({
    required String email,
    required String displayName,
    required StaffRole role,
  }) async {
    final user = _auth.currentUser;
    await _db.collection('staff_invites').add({
      'email': email.trim(),
      'displayName': displayName.trim(),
      'role': role.key,
      'roleLevel': role.level,
      'status': 'pending',
      'createdBy': user?.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await logAudit(
      action: 'STAFF_INVITE_CREATED',
      targetType: 'staff_invite',
      targetId: email.trim(),
      after: {
        'email': email.trim(),
        'displayName': displayName.trim(),
        'role': role.key,
      },
    );
  }

  static Future<void> disableStaff(String staffUid) async {
    await _db.collection('staff').doc(staffUid).set({
      'status': 'disabled',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await logAudit(
      action: 'STAFF_DISABLED',
      targetType: 'staff',
      targetId: staffUid,
    );
  }

  static Future<void> restoreDeletedItem(String deletedItemId) async {
    final doc = await _db.collection('deleted_items').doc(deletedItemId).get();
    final data = doc.data();
    if (data == null) return;

    final collection = data['originalCollection']?.toString();
    final originalId = data['originalId']?.toString();
    final snapshot = data['dataSnapshot'];

    if (collection == null || collection.isEmpty || originalId == null || originalId.isEmpty || snapshot is! Map) {
      await _db.collection('deleted_items').doc(deletedItemId).set({
        'restored': true,
        'restoredAt': FieldValue.serverTimestamp(),
        'restoreNote': 'Marked as restored. Original data snapshot was incomplete.',
      }, SetOptions(merge: true));
      return;
    }

    await _db.collection(collection).doc(originalId).set({
      ...Map<String, dynamic>.from(snapshot),
      'status': snapshot['status'] == 'deleted' ? 'active' : snapshot['status'],
      'deletedAt': FieldValue.delete(),
      'deletedBy': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _db.collection('deleted_items').doc(deletedItemId).set({
      'restored': true,
      'restoredBy': _auth.currentUser?.uid,
      'restoredAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await logAudit(
      action: 'DELETED_ITEM_RESTORED',
      targetType: data['itemType']?.toString() ?? 'deleted_item',
      targetId: originalId,
    );
  }

  static Future<void> hardDeleteDeletedItem(String deletedItemId) async {
    await _db.collection('deleted_items').doc(deletedItemId).delete();
    await logAudit(
      action: 'DELETED_ITEM_PERMANENTLY_REMOVED',
      targetType: 'deleted_item',
      targetId: deletedItemId,
    );
  }

  static Future<void> updateVenueSupportFields({
    required String venueId,
    String? name,
    List<String>? images,
  }) async {
    final update = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
    if (name != null) update['name'] = name.trim();
    if (images != null) update['images'] = images;

    await _db.collection('venues').doc(venueId).set(update, SetOptions(merge: true));
    await logAudit(
      action: 'VENUE_SUPPORT_FIELDS_UPDATED',
      targetType: 'venue',
      targetId: venueId,
      after: update,
    );
  }

  static Future<void> updateAccountStatus({
    required String uid,
    required String status,
  }) async {
    await _db.collection('users').doc(uid).set({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await logAudit(
      action: 'ACCOUNT_STATUS_UPDATED',
      targetType: 'account',
      targetId: uid,
      after: {'status': status},
    );
  }

  static Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
    await logAudit(
      action: 'PASSWORD_RESET_SENT',
      targetType: 'account',
      targetId: email.trim(),
    );
  }

  static Future<void> logAudit({
    required String action,
    required String targetType,
    required String targetId,
    Map<String, dynamic>? before,
    Map<String, dynamic>? after,
  }) async {
    final user = _auth.currentUser;
    await _db.collection('audit_logs').add({
      'actorUid': user?.uid,
      'actorEmail': user?.email,
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'before': before,
      'after': after,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
