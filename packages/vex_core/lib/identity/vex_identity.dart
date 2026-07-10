import 'account_status.dart';
import 'vex_role.dart';

final class VexIdentity {
  const VexIdentity({
    required this.uid,
    required this.roles,
    required this.status,
    this.email,
    this.venueIds = const <String>[],
  });

  final String uid;
  final String? email;
  final Set<VexRole> roles;
  final AccountStatus status;
  final List<String> venueIds;

  // TODO(vexcore): Decide whether role levels remain a compatibility detail or
  // become an explicit identity attribute.
}
