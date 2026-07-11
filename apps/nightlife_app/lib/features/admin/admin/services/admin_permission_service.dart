import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vex_core/vex_core.dart' as vex;

import '../../../../core/vexcore/admin_staff_role_bridge.dart';

/// Staff roles used by the internal admin panel.
///
/// These are separate from customer-facing app roles such as normal user,
/// venue owner, and artist. Store the active staff role in either:
/// - Firebase custom claims: staff=true, staffRole='management', roleLevel=60
/// - Firestore staff/{uid}: role='management', roleLevel=60
///
/// Firestore is used as a fallback so the app can work during development
/// before Cloud Functions/custom claims are wired up.
enum StaffRole { support, admin, management, founder }

enum SupportedAccountType { normalUser, venue, artist }

extension StaffRoleX on StaffRole {
  String get key {
    switch (this) {
      case StaffRole.support:
        return 'support';
      case StaffRole.admin:
        return 'admin';
      case StaffRole.management:
        return 'management';
      case StaffRole.founder:
        return 'founder';
    }
  }

  String get label {
    switch (this) {
      case StaffRole.support:
        return 'Support';
      case StaffRole.admin:
        return 'Admin';
      case StaffRole.management:
        return 'Management';
      case StaffRole.founder:
        return 'Founder / App Owner';
    }
  }

  int get level {
    switch (this) {
      case StaffRole.support:
        return 10;
      case StaffRole.admin:
        return 30;
      case StaffRole.management:
        return 60;
      case StaffRole.founder:
        return 100;
    }
  }

  bool atLeast(StaffRole role) => level >= role.level;

  bool get canUseAdminPanel =>
      AdminStaffRoleBridge.hasPermission(this, vex.StaffPermission.dashboardView);

  bool get canEditFullContent => AdminStaffRoleBridge.hasAnyPermission(
        this,
        const [
          vex.StaffPermission.venuesEdit,
          vex.StaffPermission.drinksManage,
          vex.StaffPermission.dealsManage,
          vex.StaffPermission.eventsManage,
        ],
      );

  bool get canManageStaff => AdminStaffRoleBridge.hasAnyPermission(
        this,
        const [
          vex.StaffPermission.staffEdit,
          vex.StaffPermission.staffInvite,
        ],
      );

  bool get canViewAuditLogs =>
      AdminStaffRoleBridge.hasPermission(this, vex.StaffPermission.auditView);

  bool get canViewFinancials =>
      AdminStaffRoleBridge.hasPermission(this, vex.StaffPermission.financials);

  bool get canHardDelete => AdminStaffRoleBridge.hasAnyPermission(
        this,
        const [
          vex.StaffPermission.usersDelete,
          vex.StaffPermission.venuesDelete,
        ],
      );

  bool canAssign(StaffRole targetRole) {
    if (this == StaffRole.founder) return true;
    if (this == StaffRole.management) {
      return targetRole == StaffRole.support || targetRole == StaffRole.admin;
    }
    return false;
  }

  bool canManageStaffMember(StaffRole targetRole) {
    if (this == StaffRole.founder) return true;
    if (this == StaffRole.management) {
      return targetRole == StaffRole.support || targetRole == StaffRole.admin;
    }
    return false;
  }

  static StaffRole fromValue(dynamic value) {
    final role = value?.toString().trim().toLowerCase();
    switch (role) {
      case 'founder':
      case 'owner':
      case 'app_owner':
        return StaffRole.founder;
      case 'management':
      case 'manager':
        return StaffRole.management;
      case 'admin':
        return StaffRole.admin;
      case 'support':
        return StaffRole.support;
      default:
        return StaffRole.support;
    }
  }

  static StaffRole fromRoleLevel(dynamic value) {
    return switch (vex.StaffRole.fromLevel(
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0,
    )) {
      vex.StaffRole.founder => StaffRole.founder,
      vex.StaffRole.management => StaffRole.management,
      vex.StaffRole.admin ||
      vex.StaffRole.superAdmin ||
      vex.StaffRole.coordinator =>
        StaffRole.admin,
      vex.StaffRole.supporter => StaffRole.support,
    };
  }

  static StaffRole fromStaffData(Map<String, dynamic>? data) {
    if (data == null) return StaffRole.support;

    final fromLevel = fromRoleLevel(data['roleLevel']);
    if (fromLevel != StaffRole.support) return fromLevel;

    return fromValue(data['role']);
  }
}

extension SupportedAccountTypeX on SupportedAccountType {
  String get key {
    switch (this) {
      case SupportedAccountType.normalUser:
        return 'user';
      case SupportedAccountType.venue:
        return 'venue';
      case SupportedAccountType.artist:
        return 'artist';
    }
  }

  String get label {
    switch (this) {
      case SupportedAccountType.normalUser:
        return 'Normal User';
      case SupportedAccountType.venue:
        return 'Venue Account';
      case SupportedAccountType.artist:
        return 'Artist Account';
    }
  }

  IconDataPlaceholder get icon {
    switch (this) {
      case SupportedAccountType.normalUser:
        return IconDataPlaceholder.person;
      case SupportedAccountType.venue:
        return IconDataPlaceholder.store;
      case SupportedAccountType.artist:
        return IconDataPlaceholder.music;
    }
  }

  static SupportedAccountType fromValue(dynamic value) {
    final type = value?.toString().trim().toLowerCase();
    if (type == 'venue' || type == 'owner' || type == 'venue_owner') {
      return SupportedAccountType.venue;
    }
    if (type == 'artist' || type == 'performer') {
      return SupportedAccountType.artist;
    }
    return SupportedAccountType.normalUser;
  }
}

/// Keeps this service UI-package-light. Widgets map these placeholders to icons.
enum IconDataPlaceholder { person, store, music }

class AdminPermissionService {
  AdminPermissionService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<StaffRole> _getStaffRoleFromFirestore(User user) async {
    final staffDoc = await _db.collection('staff').doc(user.uid).get();
    if (staffDoc.exists) {
      return StaffRoleX.fromStaffData(staffDoc.data());
    }

    final email = user.email?.trim().toLowerCase();
    if (email != null && email.isNotEmpty) {
      final staffByEmailLower = await _db
          .collection('staff')
          .where('emailLower', isEqualTo: email)
          .limit(1)
          .get();

      if (staffByEmailLower.docs.isNotEmpty) {
        return StaffRoleX.fromStaffData(staffByEmailLower.docs.first.data());
      }

      final staffByEmail = await _db
          .collection('staff')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (staffByEmail.docs.isNotEmpty) {
        return StaffRoleX.fromStaffData(staffByEmail.docs.first.data());
      }
    }

    final userDoc = await _db.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    final userRole = StaffRoleX.fromStaffData(userData);
    if (userRole != StaffRole.support) return userRole;

    return StaffRole.support;
  }

  static Future<StaffRole> getCurrentStaffRole() async {
    final user = _auth.currentUser;
    if (user == null) return StaffRole.support;

    try {
      final token = await user.getIdTokenResult(true);
      final claims = token.claims ?? <String, dynamic>{};
      if (claims['staff'] == true) {
        final fromLevel = StaffRoleX.fromRoleLevel(claims['roleLevel']);
        if (fromLevel != StaffRole.support) return fromLevel;
        return StaffRoleX.fromValue(claims['staffRole'] ?? claims['role']);
      }
    } catch (_) {
      // Firestore fallback below.
    }

    try {
      return await _getStaffRoleFromFirestore(user);
    } catch (_) {
      return StaffRole.support;
    }
  }

  static Stream<StaffRole> currentStaffRoleStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(StaffRole.support);

    return _db.collection('staff').doc(user.uid).snapshots().asyncMap((doc) async {
      if (doc.exists) {
        final role = StaffRoleX.fromStaffData(doc.data());
        if (role != StaffRole.support) return role;
      }

      return _getStaffRoleFromFirestore(user);
    });
  }
}
