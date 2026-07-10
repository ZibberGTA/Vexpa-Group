import 'package:flutter/material.dart';

import 'permission_service.dart';
import 'staff_permission.dart';
import 'staff_role.dart';

/// Shows [child] only when the current permission set includes [permission].
class PermissionGate extends StatelessWidget {
  const PermissionGate({
    super.key,
    required this.permissions,
    required this.permission,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  final PermissionService permissions;
  final StaffPermission permission;
  final Widget child;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return permissions.has(permission) ? child : fallback;
  }
}

/// Builds UI from a permission check without exposing role levels.
class PermissionBuilder extends StatelessWidget {
  const PermissionBuilder({
    super.key,
    required this.permissions,
    required this.permission,
    required this.builder,
  });

  final PermissionService permissions;
  final StaffPermission permission;
  final Widget Function(BuildContext context, bool allowed) builder;

  @override
  Widget build(BuildContext context) {
    return builder(context, permissions.has(permission));
  }
}

/// Convenience helpers for constructing permission-aware widgets from a role.
extension StaffRolePermissionX on StaffRole {
  PermissionService get permissionService => PermissionService.forRole(this);

  bool can(StaffPermission permission) => permissionService.has(permission);
}
