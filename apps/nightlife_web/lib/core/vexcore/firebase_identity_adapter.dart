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
    return UserRoleService.currentUserProfileStream().map((profile) {
      final user = AuthService.currentUser;
      if (user == null) return null;
      return identityFromUserRoleProfile(
        uid: user.uid,
        email: user.email,
        profile: profile,
      );
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

    final profile = await UserRoleService.getCurrentUserProfile();
    return identityFromUserRoleProfile(
      uid: uid,
      email: user.email,
      profile: profile,
    );
  }

  @override
  Future<VexIdentity?> retryIdentityResolution(String uid) async {
    final user = AuthService.currentUser;
    if (user == null || user.uid != uid) return null;

    final profile = await UserRoleService.retryRoleResolution(user);
    return identityFromUserRoleProfile(
      uid: uid,
      email: user.email,
      profile: profile,
    );
  }

  @override
  VexIdentity? peekCachedIdentity(String uid) {
    final profile = UserRoleService.peekCachedProfile(uid);
    if (profile == null) return null;

    final user = AuthService.currentUser;
    return identityFromUserRoleProfile(
      uid: uid,
      email: user?.email,
      profile: profile,
    );
  }

  /// Retry helper used by route guards that already hold a Firebase [User].
  Future<VexIdentity?> retryIdentityResolutionForUser(User user) async {
    final profile = await UserRoleService.retryRoleResolution(user);
    return identityFromUserRoleProfile(
      uid: user.uid,
      email: user.email,
      profile: profile,
    );
  }
}
