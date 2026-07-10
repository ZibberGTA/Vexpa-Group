import 'vex_identity.dart';

abstract interface class IdentityService {
  Future<VexIdentity?> resolveCurrentIdentity();

  Future<VexIdentity?> resolveIdentity(String uid);
}
