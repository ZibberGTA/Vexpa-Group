/// Dashboard routing roles shared across Vexda clients.
enum DashboardRole {
  admin,
  venueOwner,
  employee,
  regularUser,
}

extension DashboardRoleAccess on DashboardRole {
  bool get canAccessAdminDashboard => this == DashboardRole.admin;

  bool get canAccessVenueDashboard =>
      this == DashboardRole.admin ||
      this == DashboardRole.venueOwner ||
      this == DashboardRole.employee;

  String get label {
    return switch (this) {
      DashboardRole.admin => 'Admin',
      DashboardRole.venueOwner => 'Venue Owner',
      DashboardRole.employee => 'Employee',
      DashboardRole.regularUser => 'Customer',
    };
  }
}
