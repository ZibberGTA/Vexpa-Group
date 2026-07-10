import '../identity/vex_identity.dart';
import 'permission_decision.dart';
import 'vex_permission.dart';

abstract interface class PermissionService {
  Future<PermissionDecision> evaluate({
    required VexIdentity identity,
    required VexPermission permission,
    Map<String, Object?> context = const <String, Object?>{},
  });
}
