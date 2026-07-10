final class PermissionDecision {
  const PermissionDecision.allow({this.reason}) : isAllowed = true;

  const PermissionDecision.deny({this.reason}) : isAllowed = false;

  final bool isAllowed;
  final String? reason;
}
