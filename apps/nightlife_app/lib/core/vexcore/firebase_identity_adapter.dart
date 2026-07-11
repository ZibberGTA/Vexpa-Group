import 'package:firebase_auth/firebase_auth.dart';
import 'package:vex_core/vex_core.dart';

import '../../features/auth/services/auth_service.dart';
import '../../features/auth/services/user_role_service.dart';
import 'identity_mapper.dart';

/// Firebase-backed identity adapter for VexCore [IdentityService].
final class FirebaseIdentityAdapter implements IdentityService {
  const FirebaseIdentityAdapter();

  @override
  Stream<VexIdentity?> get currentIdentityStream {
    return UserRoleService.currentUserRoleStream().map((_) {
      final user = AuthService.currentUser;
      if (user == null) return null;
      final snapshot = UserRoleService.peekLastSnapshot(user.uid);
      if (snapshot == null) return null;
      return identityFromRoleSnapshot(snapshot);
    });
  }

  @override
  Future<VexIdentity?> resolveCurrentIdentity() async {
    final user = AuthService.currentUser;
    if (user == null) return null;
    return resolveIdentity(user.uid);
  }

  @override
  Future<VexIdentity?> resolveIdentity(String uid) async {
    final user = AuthService.currentUser;
    if (user == null || user.uid != uid) return null;

    await UserRoleService.resolveRoleForUserSafely(user);
    final snapshot = UserRoleService.peekLastSnapshot(uid);
    if (snapshot == null) return null;

    return identityFromRoleSnapshot(snapshot);
  }

  @override
  Future<VexIdentity?> retryIdentityResolution(String uid) async {
    return resolveIdentity(uid);
  }

  @override
  VexIdentity? peekCachedIdentity(String uid) {
    final snapshot = UserRoleService.peekLastSnapshot(uid);
    if (snapshot == null) return null;
    return identityFromRoleSnapshot(snapshot);
  }

  /// Retry helper used by route guards that already hold a Firebase [User].
  Future<VexIdentity?> retryIdentityResolutionForUser(User user) async {
    await UserRoleService.resolveRoleForUserSafely(user);
    final snapshot = UserRoleService.peekLastSnapshot(user.uid);
    if (snapshot == null) return null;
    return identityFromRoleSnapshot(snapshot);
  }
}
