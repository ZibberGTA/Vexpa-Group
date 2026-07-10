/// Internal Vexda staff roles used by the admin permission framework.
enum StaffRole {
  supporter(10),
  coordinator(20),
  admin(30),
  superAdmin(50),
  management(60),
  founder(100);

  const StaffRole(this.level);

  final int level;

  static StaffRole fromLevel(int roleLevel) {
    if (roleLevel >= StaffRole.founder.level) return StaffRole.founder;
    if (roleLevel >= StaffRole.management.level) return StaffRole.management;
    if (roleLevel >= StaffRole.superAdmin.level) return StaffRole.superAdmin;
    if (roleLevel >= StaffRole.admin.level) return StaffRole.admin;
    if (roleLevel >= StaffRole.coordinator.level) return StaffRole.coordinator;
    return StaffRole.supporter;
  }

  static StaffRole fromName(String rawRole) {
    final normalized = rawRole.trim().toLowerCase().replaceAll('-', '_');
    return switch (normalized) {
      'supporter' => StaffRole.supporter,
      'coordinator' => StaffRole.coordinator,
      'admin' => StaffRole.admin,
      'super_admin' || 'superadmin' => StaffRole.superAdmin,
      'management' => StaffRole.management,
      'founder' => StaffRole.founder,
      _ => StaffRole.fromLevel(int.tryParse(normalized) ?? 0),
    };
  }
}
