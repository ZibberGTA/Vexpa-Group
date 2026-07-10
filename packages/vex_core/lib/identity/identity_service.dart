import 'vex_identity.dart';

abstract interface class IdentityService {
  Stream<VexIdentity?> get currentIdentityStream;

  Future<VexIdentity?> resolveCurrentIdentity();

  Future<VexIdentity?> resolveIdentity(String uid);

  Future<VexIdentity?> retryIdentityResolution(String uid);

  /// Returns the last resolved identity for [uid] without waiting on streams.
  VexIdentity? peekCachedIdentity(String uid);
}
