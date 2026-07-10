import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/breakpoints.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/components/drinkspot_button.dart';
import '../../../shared/components/vexda_logo.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/premium_effects.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/services/user_role_service.dart';
import '../../venue_management/widgets/page/venue_dashboard_page_widgets.dart';
import '../../venue_management/widgets/venue_dashboard_layout.dart';
import '../data/admin_claim_venue_repository.dart';
import '../data/admin_dashboard_repository.dart';
import '../models/admin_claim_venue.dart';
import '../models/admin_dashboard_models.dart';
import '../permissions/admin_page_permissions.dart';
import '../permissions/admin_permission_constants.dart';
import '../permissions/admin_permission_ui.dart';
import '../permissions/permission_service.dart';
import '../permissions/staff_permission.dart';
import '../permissions/staff_role.dart';
import '../widgets/admin_claim_venue_map.dart';
import '../widgets/claims/admin_venue_claims_page.dart';
import '../widgets/users/admin_users_crm_page.dart';
import '../widgets/venues/admin_venues_crm_page.dart';

/// Production admin shell for Vexda operations.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key, this.repository});

  final AdminDashboardRepository? repository;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final AdminDashboardRepository _repository =
      widget.repository ?? AdminDashboardRepository();

  AdminDashboardPage _selectedPage = AdminDashboardPage.dashboard;
  final _searchController = TextEditingController();
  bool _sidebarExpanded = true;
  String? _adminMapFocusVenueId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectPage(AdminDashboardPage page) {
    setState(() => _selectedPage = page);
  }

  void _navigateToAdminMapForVenue(String venueId) {
    setState(() {
      _adminMapFocusVenueId = venueId;
      _selectedPage = AdminDashboardPage.adminMap;
    });
  }

  void _navigateToUsersPage() {
    setState(() => _selectedPage = AdminDashboardPage.users);
  }

  void _navigateToSubscriptionsPage() {
    setState(() => _selectedPage = AdminDashboardPage.subscriptions);
  }

  void _clearAdminMapFocusVenueId() {
    if (_adminMapFocusVenueId == null) return;
    setState(() => _adminMapFocusVenueId = null);
  }

  @override
  Widget build(BuildContext context) {
    final compact = !Breakpoints.isDesktop(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Column(
            children: [
              _AdminTopBar(
                selectedPage: _selectedPage,
                onToggleSidebar: () {
                  setState(() => _sidebarExpanded = !_sidebarExpanded);
                },
              ),
              Expanded(
                child: _AdminPermissionsBuilder(
                  builder: (context, permissions) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!compact || _sidebarExpanded)
                          _AdminSidebar(
                            expanded: compact ? true : _sidebarExpanded,
                            selectedPage: _selectedPage,
                            permissions: permissions,
                            onPageSelected: (page) {
                              _selectPage(page);
                              if (compact) {
                                setState(() => _sidebarExpanded = false);
                              }
                            },
                          ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding:
                                _selectedPage == AdminDashboardPage.adminMap
                                ? EdgeInsets.all(
                                    compact ? AppSpacing.sm : AppSpacing.md,
                                  )
                                : EdgeInsets.all(
                                    compact ? AppSpacing.lg : AppSpacing.xl,
                                  ),
                            child: _AdminPageScaffold(
                              page: _selectedPage,
                              repository: _repository,
                              searchController: _searchController,
                              permissions: permissions,
                              adminMapFocusVenueId: _adminMapFocusVenueId,
                              onAdminMapFocusHandled:
                                  _clearAdminMapFocusVenueId,
                              onNavigateToAdminMap: _navigateToAdminMapForVenue,
                              onNavigateToUsers: _navigateToUsersPage,
                              onNavigateToSubscriptions:
                                  _navigateToSubscriptionsPage,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          if (compact && _sidebarExpanded)
            Positioned.fill(
              left: VenueDashboardLayout.sidebarExpandedWidth,
              top: VenueDashboardLayout.topBarHeight,
              child: GestureDetector(
                onTap: () => setState(() => _sidebarExpanded = false),
                child: Container(color: Colors.black.withValues(alpha: 0.42)),
              ),
            ),
        ],
      ),
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar({
    required this.selectedPage,
    required this.onToggleSidebar,
  });

  final AdminDashboardPage selectedPage;
  final VoidCallback onToggleSidebar;

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: VenueDashboardLayout.topBarHeight,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? AppSpacing.lg : AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.82),
            border: Border(
              bottom: BorderSide(
                color: AppColors.primaryPurple.withValues(alpha: 0.12),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: -8,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRouter.home,
                    (_) => false,
                  ),
                  child: VexdaLogo(
                    height: isMobile
                        ? VenueDashboardLayout.headerLogoHeightMobile
                        : VenueDashboardLayout.headerLogoHeightDesktop,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _AdminIconButton(
                icon: Icons.menu_rounded,
                tooltip: 'Toggle navigation',
                onPressed: onToggleSidebar,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  selectedPage.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                _adminWelcomeGreeting(),
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _AdminIconButton(
                icon: Icons.logout_rounded,
                tooltip: 'Log out',
                onPressed: () async {
                  await AuthService.logout();
                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRouter.home,
                    (_) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminPermissionsBuilder extends StatelessWidget {
  const _AdminPermissionsBuilder({required this.builder});

  final Widget Function(BuildContext context, PermissionService permissions)
  builder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserRoleProfile>(
      stream: UserRoleService.currentUserProfileStream(),
      builder: (context, snapshot) {
        final uid = AuthService.currentUser?.uid;
        final profile =
            snapshot.data ??
            (uid != null ? UserRoleService.peekCachedProfile(uid) : null);
        final permissions = PermissionService.fromRoleLevel(
          profile?.roleLevel ?? 0,
        );
        return builder(context, permissions);
      },
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.expanded,
    required this.selectedPage,
    required this.permissions,
    required this.onPageSelected,
  });

  final bool expanded;
  final AdminDashboardPage selectedPage;
  final PermissionService permissions;
  final ValueChanged<AdminDashboardPage> onPageSelected;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<AdminDashboardPage>>{};
    for (final page in AdminDashboardPage.values) {
      grouped.putIfAbsent(page.section, () => []).add(page);
    }

    return AnimatedContainer(
      duration: VenueDashboardLayout.sidebarTransitionDuration,
      curve: PremiumEffects.easeOut,
      width: expanded
          ? VenueDashboardLayout.sidebarExpandedWidth
          : VenueDashboardLayout.sidebarCollapsedWidth,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.58),
        border: Border(
          right: BorderSide(
            color: AppColors.primaryPurple.withValues(alpha: 0.12),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: -8,
            offset: const Offset(6, 0),
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: expanded ? AppSpacing.lg : AppSpacing.sm,
              vertical: AppSpacing.lg,
            ),
            children: [
              _AdminSidebarHeader(expanded: expanded),
              const SizedBox(height: AppSpacing.lg),
              for (final entry in grouped.entries) ...[
                if (expanded) _AdminSectionLabel(label: entry.key),
                if (expanded) const SizedBox(height: AppSpacing.xs),
                for (final page in entry.value)
                  _AdminNavItem(
                    page: page,
                    expanded: expanded,
                    selected: selectedPage == page,
                    locked: AdminPagePermissions.isNavLocked(page, permissions),
                    onTap: AdminPagePermissions.canViewPage(page, permissions)
                        ? () => onPageSelected(page)
                        : null,
                  ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminPageScaffold extends StatelessWidget {
  const _AdminPageScaffold({
    required this.page,
    required this.repository,
    required this.searchController,
    required this.permissions,
    this.adminMapFocusVenueId,
    this.onAdminMapFocusHandled,
    this.onNavigateToAdminMap,
    this.onNavigateToUsers,
    this.onNavigateToSubscriptions,
  });

  final AdminDashboardPage page;
  final AdminDashboardRepository repository;
  final TextEditingController searchController;
  final PermissionService permissions;
  final String? adminMapFocusVenueId;
  final VoidCallback? onAdminMapFocusHandled;
  final void Function(String venueId)? onNavigateToAdminMap;
  final VoidCallback? onNavigateToUsers;
  final VoidCallback? onNavigateToSubscriptions;

  @override
  Widget build(BuildContext context) {
    if (!AdminPagePermissions.canViewPage(page, permissions)) {
      return AdminAccessRestrictedCard(pageTitle: page.label);
    }

    if (page == AdminDashboardPage.adminMap) {
      return _AdminMapPage(
        repository: repository,
        permissions: permissions,
        focusVenueId: adminMapFocusVenueId,
        onFocusHandled: onAdminMapFocusHandled,
      );
    }
    if (page == AdminDashboardPage.teamMembers) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VenueDashboardPageHeader(title: page.label, subtitle: page.subtitle),
          const SizedBox(height: AppSpacing.xl),
          _TeamMembersPage(repository: repository, permissions: permissions),
        ],
      );
    }
    if (page == AdminDashboardPage.users) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VenueDashboardPageHeader(title: page.label, subtitle: page.subtitle),
          const SizedBox(height: AppSpacing.xl),
          AdminUsersCrmPage(repository: repository, permissions: permissions),
        ],
      );
    }
    if (page == AdminDashboardPage.venues) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VenueDashboardPageHeader(title: page.label, subtitle: page.subtitle),
          const SizedBox(height: AppSpacing.xl),
          AdminVenuesCrmPage(
            repository: repository,
            permissions: permissions,
            onNavigateToAdminMap: onNavigateToAdminMap,
            onNavigateToUsers: onNavigateToUsers,
            onNavigateToSubscriptions: onNavigateToSubscriptions,
          ),
        ],
      );
    }
    if (page == AdminDashboardPage.venueClaims) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VenueDashboardPageHeader(title: page.label, subtitle: page.subtitle),
          const SizedBox(height: AppSpacing.xl),
          AdminVenueClaimsPage(permissions: permissions),
        ],
      );
    }

    final sideBySide = Breakpoints.isDesktop(context);
    final main = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VenueDashboardPageHeader(
          title: page.label,
          subtitle: page.subtitle,
          primaryActionLabel: _primaryActionLabel(page),
          primaryActionIcon: _primaryActionIcon(page),
          onPrimaryAction:
              AdminPagePermissions.managePermission(page) != null &&
                  permissions.has(AdminPagePermissions.managePermission(page)!)
              ? () => _showTodo(context, _primaryActionLabel(page))
              : null,
        ),
        const SizedBox(height: AppSpacing.xl),
        _AdminPageContent(
          page: page,
          repository: repository,
          searchController: searchController,
          permissions: permissions,
        ),
      ],
    );

    if (!sideBySide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          main,
          const SizedBox(height: AppSpacing.xl),
          _AdminRightColumn(
            page: page,
            repository: repository,
            permissions: permissions,
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: main),
        const SizedBox(width: AppSpacing.xl),
        _AdminRightColumn(
          page: page,
          repository: repository,
          permissions: permissions,
        ),
      ],
    );
  }

  static String? _primaryActionLabel(AdminDashboardPage page) {
    return switch (page) {
      AdminDashboardPage.dashboard => 'Create report',
      AdminDashboardPage.adminMap => 'Export map view',
      AdminDashboardPage.developer => 'Run diagnostics',
      _ => 'New action',
    };
  }

  static IconData _primaryActionIcon(AdminDashboardPage page) {
    return switch (page) {
      AdminDashboardPage.dashboard => Icons.summarize_rounded,
      AdminDashboardPage.adminMap => Icons.ios_share_rounded,
      AdminDashboardPage.developer => Icons.terminal_rounded,
      _ => Icons.add_rounded,
    };
  }
}

class _AdminPageContent extends StatelessWidget {
  const _AdminPageContent({
    required this.page,
    required this.repository,
    required this.searchController,
    required this.permissions,
  });

  final AdminDashboardPage page;
  final AdminDashboardRepository repository;
  final TextEditingController searchController;
  final PermissionService permissions;

  @override
  Widget build(BuildContext context) {
    return switch (page) {
      AdminDashboardPage.dashboard => _AdminOverviewPage(
        repository: repository,
      ),
      AdminDashboardPage.adminMap => _AdminMapPage(
        repository: repository,
        permissions: permissions,
      ),
      AdminDashboardPage.teamMembers => _TeamMembersPage(
        repository: repository,
        permissions: permissions,
      ),
      AdminDashboardPage.developer => _DeveloperPage(
        repository: repository,
        permissions: permissions,
      ),
      AdminDashboardPage.platformAnalytics ||
      AdminDashboardPage.searchIntelligence ||
      AdminDashboardPage.venueIntelligence ||
      AdminDashboardPage.reports => _AdminAnalyticsPage(
        page: page,
        repository: repository,
        permissions: permissions,
      ),
      _ => _AdminManagementPage(
        page: page,
        repository: repository,
        searchController: searchController,
        permissions: permissions,
      ),
    };
  }
}

class _AdminOverviewPage extends StatelessWidget {
  const _AdminOverviewPage({required this.repository});

  final AdminDashboardRepository repository;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1100
                ? 4
                : constraints.maxWidth >= 760
                ? 3
                : 2;
            final width =
                (constraints.maxWidth - (AppSpacing.md * (columns - 1))) /
                columns;

            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                _LiveMetricCard(
                  width: width,
                  label: 'Total Users',
                  icon: Icons.people_rounded,
                  stream: repository.watchCollectionCount('users'),
                ),
                _LiveMetricCard(
                  width: width,
                  label: 'Total Venues',
                  icon: Icons.storefront_rounded,
                  stream: repository.watchCollectionCount('venues'),
                ),
                _LiveMetricCard(
                  width: width,
                  label: 'Claimed Venues',
                  icon: Icons.verified_rounded,
                  stream: repository.watchVenueCount(claimed: true),
                ),
                _LiveMetricCard(
                  width: width,
                  label: 'Unclaimed Venues',
                  icon: Icons.store_mall_directory_outlined,
                  stream: repository.watchVenueCount(claimed: false),
                ),
                _LiveMetricCard(
                  width: width,
                  label: 'Today\'s Signups',
                  icon: Icons.person_add_alt_1_rounded,
                  stream: repository.watchTodaySignups(),
                ),
                _LiveMetricCard(
                  width: width,
                  label: 'Events',
                  icon: Icons.event_rounded,
                  stream: repository.watchCollectionCount('events'),
                ),
                _LiveMetricCard(
                  width: width,
                  label: 'Deals',
                  icon: Icons.local_offer_rounded,
                  stream: repository.watchCollectionCount('deals'),
                ),
                _LiveMetricCard(
                  width: width,
                  label: 'Drinks',
                  icon: Icons.local_bar_rounded,
                  stream: repository.watchCollectionCount('drinks'),
                ),
                _LiveMetricCard(
                  width: width,
                  label: 'Trails',
                  icon: Icons.route_rounded,
                  stream: repository.watchCollectionCount('trails'),
                ),
                _LiveMetricCard(
                  width: width,
                  label: 'Subscriptions',
                  icon: Icons.workspace_premium_rounded,
                  stream: repository.watchCollectionCount('customers'),
                ),
                _LiveMetricCard(
                  width: width,
                  label: 'Revenue',
                  icon: Icons.payments_rounded,
                  stream: repository.watchCollectionCount('payment_events'),
                  valuePrefix: 'Events ',
                ),
                _LiveMetricCard(
                  width: width,
                  label: 'Pending Claims',
                  icon: Icons.fact_check_rounded,
                  stream: repository.watchPendingVenueReviewCount(),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 62, child: _GrowthGraphCard(repository: repository)),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              flex: 38,
              child: _LatestActivityCard(repository: repository),
            ),
          ],
        ),
      ],
    );
  }
}

class _TeamMembersPage extends StatefulWidget {
  const _TeamMembersPage({required this.repository, required this.permissions});

  final AdminDashboardRepository repository;
  final PermissionService permissions;

  @override
  State<_TeamMembersPage> createState() => _TeamMembersPageState();
}

enum _StaffTableAction {
  viewDetails,
  edit,
  changeRole,
  toggleActive,
  resendInvite,
  remove,
}

class _StaffRoleDefinition {
  const _StaffRoleDefinition({
    required this.value,
    required this.label,
    required this.roleLevel,
  });

  final String value;
  final String label;
  final int roleLevel;

  static const supporter = _StaffRoleDefinition(
    value: 'supporter',
    label: 'Supporter',
    roleLevel: 10,
  );
  static const coordinator = _StaffRoleDefinition(
    value: 'coordinator',
    label: 'Coordinator',
    roleLevel: 20,
  );
  static const admin = _StaffRoleDefinition(
    value: 'admin',
    label: 'Admin',
    roleLevel: 30,
  );
  static const superAdmin = _StaffRoleDefinition(
    value: 'super_admin',
    label: 'Super Admin',
    roleLevel: 50,
  );
  static const management = _StaffRoleDefinition(
    value: 'management',
    label: 'Management',
    roleLevel: 60,
  );
  static const founder = _StaffRoleDefinition(
    value: 'founder',
    label: 'Founder',
    roleLevel: 100,
  );

  static const values = [
    supporter,
    coordinator,
    admin,
    superAdmin,
    management,
    founder,
  ];

  static _StaffRoleDefinition fromRow(AdminDocumentRow row) {
    final roleValue = row
        .readString(['role'], fallback: '')
        .trim()
        .toLowerCase()
        .replaceAll('-', '_');
    final roleLevel = _readAdminInt(row.data, const ['roleLevel', 'level']);

    for (final role in values) {
      if (role.value == roleValue || role.roleLevel == roleLevel) {
        return role;
      }
    }
    return admin;
  }

  static _StaffRoleDefinition fromValue(String value) {
    return values.firstWhere(
      (role) => role.value == value,
      orElse: () => admin,
    );
  }
}

class _StaffAccessPolicy {
  _StaffAccessPolicy({required this.permissions, required this.actorRole});

  final PermissionService permissions;
  final StaffRole actorRole;

  factory _StaffAccessPolicy.fromContext({
    required PermissionService permissions,
    required int roleLevel,
  }) {
    return _StaffAccessPolicy(
      permissions: permissions,
      actorRole: StaffRole.fromLevel(roleLevel),
    );
  }

  bool get canViewTeamMembers => permissions.has(StaffPermission.staffView);
  bool get canInviteAny => permissions.has(StaffPermission.staffInvite);
  bool get isFounder => actorRole == StaffRole.founder;
  bool get canManageSuperAdmins =>
      permissions.has(StaffPermission.staffManageSuperAdmins);

  List<_StaffRoleDefinition> get inviteRoles => assignableRoles;

  List<_StaffRoleDefinition> get assignableRoles {
    if (isFounder) return _StaffRoleDefinition.values;
    if (canManageSuperAdmins) {
      return _StaffRoleDefinition.values
          .where(
            (role) =>
                role.roleLevel <= _StaffRoleDefinition.superAdmin.roleLevel,
          )
          .toList(growable: false);
    }
    if (permissions.has(StaffPermission.staffInvite)) {
      return const [
        _StaffRoleDefinition.supporter,
        _StaffRoleDefinition.coordinator,
        _StaffRoleDefinition.admin,
      ];
    }
    return const [];
  }

  List<_StaffRoleDefinition> get editableRoles => assignableRoles;

  bool canManageRole(_StaffRoleDefinition role) {
    if (role == _StaffRoleDefinition.founder) return isFounder;
    if (isFounder) return true;
    if (canManageSuperAdmins) {
      return role.roleLevel <= _StaffRoleDefinition.superAdmin.roleLevel;
    }
    if (permissions.has(StaffPermission.staffEdit) ||
        permissions.has(StaffPermission.staffRoleChange)) {
      return role.roleLevel <= _StaffRoleDefinition.admin.roleLevel;
    }
    return false;
  }

  bool canAssignRole(_StaffRoleDefinition role) {
    if (role == _StaffRoleDefinition.founder) return isFounder;
    if (isFounder) return true;
    if (canManageSuperAdmins) {
      return role.roleLevel <= _StaffRoleDefinition.superAdmin.roleLevel;
    }
    if (permissions.has(StaffPermission.staffRoleChange)) {
      return role.roleLevel <= _StaffRoleDefinition.admin.roleLevel;
    }
    return false;
  }

  bool canEditStaff(_StaffRoleDefinition role) {
    if (!permissions.has(StaffPermission.staffEdit)) return false;
    if (role == _StaffRoleDefinition.founder && !isFounder) return false;
    return canManageRole(role);
  }

  bool canDeactivateStaff(_StaffRoleDefinition role) {
    if (!permissions.has(StaffPermission.staffEdit)) return false;
    if (role == _StaffRoleDefinition.founder && !isFounder) return false;
    return canManageRole(role);
  }

  bool canChangeStaffRole(_StaffRoleDefinition target) {
    if (!permissions.has(StaffPermission.staffRoleChange)) return false;
    if (target == _StaffRoleDefinition.founder && !isFounder) return false;
    return canManageRole(target);
  }

  bool canRemoveRole(_StaffRoleDefinition role) {
    if (!permissions.has(StaffPermission.staffRemove)) return false;
    if (role == _StaffRoleDefinition.founder && !isFounder) return false;
    return canManageRole(role);
  }

  String get inviteTooltip {
    if (permissions.has(StaffPermission.staffInvite)) {
      return 'Invite staff member';
    }
    return kAdminPermissionDeniedTooltip;
  }

  String manageTooltipFor(_StaffRoleDefinition role) {
    if (role == _StaffRoleDefinition.founder && !isFounder) {
      return 'Founder accounts can only be managed by Founder users';
    }
    if (canManageRole(role)) return 'Manage staff member';
    return kAdminPermissionDeniedTooltip;
  }

  String editTooltipFor(_StaffRoleDefinition role) {
    if (!permissions.has(StaffPermission.staffEdit)) {
      return kAdminPermissionDeniedTooltip;
    }
    if (role == _StaffRoleDefinition.founder && !isFounder) {
      return 'Founder accounts cannot be edited unless you are Founder';
    }
    return manageTooltipFor(role);
  }

  String changeRoleTooltipFor(_StaffRoleDefinition role) {
    if (!permissions.has(StaffPermission.staffRoleChange)) {
      return kAdminPermissionDeniedTooltip;
    }
    if (role == _StaffRoleDefinition.founder && !isFounder) {
      return 'Founder role cannot be changed unless you are Founder';
    }
    return manageTooltipFor(role);
  }

  String deactivateTooltipFor(_StaffRoleDefinition role) {
    if (!permissions.has(StaffPermission.staffEdit)) {
      return kAdminPermissionDeniedTooltip;
    }
    if (role == _StaffRoleDefinition.founder && !isFounder) {
      return 'Founder accounts cannot be deactivated';
    }
    return manageTooltipFor(role);
  }

  String resendInviteTooltipFor(_StaffRoleDefinition role) {
    if (!permissions.has(StaffPermission.staffInvite)) {
      return kAdminPermissionDeniedTooltip;
    }
    return 'Resend staff invite email';
  }

  String removeTooltipFor(_StaffRoleDefinition role) {
    if (!permissions.has(StaffPermission.staffRemove)) {
      return kAdminPermissionDeniedTooltip;
    }
    if (role == _StaffRoleDefinition.founder && !isFounder) {
      return 'Founder accounts cannot be removed unless you are Founder';
    }
    return 'Remove staff member from internal team';
  }
}

class _StaffInviteDraft {
  const _StaffInviteDraft({required this.email, required this.role});

  final String email;
  final _StaffRoleDefinition role;
}

class _StaffEditDraft {
  const _StaffEditDraft({
    required this.name,
    required this.status,
    required this.active,
    required this.notes,
  });

  final String name;
  final String status;
  final bool active;
  final String notes;
}

class _StaffRoleChangeDraft {
  const _StaffRoleChangeDraft({required this.role});

  final _StaffRoleDefinition role;
}

class _TeamMembersPageState extends State<_TeamMembersPage> {
  String _search = '';
  String _roleFilter = 'All';
  String _activeFilter = 'All';
  String _statusFilter = 'All';
  AdminDocumentRow? _selectedStaff;
  late final Stream<List<AdminDocumentRow>> _staffStream;

  @override
  void initState() {
    super.initState();
    debugPrint('[TeamMembersPage] subscribing to staff collection');
    _staffStream = widget.repository.watchTeamMembersTable(limit: 500);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[TeamMembersPage] build using watchStaffCollection');
    return StreamBuilder<UserRoleProfile>(
      stream: UserRoleService.currentUserProfileStream(),
      builder: (context, profileSnapshot) {
        final uid = AuthService.currentUser?.uid;
        final profile =
            profileSnapshot.data ??
            (uid != null ? UserRoleService.peekCachedProfile(uid) : null);
        final policy = _StaffAccessPolicy.fromContext(
          permissions: widget.permissions,
          roleLevel: profile?.roleLevel ?? 0,
        );

        if (!widget.permissions.has(StaffPermission.staffView)) {
          return const AdminAccessRestrictedCard(pageTitle: 'Team Members');
        }

        return StreamBuilder<List<AdminDocumentRow>>(
          stream: _staffStream,
          builder: (context, snapshot) {
            if (snapshot.hasError && !snapshot.hasData) {
              return _TodoPanel(
                title: 'Could not load staff',
                body: _teamMembersLoadErrorBody(snapshot.error),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const _AdminLoadingPanel();
            }

            final staff = _filterStaff(snapshot.data ?? const []);
            final selected =
                _selectedStaff != null &&
                    staff.any((row) => row.id == _selectedStaff!.id)
                ? _selectedStaff
                : (staff.isEmpty ? null : staff.first);

            return LayoutBuilder(
              builder: (context, constraints) {
                final sideBySide = constraints.maxWidth >= 1080;
                final table = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TeamMembersToolbar(
                      search: _search,
                      roleFilter: _roleFilter,
                      activeFilter: _activeFilter,
                      statusFilter: _statusFilter,
                      canInvite: policy.canInviteAny,
                      inviteTooltip: policy.inviteTooltip,
                      onSearchChanged: (value) =>
                          setState(() => _search = value),
                      onRoleChanged: (value) =>
                          setState(() => _roleFilter = value),
                      onActiveChanged: (value) =>
                          setState(() => _activeFilter = value),
                      onStatusChanged: (value) =>
                          setState(() => _statusFilter = value),
                      onInvite: () => _showInviteDialog(policy),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _TeamMembersTable(
                      rows: staff,
                      selectedId: selected?.id,
                      policy: policy,
                      onSelect: (row) => setState(() => _selectedStaff = row),
                      onAction: (row, action) =>
                          _handleStaffAction(row, action, policy),
                    ),
                  ],
                );

                final details = _TeamMemberDetailsPanel(
                  staff: selected,
                  policy: policy,
                  onInvite: () => _showInviteDialog(policy),
                  onEdit: selected == null
                      ? null
                      : () => _showEditDialog(selected, policy),
                  onToggleActive: selected == null
                      ? null
                      : () => _toggleStaffActive(selected, policy),
                  onRemove: selected == null
                      ? null
                      : () => _removeStaff(selected, policy),
                );

                if (!sideBySide) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      table,
                      const SizedBox(height: AppSpacing.xl),
                      details,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: table),
                    const SizedBox(width: AppSpacing.xl),
                    SizedBox(
                      width: VenueDashboardLayout.rightColumnWidth,
                      child: details,
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  List<AdminDocumentRow> _filterStaff(List<AdminDocumentRow> rows) {
    final query = _search.trim().toLowerCase();
    return rows.where((row) {
      final role = _StaffRoleDefinition.fromRow(row);
      final status = _staffStatus(row);
      final active = _staffActive(row);

      if (_roleFilter != 'All' && role.value != _roleFilter) return false;
      if (_activeFilter == 'Active' && !active) return false;
      if (_activeFilter == 'Inactive' && active) return false;
      if (_statusFilter != 'All' && status != _statusFilter.toLowerCase()) {
        return false;
      }

      if (query.isEmpty) return true;
      final searchable = [
        row.readString(['name', 'displayName', 'fullName'], fallback: ''),
        row.readString(['email'], fallback: ''),
        role.label,
        role.value,
      ].join(' ').toLowerCase();
      return searchable.contains(query);
    }).toList()..sort((a, b) {
      final left = _StaffRoleDefinition.fromRow(a).roleLevel;
      final right = _StaffRoleDefinition.fromRow(b).roleLevel;
      return right.compareTo(left);
    });
  }

  Future<void> _handleStaffAction(
    AdminDocumentRow row,
    _StaffTableAction action,
    _StaffAccessPolicy policy,
  ) async {
    switch (action) {
      case _StaffTableAction.viewDetails:
        setState(() => _selectedStaff = row);
        await _showViewDetailsDialog(row);
      case _StaffTableAction.edit:
        await _showEditDialog(row, policy);
      case _StaffTableAction.changeRole:
        await _showChangeRoleDialog(row, policy);
      case _StaffTableAction.toggleActive:
        await _toggleStaffActive(row, policy);
      case _StaffTableAction.resendInvite:
        await _resendInvite(row, policy);
      case _StaffTableAction.remove:
        if (_isStaffInviteRow(row)) {
          await _removeInvite(row, policy);
        } else {
          await _removeStaff(row, policy);
        }
    }
  }

  Future<void> _showViewDetailsDialog(AdminDocumentRow row) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _StaffDetailsDialog(staff: row),
    );
  }

  Future<void> _showInviteDialog(_StaffAccessPolicy policy) async {
    if (!policy.canInviteAny) return;

    final result = await showDialog<_StaffInviteDraft>(
      context: context,
      builder: (context) => _StaffInviteDialog(policy: policy),
    );
    if (result == null) return;

    final currentUser = AuthService.currentUser;
    await _withStaffActionLoading(() async {
      try {
        final outcome = await widget.repository.upsertStaffInvite(
          email: result.email,
          role: result.role.value,
          roleLevel: result.role.roleLevel,
          invitedBy: currentUser?.uid ?? 'unknown',
        );
        // TODO(admin-audit): staff invite created
        if (!mounted) return;
        switch (outcome) {
          case StaffInviteUpsertResult.alreadyStaffMember:
            _showAdminSnack(context, 'This person is already a staff member.');
          case StaffInviteUpsertResult.created:
            _showAdminSnack(context, 'Staff invite created.');
          case StaffInviteUpsertResult.updated:
            _showAdminSnack(context, 'Existing invite updated and resent.');
        }
      } catch (error) {
        if (!mounted) return;
        _showAdminSnack(
          context,
          _friendlyStaffActionError('create invite', error),
        );
      }
    });
  }

  Future<void> _showEditDialog(
    AdminDocumentRow row,
    _StaffAccessPolicy policy,
  ) async {
    if (_isStaffInviteRow(row)) return;

    final targetRole = _StaffRoleDefinition.fromRow(row);
    if (!policy.canEditStaff(targetRole)) return;

    final result = await showDialog<_StaffEditDraft>(
      context: context,
      builder: (context) => _StaffEditDialog(staff: row, policy: policy),
    );
    if (result == null) return;

    await _withStaffActionLoading(() async {
      try {
        // TODO(admin-audit): staff edited
        await widget.repository.updateDocument(
          path: row.path,
          updates: {
            'name': result.name,
            'displayName': result.name,
            'status': result.status,
            'isActive': result.active,
            'active': result.active,
            'internalNotes': result.notes,
          },
        );
        if (!mounted) return;
        _showAdminSnack(context, 'Staff member updated.');
      } catch (error) {
        if (!mounted) return;
        _showAdminSnack(
          context,
          _friendlyStaffActionError('update staff member', error),
        );
      }
    });
  }

  Future<void> _showChangeRoleDialog(
    AdminDocumentRow row,
    _StaffAccessPolicy policy,
  ) async {
    if (_isStaffInviteRow(row)) return;

    final targetRole = _StaffRoleDefinition.fromRow(row);
    if (!policy.canChangeStaffRole(targetRole)) return;

    final result = await showDialog<_StaffRoleChangeDraft>(
      context: context,
      builder: (context) => _StaffChangeRoleDialog(staff: row, policy: policy),
    );
    if (result == null) return;

    if (!policy.canAssignRole(result.role)) {
      if (!mounted) return;
      _showAdminSnack(
        context,
        'You cannot assign the ${result.role.label} role.',
      );
      return;
    }

    await _withStaffActionLoading(() async {
      try {
        // TODO(admin-audit): staff role changed
        await widget.repository.updateDocument(
          path: row.path,
          updates: {
            'role': result.role.value,
            'roleLevel': result.role.roleLevel,
          },
        );
        if (!mounted) return;
        _showAdminSnack(context, 'Staff role updated to ${result.role.label}.');
      } catch (error) {
        if (!mounted) return;
        _showAdminSnack(
          context,
          _friendlyStaffActionError('update staff role', error),
        );
      }
    });
  }

  Future<void> _resendInvite(
    AdminDocumentRow row,
    _StaffAccessPolicy policy,
  ) async {
    if (!_staffCanResendInvite(row, policy)) return;

    await _withStaffActionLoading(() async {
      try {
        // TODO(admin-audit): invite resent
        // TODO(staff-invites): integrate email delivery for staff invite resend
        await widget.repository.updateDocument(
          path: row.path,
          updates: {
            'status': 'invited',
            'invitedAt': FieldValue.serverTimestamp(),
            'invitedBy': AuthService.currentUser?.uid ?? 'unknown',
          },
        );
        if (!mounted) return;
        _showAdminSnack(
          context,
          'Invite resent for ${_staffName(row)} (email integration pending).',
        );
      } catch (error) {
        if (!mounted) return;
        _showAdminSnack(
          context,
          _friendlyStaffActionError('resend invite', error),
        );
      }
    });
  }

  Future<void> _toggleStaffActive(
    AdminDocumentRow row,
    _StaffAccessPolicy policy,
  ) async {
    if (_isStaffInviteRow(row)) return;

    final role = _StaffRoleDefinition.fromRow(row);
    if (!policy.canDeactivateStaff(role)) return;

    final active = _staffActive(row);
    final confirmed = await _confirmStaffAction(
      title: active ? 'Deactivate staff member?' : 'Activate staff member?',
      message: active
          ? 'This will set active to false for ${_staffName(row)} without deleting their record.'
          : 'This will reactivate ${_staffName(row)}.',
      actionLabel: active ? 'Deactivate' : 'Activate',
    );
    if (!confirmed) return;

    await _withStaffActionLoading(() async {
      try {
        if (active) {
          // TODO(admin-audit): staff deactivated
        } else {
          // TODO(admin-audit): staff reactivated
        }
        await widget.repository.updateDocument(
          path: row.path,
          updates: {'isActive': !active, 'active': !active},
        );
        if (!mounted) return;
        _showAdminSnack(
          context,
          active ? 'Staff deactivated.' : 'Staff activated.',
        );
      } catch (error) {
        if (!mounted) return;
        _showAdminSnack(
          context,
          _friendlyStaffActionError('update staff status', error),
        );
      }
    });
  }

  Future<void> _removeStaff(
    AdminDocumentRow row,
    _StaffAccessPolicy policy,
  ) async {
    if (_isStaffInviteRow(row)) return;

    final role = _StaffRoleDefinition.fromRow(row);
    if (!policy.canRemoveRole(role)) return;

    final confirmed = await _confirmStaffAction(
      title: 'Remove staff member?',
      message:
          'This will remove the staff account from the internal Vexda team.',
      actionLabel: 'Remove',
      destructive: true,
    );
    if (!confirmed) return;

    final removedBy = AuthService.currentUser?.uid ?? 'unknown';
    await _withStaffActionLoading(() async {
      try {
        // TODO(admin-audit): staff removed
        await widget.repository.updateDocument(
          path: row.path,
          updates: {
            'status': 'removed',
            'active': false,
            'isActive': false,
            'removedAt': FieldValue.serverTimestamp(),
            'removedBy': removedBy,
          },
        );
        if (!mounted) return;
        setState(() => _selectedStaff = null);
        _showAdminSnack(context, 'Staff member marked as removed.');
      } catch (error) {
        if (!mounted) return;
        _showAdminSnack(
          context,
          _friendlyStaffActionError('remove staff member', error),
        );
      }
    });
  }

  Future<void> _removeInvite(
    AdminDocumentRow row,
    _StaffAccessPolicy policy,
  ) async {
    if (!_staffCanRemoveInvite(row, policy)) return;

    final confirmed = await _confirmStaffAction(
      title: 'Remove invite?',
      message:
          'This will remove the pending staff invite for ${_staffName(row)}.',
      actionLabel: 'Remove Invite',
      destructive: true,
    );
    if (!confirmed) return;

    final removedBy = AuthService.currentUser?.uid ?? 'unknown';
    await _withStaffActionLoading(() async {
      try {
        // TODO(admin-audit): invite removed
        await widget.repository.updateDocument(
          path: row.path,
          updates: {
            'status': 'removed',
            'active': false,
            'isActive': false,
            'removedAt': FieldValue.serverTimestamp(),
            'removedBy': removedBy,
          },
        );
        if (!mounted) return;
        if (_selectedStaff?.id == row.id) {
          setState(() => _selectedStaff = null);
        }
        _showAdminSnack(context, 'Staff invite removed.');
      } catch (error) {
        if (!mounted) return;
        _showAdminSnack(
          context,
          _friendlyStaffActionError('remove invite', error),
        );
      }
    });
  }

  Future<void> _withStaffActionLoading(Future<void> Function() action) async {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PopScope(
        canPop: false,
        child: Center(
          child: Card(
            color: AppColors.surfaceElevated,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Text(
                    'Saving...',
                    style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      await action();
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  String _friendlyStaffActionError(String action, Object error) {
    if (error is FirebaseException) {
      return 'Could not $action.\n${error.message ?? error.code}';
    }
    return 'Could not $action.\n$error';
  }

  Future<bool> _confirmStaffAction({
    required String title,
    required String message,
    required String actionLabel,
    bool destructive = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text(title, style: const TextStyle(color: AppColors.white)),
        content: Text(
          message,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              actionLabel,
              style: TextStyle(
                color: destructive ? Colors.redAccent : AppColors.primaryPink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    return confirmed == true;
  }
}

class _TeamMembersToolbar extends StatelessWidget {
  const _TeamMembersToolbar({
    required this.search,
    required this.roleFilter,
    required this.activeFilter,
    required this.statusFilter,
    required this.canInvite,
    required this.inviteTooltip,
    required this.onSearchChanged,
    required this.onRoleChanged,
    required this.onActiveChanged,
    required this.onStatusChanged,
    required this.onInvite,
  });

  final String search;
  final String roleFilter;
  final String activeFilter;
  final String statusFilter;
  final bool canInvite;
  final String inviteTooltip;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<String> onActiveChanged;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    return VenuePageSection(
      title: 'Search, Filters & Staff Actions',
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 320,
            child: TextField(
              onChanged: onSearchChanged,
              style: const TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                hintText: 'Search name, email or role',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppColors.surfaceElevated.withValues(alpha: 0.78),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
          ),
          _MiniDropdown(
            label: 'Role',
            value: roleFilter,
            values: const [
              'All',
              'supporter',
              'coordinator',
              'admin',
              'super_admin',
              'management',
              'founder',
            ],
            onChanged: onRoleChanged,
          ),
          _MiniDropdown(
            label: 'Active',
            value: activeFilter,
            values: const ['All', 'Active', 'Inactive'],
            onChanged: onActiveChanged,
          ),
          _MiniDropdown(
            label: 'Status',
            value: statusFilter,
            values: const [
              'All',
              'active',
              'disabled',
              'invited',
              'pending',
              'accepted',
              'expired',
              'removed',
            ],
            onChanged: onStatusChanged,
          ),
          Tooltip(
            message: canInvite ? 'Invite staff member' : inviteTooltip,
            child: DrinkSpotButton(
              label: 'Invite staff',
              icon: Icons.person_add_alt_1_rounded,
              compact: true,
              onPressed: canInvite ? onInvite : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamMembersTable extends StatelessWidget {
  const _TeamMembersTable({
    required this.rows,
    required this.selectedId,
    required this.policy,
    required this.onSelect,
    required this.onAction,
  });

  final List<AdminDocumentRow> rows;
  final String? selectedId;
  final _StaffAccessPolicy policy;
  final ValueChanged<AdminDocumentRow> onSelect;
  final void Function(AdminDocumentRow row, _StaffTableAction action) onAction;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const VenuePageSection(
        title: 'No team members found',
        child: Text(
          'No staff records match the current search and filters.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return VenuePageSection(
      title: 'Staff Management',
      trailing: Text(
        '${rows.length} shown',
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
          dataTextStyle: const TextStyle(
            color: AppColors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          columns: const [
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Role')),
            DataColumn(label: Text('Role Level')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Active')),
            DataColumn(label: Text('Last Login')),
            DataColumn(label: Text('Created At')),
            DataColumn(label: Text('Actions')),
          ],
          rows: rows.map((row) {
            final role = _StaffRoleDefinition.fromRow(row);
            final active = _staffActive(row);
            return DataRow(
              selected: selectedId == row.id,
              onSelectChanged: (_) => onSelect(row),
              cells: [
                DataCell(Text(_staffName(row))),
                DataCell(Text(row.readString(['email']))),
                DataCell(_StaffRoleChip(role: role)),
                DataCell(Text('${role.roleLevel}')),
                DataCell(_StatusPill(label: _staffStatusLabel(row))),
                DataCell(_ActiveChip(active: active)),
                DataCell(
                  Text(
                    _readAdminDate(row.data, const [
                      'lastLoginAt',
                      'lastLogin',
                      'lastSignInTime',
                    ]),
                  ),
                ),
                DataCell(Text(_staffCreatedDate(row))),
                DataCell(
                  _StaffActionsMenu(
                    row: row,
                    role: role,
                    active: active,
                    policy: policy,
                    onAction: onAction,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _StaffActionsMenu extends StatelessWidget {
  const _StaffActionsMenu({
    required this.row,
    required this.role,
    required this.active,
    required this.policy,
    required this.onAction,
  });

  final AdminDocumentRow row;
  final _StaffRoleDefinition role;
  final bool active;
  final _StaffAccessPolicy policy;
  final void Function(AdminDocumentRow row, _StaffTableAction action) onAction;

  @override
  Widget build(BuildContext context) {
    final isInvite = _isStaffInviteRow(row);
    final inviteStatus = isInvite ? _staffStatus(row).toLowerCase() : '';
    final canEdit = !isInvite && policy.canEditStaff(role);
    final canChangeRole = !isInvite && policy.canChangeStaffRole(role);
    final canDeactivate = !isInvite && policy.canDeactivateStaff(role);
    final canResend = _staffCanResendInvite(row, policy);
    final canRemove = isInvite
        ? _staffCanRemoveInvite(row, policy)
        : policy.canRemoveRole(role);

    if (isInvite) {
      final items = <PopupMenuItem<_StaffTableAction>>[
        _staffActionItem(
          action: _StaffTableAction.viewDetails,
          label: 'View Staff Details',
          enabled: true,
          tooltip: 'View invite details',
        ),
      ];

      if (inviteStatus == 'accepted') {
        return PopupMenuButton<_StaffTableAction>(
          tooltip: 'Invite actions',
          color: AppColors.surfaceElevated,
          icon: const Icon(
            Icons.more_horiz_rounded,
            color: AppColors.textSecondary,
          ),
          onSelected: (action) => onAction(row, action),
          itemBuilder: (context) => items,
        );
      }

      if (canResend) {
        items.add(
          _staffActionItem(
            action: _StaffTableAction.resendInvite,
            label: 'Resend Invite',
            enabled: true,
            tooltip: policy.resendInviteTooltipFor(role),
          ),
        );
      }
      if (canRemove) {
        items.add(
          _staffActionItem(
            action: _StaffTableAction.remove,
            label: 'Remove Invite',
            enabled: true,
            tooltip: 'Remove pending staff invite',
          ),
        );
      }

      return PopupMenuButton<_StaffTableAction>(
        tooltip: 'Invite actions',
        color: AppColors.surfaceElevated,
        icon: const Icon(
          Icons.more_horiz_rounded,
          color: AppColors.textSecondary,
        ),
        onSelected: (action) => onAction(row, action),
        itemBuilder: (context) => items,
      );
    }

    return PopupMenuButton<_StaffTableAction>(
      tooltip: 'Staff actions',
      color: AppColors.surfaceElevated,
      icon: const Icon(
        Icons.more_horiz_rounded,
        color: AppColors.textSecondary,
      ),
      onSelected: (action) => onAction(row, action),
      itemBuilder: (context) => [
        _staffActionItem(
          action: _StaffTableAction.viewDetails,
          label: 'View Staff Details',
          enabled: true,
          tooltip: 'View full staff profile',
        ),
        _staffActionItem(
          action: _StaffTableAction.edit,
          label: 'Edit Staff',
          enabled: canEdit,
          tooltip: policy.editTooltipFor(role),
        ),
        _staffActionItem(
          action: _StaffTableAction.changeRole,
          label: 'Change Role',
          enabled: canChangeRole,
          tooltip: policy.changeRoleTooltipFor(role),
        ),
        _staffActionItem(
          action: _StaffTableAction.toggleActive,
          label: active ? 'Deactivate' : 'Activate',
          enabled: canDeactivate,
          tooltip: policy.deactivateTooltipFor(role),
        ),
        _staffActionItem(
          action: _StaffTableAction.resendInvite,
          label: 'Resend Invite',
          enabled: canResend,
          tooltip: canResend
              ? policy.resendInviteTooltipFor(role)
              : 'Available only for pending or invited staff',
        ),
        _staffActionItem(
          action: _StaffTableAction.remove,
          label: 'Remove Staff',
          enabled: canRemove,
          tooltip: policy.removeTooltipFor(role),
        ),
      ],
    );
  }

  PopupMenuItem<_StaffTableAction> _staffActionItem({
    required _StaffTableAction action,
    required String label,
    required bool enabled,
    required String tooltip,
  }) {
    return PopupMenuItem(
      value: action,
      enabled: enabled,
      child: Tooltip(
        message: tooltip,
        child: Text(
          enabled ? label : '$label — $tooltip',
          style: TextStyle(
            color: enabled ? AppColors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _TeamMemberDetailsPanel extends StatelessWidget {
  const _TeamMemberDetailsPanel({
    required this.staff,
    required this.policy,
    required this.onInvite,
    required this.onEdit,
    required this.onToggleActive,
    required this.onRemove,
  });

  final AdminDocumentRow? staff;
  final _StaffAccessPolicy policy;
  final VoidCallback onInvite;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleActive;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final selected = staff;
    final isInvite = selected != null && _isStaffInviteRow(selected);
    final role = selected == null
        ? null
        : _StaffRoleDefinition.fromRow(selected);
    final active = selected == null ? false : _staffActive(selected);
    final canManage = role != null && !isInvite && policy.canEditStaff(role);
    final canDeactivate =
        role != null && !isInvite && policy.canDeactivateStaff(role);
    final canRemove = isInvite
        ? policy.permissions.has(StaffPermission.staffRemove)
        : role != null && policy.canRemoveRole(role);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VenuePageSection(
          title: 'Quick Actions',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Tooltip(
                message: policy.canInviteAny
                    ? 'Invite staff member'
                    : policy.inviteTooltip,
                child: DrinkSpotButton(
                  label: 'Invite Staff Member',
                  icon: Icons.person_add_alt_1_rounded,
                  compact: true,
                  onPressed: policy.canInviteAny ? onInvite : null,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Tooltip(
                message: selected == null
                    ? 'Select a staff member first'
                    : canManage
                    ? 'Edit selected staff member'
                    : policy.editTooltipFor(role!),
                child: DrinkSpotButton(
                  label: 'Edit Staff Member',
                  icon: Icons.edit_rounded,
                  compact: true,
                  variant: DrinkSpotButtonVariant.secondary,
                  onPressed: canManage ? onEdit : null,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Tooltip(
                message: selected == null
                    ? 'Select a staff member first'
                    : canDeactivate
                    ? (active ? 'Deactivate staff' : 'Activate staff')
                    : policy.deactivateTooltipFor(role!),
                child: DrinkSpotButton(
                  label: active ? 'Deactivate' : 'Activate',
                  icon: active
                      ? Icons.block_rounded
                      : Icons.check_circle_outline_rounded,
                  compact: true,
                  variant: DrinkSpotButtonVariant.secondary,
                  onPressed: canDeactivate ? onToggleActive : null,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Tooltip(
                message: selected == null
                    ? 'Select a staff member first'
                    : canRemove
                    ? 'Remove selected staff member'
                    : policy.removeTooltipFor(role!),
                child: DrinkSpotButton(
                  label: 'Remove Staff Member',
                  icon: Icons.delete_outline_rounded,
                  compact: true,
                  variant: DrinkSpotButtonVariant.ghost,
                  onPressed: canRemove ? onRemove : null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        VenuePageSection(
          title: 'Selected Staff',
          child: selected == null
              ? const Text(
                  'Select a team member to view details and available actions.',
                  style: TextStyle(color: AppColors.textSecondary),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.brandGradient,
                          ),
                          child: Center(
                            child: Text(
                              _staffInitials(selected),
                              style: const TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _staffName(selected),
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                selected.readString(['email']),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _ContextLine(label: 'Role', value: role!.label),
                    _ContextLine(
                      label: 'Role Level',
                      value: '${role.roleLevel}',
                    ),
                    _ContextLine(
                      label: 'Status',
                      value: _staffStatusLabel(selected),
                    ),
                    _ContextLine(label: 'Active', value: active ? 'Yes' : 'No'),
                    _ContextLine(
                      label: 'Last Login',
                      value: _readAdminDate(selected.data, const [
                        'lastLoginAt',
                        'lastLogin',
                        'lastSignInTime',
                      ]),
                    ),
                    _ContextLine(
                      label: 'Created',
                      value: _staffCreatedDate(selected),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'TODO: connect this role hierarchy to the future granular permission framework.',
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.86),
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _StaffDetailsDialog extends StatelessWidget {
  const _StaffDetailsDialog({required this.staff});

  final AdminDocumentRow staff;

  @override
  Widget build(BuildContext context) {
    final role = _StaffRoleDefinition.fromRow(staff);
    final active = _staffActive(staff);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: GlassContainer(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.brandGradient,
                    ),
                    child: Center(
                      child: Text(
                        _staffInitials(staff),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _staffName(staff),
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          staff.readString(['email']),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _StaffRoleChip(role: role),
              const SizedBox(height: AppSpacing.lg),
              _ContextLine(label: 'Role Level', value: '${role.roleLevel}'),
              _ContextLine(label: 'Status', value: _staffStatusLabel(staff)),
              _ContextLine(label: 'Active', value: active ? 'Yes' : 'No'),
              _ContextLine(
                label: _isStaffInviteRow(staff) ? 'Invited' : 'Created',
                value: _staffCreatedDate(staff),
              ),
              _ContextLine(
                label: 'Updated',
                value: _readAdminDate(staff.data, const [
                  'updatedAt',
                  'updated_at',
                ]),
              ),
              _ContextLine(
                label: 'Last Login',
                value: _readAdminDate(staff.data, const [
                  'lastLoginAt',
                  'lastLogin',
                  'lastSignInTime',
                ]),
              ),
              _ContextLine(label: 'Invited By', value: _staffInvitedBy(staff)),
              _ContextLine(label: 'Staff UID', value: staff.id),
              _ContextLine(
                label: 'Assigned Venues',
                value: 'TODO: venue assignment coming soon',
              ),
              _ContextLine(label: 'Notes', value: _staffInternalNotes(staff)),
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: Alignment.centerRight,
                child: DrinkSpotButton(
                  label: 'Close',
                  compact: true,
                  variant: DrinkSpotButtonVariant.secondary,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaffChangeRoleDialog extends StatefulWidget {
  const _StaffChangeRoleDialog({required this.staff, required this.policy});

  final AdminDocumentRow staff;
  final _StaffAccessPolicy policy;

  @override
  State<_StaffChangeRoleDialog> createState() => _StaffChangeRoleDialogState();
}

class _StaffChangeRoleDialogState extends State<_StaffChangeRoleDialog> {
  late _StaffRoleDefinition _role = _StaffRoleDefinition.fromRow(widget.staff);

  @override
  Widget build(BuildContext context) {
    final roles = widget.policy.assignableRoles;
    final allowedValues = roles.map((role) => role.value).toSet();
    final selectedRole = allowedValues.contains(_role.value)
        ? _role
        : roles.isEmpty
        ? _role
        : roles.first;

    return AlertDialog(
      backgroundColor: AppColors.surfaceElevated,
      title: const Text(
        'Change Role',
        style: TextStyle(color: AppColors.white),
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Update role for ${_staffName(widget.staff)}.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: selectedRole.value,
              dropdownColor: AppColors.surfaceElevated,
              decoration: const InputDecoration(labelText: 'Role'),
              items: roles
                  .map(
                    (role) => DropdownMenuItem(
                      value: role.value,
                      child: Text('${role.label} (${role.roleLevel})'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _role = _StaffRoleDefinition.fromValue(value));
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Role and roleLevel will be updated together.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: roles.isEmpty
              ? null
              : () {
                  Navigator.pop(context, _StaffRoleChangeDraft(role: _role));
                },
          child: const Text(
            'Save Role',
            style: TextStyle(
              color: AppColors.primaryPink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _StaffInviteDialog extends StatefulWidget {
  const _StaffInviteDialog({required this.policy});

  final _StaffAccessPolicy policy;

  @override
  State<_StaffInviteDialog> createState() => _StaffInviteDialogState();
}

class _StaffInviteDialogState extends State<_StaffInviteDialog> {
  final _emailController = TextEditingController();
  late _StaffRoleDefinition _role = widget.policy.inviteRoles.first;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roles = widget.policy.inviteRoles;
    return AlertDialog(
      backgroundColor: AppColors.surfaceElevated,
      title: const Text(
        'Invite Staff Member',
        style: TextStyle(color: AppColors.white),
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppColors.white),
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'team@vexda.com',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _role.value,
              dropdownColor: AppColors.surfaceElevated,
              decoration: const InputDecoration(labelText: 'Role'),
              items: roles
                  .map(
                    (role) => DropdownMenuItem(
                      value: role.value,
                      child: Text('${role.label} (${role.roleLevel})'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _role = _StaffRoleDefinition.fromValue(value));
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'TODO: future permission framework will attach granular permissions to this invite.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final email = _emailController.text.trim();
            if (!email.contains('@')) return;
            Navigator.pop(
              context,
              _StaffInviteDraft(email: email, role: _role),
            );
          },
          child: const Text(
            'Invite',
            style: TextStyle(
              color: AppColors.primaryPink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _StaffEditDialog extends StatefulWidget {
  const _StaffEditDialog({required this.staff, required this.policy});

  final AdminDocumentRow staff;
  final _StaffAccessPolicy policy;

  @override
  State<_StaffEditDialog> createState() => _StaffEditDialogState();
}

class _StaffEditDialogState extends State<_StaffEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  late String _status = _staffStatus(widget.staff);
  late bool _active = _staffActive(widget.staff);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _staffName(widget.staff));
    _notesController = TextEditingController(
      text: widget.staff.readString(['internalNotes', 'notes'], fallback: ''),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceElevated,
      title: const Text(
        'Edit Staff Member',
        style: TextStyle(color: AppColors.white),
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(labelText: 'Display name'),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _status,
                dropdownColor: AppColors.surfaceElevated,
                decoration: const InputDecoration(labelText: 'Status'),
                items:
                    const [
                          'active',
                          'disabled',
                          'pending',
                          'invited',
                          'removed',
                        ]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              Material(
                color: Colors.transparent,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _active,
                  onChanged: (value) => setState(() => _active = value),
                  title: const Text(
                    'Active',
                    style: TextStyle(color: AppColors.white),
                  ),
                  subtitle: const Text(
                    'Disable unavailable accounts instead of deleting when possible.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _notesController,
                minLines: 2,
                maxLines: 4,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(
                  labelText: 'Internal notes',
                  hintText: 'Optional internal notes for this staff member',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(
              context,
              _StaffEditDraft(
                name: _nameController.text.trim(),
                status: _status,
                active: _active,
                notes: _notesController.text.trim(),
              ),
            );
          },
          child: const Text(
            'Save',
            style: TextStyle(
              color: AppColors.primaryPink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _StaffRoleChip extends StatelessWidget {
  const _StaffRoleChip({required this.role});

  final _StaffRoleDefinition role;

  @override
  Widget build(BuildContext context) {
    final accent = switch (role.roleLevel) {
      >= 100 => AppColors.trailGold,
      >= 60 => AppColors.primaryPink,
      >= 50 => AppColors.primaryPurple,
      >= 30 => Colors.lightBlueAccent,
      _ => AppColors.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: accent.withValues(alpha: 0.14),
        border: Border.all(color: accent.withValues(alpha: 0.36)),
      ),
      child: Text(
        role.label,
        style: TextStyle(
          color: accent,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return _StatusPill(label: active ? 'Active' : 'Disabled');
  }
}

class _AdminManagementPage extends StatefulWidget {
  const _AdminManagementPage({
    required this.page,
    required this.repository,
    required this.searchController,
    required this.permissions,
  });

  final AdminDashboardPage page;
  final AdminDashboardRepository repository;
  final TextEditingController searchController;
  final PermissionService permissions;

  @override
  State<_AdminManagementPage> createState() => _AdminManagementPageState();
}

class _AdminManagementPageState extends State<_AdminManagementPage> {
  final Set<String> _selectedIds = {};
  String _search = '';
  String _statusFilter = 'All';
  int _pageIndex = 0;
  static const _pageSize = 20;

  @override
  Widget build(BuildContext context) {
    final collectionPath = widget.page.collectionPath;
    if (collectionPath == null) {
      return _TodoPanel(
        title: widget.page.label,
        body:
            'This surface requires backend diagnostics endpoints before live data can be connected.',
      );
    }

    return StreamBuilder<List<AdminDocumentRow>>(
      stream: widget.repository.watchCollection(collectionPath, limit: 250),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const _AdminLoadingPanel();
        }

        final rows = _filterRows(snapshot.data ?? const []);
        final totalPages = rows.isEmpty
            ? 1
            : ((rows.length - 1) ~/ _pageSize) + 1;
        final pageIndex = _pageIndex.clamp(0, totalPages - 1);
        final visibleRows = rows
            .skip(pageIndex * _pageSize)
            .take(_pageSize)
            .toList();

        final canManage = AdminPagePermissions.managePermission(widget.page);
        final canBulkAct =
            canManage != null && widget.permissions.has(canManage);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ManagementToolbar(
              searchController: widget.searchController,
              search: _search,
              statusFilter: _statusFilter,
              selectedCount: _selectedIds.length,
              canBulkAction: canBulkAct,
              onSearchChanged: (value) {
                setState(() {
                  _search = value;
                  _pageIndex = 0;
                });
              },
              onStatusChanged: (value) {
                setState(() {
                  _statusFilter = value;
                  _pageIndex = 0;
                });
              },
              onBulkAction: () => _showTodo(context, 'Bulk actions'),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_selectedIds.isNotEmpty) ...[
              _SelectionBanner(
                count: _selectedIds.length,
                onClear: () => setState(_selectedIds.clear),
                onAction: () => _showTodo(context, 'Bulk moderation'),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            _AdminDataTable(
              page: widget.page,
              rows: visibleRows,
              selectedIds: _selectedIds,
              permissions: widget.permissions,
              onSelectedChanged: (id, selected) {
                setState(() {
                  if (selected) {
                    _selectedIds.add(id);
                  } else {
                    _selectedIds.remove(id);
                  }
                });
              },
              onAction: (row, action) => _showTodo(context, action),
            ),
            const SizedBox(height: AppSpacing.lg),
            _PaginationBar(
              pageIndex: pageIndex,
              totalPages: totalPages,
              visibleCount: visibleRows.length,
              totalCount: rows.length,
              onPrevious: pageIndex == 0
                  ? null
                  : () => setState(() => _pageIndex = pageIndex - 1),
              onNext: pageIndex >= totalPages - 1
                  ? null
                  : () => setState(() => _pageIndex = pageIndex + 1),
            ),
          ],
        );
      },
    );
  }

  List<AdminDocumentRow> _filterRows(List<AdminDocumentRow> rows) {
    final query = _search.trim().toLowerCase();
    return rows.where((row) {
      final deleted = row.data['isDeleted'] == true;
      if (deleted) return false;

      if (_statusFilter != 'All') {
        final status = row.readString([
          'status',
          'claimStatus',
          'moderationStatus',
        ], fallback: '').toLowerCase();
        if (status != _statusFilter.toLowerCase()) return false;
      }

      if (widget.page == AdminDashboardPage.venueClaims) {
        final verified = row.readBool(['isVerified', 'verified']);
        final ownerId = row.readString(['ownerId'], fallback: '');
        if (verified && ownerId.isNotEmpty) return false;
      }

      if (query.isEmpty) return true;
      return row.data.entries.any(
        (entry) => entry.value.toString().toLowerCase().contains(query),
      );
    }).toList()..sort((a, b) {
      final left = a.readString(['createdAt', 'updatedAt', 'name', 'title']);
      final right = b.readString(['createdAt', 'updatedAt', 'name', 'title']);
      return right.compareTo(left);
    });
  }
}

class _AdminDataTable extends StatelessWidget {
  const _AdminDataTable({
    required this.page,
    required this.rows,
    required this.selectedIds,
    required this.permissions,
    required this.onSelectedChanged,
    required this.onAction,
  });

  final AdminDashboardPage page;
  final List<AdminDocumentRow> rows;
  final Set<String> selectedIds;
  final PermissionService permissions;
  final void Function(String id, bool selected) onSelectedChanged;
  final void Function(AdminDocumentRow row, String action) onAction;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return _EmptyState(page: page);
    }

    final columns = _columnsFor(page);

    return VenuePageSection(
      title: '${page.label} Management',
      trailing: Text(
        '${rows.length} shown',
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
          dataTextStyle: const TextStyle(
            color: AppColors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          columns: [
            const DataColumn(label: Text('')),
            for (final column in columns) DataColumn(label: Text(column.label)),
            const DataColumn(label: Text('Actions')),
          ],
          rows: rows.map((row) {
            return DataRow(
              selected: selectedIds.contains(row.id),
              cells: [
                DataCell(
                  Checkbox(
                    value: selectedIds.contains(row.id),
                    onChanged: (selected) {
                      onSelectedChanged(row.id, selected == true);
                    },
                  ),
                ),
                for (final column in columns)
                  DataCell(_AdminCell(row: row, column: column)),
                DataCell(
                  PopupMenuButton<String>(
                    tooltip: 'Actions',
                    color: AppColors.surfaceElevated,
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      color: AppColors.textSecondary,
                    ),
                    onSelected: (action) => onAction(row, action),
                    itemBuilder: (context) => _actionsFor(page).map((action) {
                      final allowed = AdminPagePermissions.canPerformAction(
                        page,
                        action,
                        permissions,
                      );
                      return PopupMenuItem<String>(
                        value: action,
                        enabled: allowed,
                        child: Tooltip(
                          message: allowed
                              ? action
                              : kAdminPermissionDeniedTooltip,
                          child: Text(
                            allowed
                                ? action
                                : '$action — $kAdminPermissionDeniedTooltip',
                            style: TextStyle(
                              color: allowed
                                  ? AppColors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _AdminMapPage extends StatefulWidget {
  const _AdminMapPage({
    required this.repository,
    required this.permissions,
    this.focusVenueId,
    this.onFocusHandled,
  });

  final AdminDashboardRepository repository;
  final PermissionService permissions;
  final String? focusVenueId;
  final VoidCallback? onFocusHandled;

  @override
  State<_AdminMapPage> createState() => _AdminMapPageState();
}

class _AdminMapPageState extends State<_AdminMapPage> {
  final _repository = AdminClaimVenueRepository();
  final _searchController = TextEditingController();
  late final Future<AdminClaimVenueLoadResult> _loadFuture = _repository
      .loadClaimVenues();

  AdminClaimVenue? _selectedVenue;
  String _search = '';
  bool _focusAttempted = false;

  @override
  void didUpdateWidget(covariant _AdminMapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusVenueId != widget.focusVenueId) {
      _focusAttempted = false;
    }
  }

  /// Attempts to select a venue on the claim directory map by venues doc id.
  ///
  /// TODO(map): Cross-reference venues/{id} with claim directory when ids differ.
  void _attemptVenueFocus(List<AdminClaimVenue> venues, BuildContext context) {
    final focusId = widget.focusVenueId;
    if (focusId == null || _focusAttempted) return;

    _focusAttempted = true;
    widget.onFocusHandled?.call();

    AdminClaimVenue? match;
    for (final venue in venues) {
      if (venue.id == focusId) {
        match = venue;
        break;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (match != null) {
        setState(() => _selectedVenue = match);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Map focus will be added in a later pass.'),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.permissions.has(StaffPermission.adminMapView)) {
      return const AdminAccessRestrictedCard(pageTitle: 'Admin Map');
    }

    return FutureBuilder<AdminClaimVenueLoadResult>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const _AdminLoadingPanel();
        }

        if (snapshot.hasError) {
          return _TodoPanel(
            title: 'Claim directory unavailable',
            body: 'Could not load venue_claim_directory. ${snapshot.error}',
          );
        }

        final result =
            snapshot.data ??
            const AdminClaimVenueLoadResult(
              venues: [],
              totalRecords: 0,
              mappedRecords: 0,
              missingCoordinates: 0,
            );
        final venues = result.venues;
        final filteredVenues = _filteredVenues(venues);
        _attemptVenueFocus(venues, context);
        final selectedVenue =
            _selectedVenue != null &&
                filteredVenues.any((venue) => venue.id == _selectedVenue!.id)
            ? _selectedVenue
            : null;
        final viewportHeight = MediaQuery.sizeOf(context).height;
        final mapHeight =
            (viewportHeight - VenueDashboardLayout.topBarHeight - 116).clamp(
              640.0,
              980.0,
            );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AdminMapCommandBar(
              totalRecords: result.totalRecords,
              searchController: _searchController,
              onSearchChanged: (value) => setState(() => _search = value),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: mapHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: AdminClaimVenueMap(
                        venues: filteredVenues,
                        selectedVenue: selectedVenue,
                        padding: const EdgeInsets.only(
                          left: 20,
                          top: 20,
                          bottom: 92,
                        ).copyWith(right: selectedVenue == null ? 20 : 390),
                        onVenueSelected: (venue) {
                          setState(() => _selectedVenue = venue);
                        },
                      ),
                    ),
                    Positioned(
                      left: AppSpacing.lg,
                      top: AppSpacing.lg,
                      child: _AdminMapResultBadge(
                        filteredCount: filteredVenues.length,
                        totalRecords: result.totalRecords,
                      ),
                    ),
                    Positioned(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      bottom: AppSpacing.lg,
                      child: _AdminMapStatusBar(
                        mappedVenues: result.mappedRecords,
                        usersStream: widget.repository.watchCollectionCount(
                          'users',
                        ),
                        claimsStream: widget.repository
                            .watchPendingVenueReviewCount(),
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        ignoring: selectedVenue == null,
                        child: AnimatedOpacity(
                          opacity: selectedVenue == null ? 0 : 1,
                          duration: const Duration(milliseconds: 180),
                          curve: PremiumEffects.easeOut,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: _AdminMapVenueDrawer(
                              venue: selectedVenue,
                              permissions: widget.permissions,
                              onClose: () {
                                setState(() => _selectedVenue = null);
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<AdminClaimVenue> _filteredVenues(List<AdminClaimVenue> venues) {
    final query = _search.trim().toLowerCase();
    if (query.isEmpty) return venues;

    return venues
        .where((venue) {
          return _searchableText(venue).contains(query);
        })
        .toList(growable: false);
  }

  String _searchableText(AdminClaimVenue venue) {
    return [
      venue.name,
      venue.city,
      venue.postcode,
      venue.category,
      venue.claimStatus,
      _readRawString(venue.rawData, const [
        'osmId',
        'osm_id',
        'osmid',
        'openStreetMapId',
        'placeId',
        'sourceId',
      ]),
    ].join(' ').toLowerCase();
  }
}

class _AdminMapCommandBar extends StatelessWidget {
  const _AdminMapCommandBar({
    required this.totalRecords,
    required this.searchController,
    required this.onSearchChanged,
  });

  final int totalRecords;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final compact = Breakpoints.isMobile(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.56),
            border: Border.all(
              color: AppColors.primaryPurple.withValues(alpha: 0.16),
            ),
            boxShadow: PremiumEffects.softCardShadow(intensity: 0.65),
          ),
          child: Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: compact ? double.infinity : 280,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Admin Map',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_formatNumber(totalRecords)} Claim Venues',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: compact ? double.infinity : 420,
                child: _AdminMapSearchField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                ),
              ),
              DrinkSpotButton(
                label: 'Export CSV',
                icon: Icons.download_rounded,
                compact: true,
                variant: DrinkSpotButtonVariant.secondary,
                onPressed: () => _showTodo(context, 'Export CSV'),
              ),
              DrinkSpotButton(
                label: 'Export Map',
                icon: Icons.ios_share_rounded,
                compact: true,
                onPressed: () => _showTodo(context, 'Export map view'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminMapSearchField extends StatelessWidget {
  const _AdminMapSearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(
        color: AppColors.white,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: 'Search name, city, postcode, category, status, OSM ID...',
        hintStyle: TextStyle(
          color: AppColors.textSecondary.withValues(alpha: 0.78),
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: AppColors.background.withValues(alpha: 0.54),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(
            color: AppColors.primaryPurple.withValues(alpha: 0.18),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(
            color: AppColors.primaryPurple.withValues(alpha: 0.18),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(
            color: AppColors.primaryPink.withValues(alpha: 0.68),
          ),
        ),
      ),
    );
  }
}

class _AdminMapResultBadge extends StatelessWidget {
  const _AdminMapResultBadge({
    required this.filteredCount,
    required this.totalRecords,
  });

  final int filteredCount;
  final int totalRecords;

  @override
  Widget build(BuildContext context) {
    return _FrostedMapPanel(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.brandGradient,
              boxShadow: PremiumEffects.hoverGlow(intensity: 0.45),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: AppColors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Visible Venues',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${_formatNumber(filteredCount)} / ${_formatNumber(totalRecords)}',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminMapStatusBar extends StatelessWidget {
  const _AdminMapStatusBar({
    required this.mappedVenues,
    required this.usersStream,
    required this.claimsStream,
  });

  final int mappedVenues;
  final Stream<int> usersStream;
  final Stream<int> claimsStream;

  @override
  Widget build(BuildContext context) {
    return _FrostedMapPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Wrap(
        spacing: AppSpacing.xl,
        runSpacing: AppSpacing.md,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _AdminMapStatusMetric(
            icon: Icons.pin_drop_rounded,
            label: 'Mapped Venues',
            value: _formatNumber(mappedVenues),
          ),
          _LiveAdminMapStatusMetric(
            icon: Icons.people_alt_rounded,
            label: 'Users',
            stream: usersStream,
          ),
          _LiveAdminMapStatusMetric(
            icon: Icons.fact_check_rounded,
            label: 'Claims',
            stream: claimsStream,
          ),
          const _AdminMapStatusMetric(
            icon: Icons.bolt_rounded,
            label: 'Last Sync',
            value: 'Live',
          ),
        ],
      ),
    );
  }
}

class _LiveAdminMapStatusMetric extends StatelessWidget {
  const _LiveAdminMapStatusMetric({
    required this.icon,
    required this.label,
    required this.stream,
  });

  final IconData icon;
  final String label;
  final Stream<int> stream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snapshot) {
        return _AdminMapStatusMetric(
          icon: icon,
          label: label,
          value: snapshot.data == null ? '...' : _formatNumber(snapshot.data!),
        );
      },
    );
  }
}

class _AdminMapStatusMetric extends StatelessWidget {
  const _AdminMapStatusMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryPurple.withValues(alpha: 0.2),
              border: Border.all(
                color: AppColors.primaryPink.withValues(alpha: 0.22),
              ),
            ),
            child: Icon(icon, color: AppColors.primaryPink, size: 19),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FrostedMapPanel extends StatelessWidget {
  const _FrostedMapPanel({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.58),
            border: Border.all(
              color: AppColors.primaryPurple.withValues(alpha: 0.18),
            ),
            boxShadow: PremiumEffects.softCardShadow(intensity: 0.55),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _AdminAnalyticsPage extends StatelessWidget {
  const _AdminAnalyticsPage({
    required this.page,
    required this.repository,
    required this.permissions,
  });

  final AdminDashboardPage page;
  final AdminDashboardRepository repository;
  final PermissionService permissions;

  @override
  Widget build(BuildContext context) {
    final canViewAdvanced = permissions.has(StaffPermission.analyticsAdvanced);
    final canViewBasic = permissions.has(StaffPermission.analyticsView);

    if (!canViewBasic && !canViewAdvanced) {
      return AdminAccessRestrictedCard(pageTitle: page.label);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canViewBasic) _GrowthGraphCard(repository: repository),
        if (canViewBasic) const SizedBox(height: AppSpacing.lg),
        if (canViewAdvanced)
          _TodoPanel(
            title: page.label,
            body:
                'Live records are read from ${page.collectionPath ?? 'existing platform collections'}. TODO: wire monthly export jobs and revenue aggregation once backend reporting endpoints exist.',
          )
        else if (canViewBasic)
          VenuePageSection(
            title: 'Advanced analytics',
            child: Tooltip(
              message: kAdminPermissionDeniedTooltip,
              child: Text(
                'Revenue aggregation and advanced exports require elevated analytics permissions.',
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.85),
                  height: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DeveloperPage extends StatelessWidget {
  const _DeveloperPage({required this.repository, required this.permissions});

  final AdminDashboardRepository repository;
  final PermissionService permissions;

  @override
  Widget build(BuildContext context) {
    if (!permissions.has(StaffPermission.systemMonitoringView)) {
      return const AdminAccessRestrictedCard(pageTitle: 'Developer');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TodoPanel(
          title: 'Developer Tools',
          body:
              'Database explorer, Storage explorer, Firebase diagnostics, background jobs and system information. TODO: wire write/debug tools once backend endpoints exist.',
        ),
        const SizedBox(height: AppSpacing.lg),
        _AdminManagementPage(
          page: AdminDashboardPage.systemHealth,
          repository: repository,
          searchController: TextEditingController(),
          permissions: permissions,
        ),
      ],
    );
  }
}

class _AdminRightColumn extends StatelessWidget {
  const _AdminRightColumn({
    required this.page,
    required this.repository,
    required this.permissions,
  });

  final AdminDashboardPage page;
  final AdminDashboardRepository repository;
  final PermissionService permissions;

  @override
  Widget build(BuildContext context) {
    final canReviewQueue = permissions.hasAny([
      StaffPermission.venueClaimsView,
      StaffPermission.reportsModerate,
    ]);
    final managePermission = AdminPagePermissions.managePermission(page);
    final canExport =
        managePermission != null && permissions.has(managePermission);
    final canBroadcast = permissions.has(
      StaffPermission.platformNotificationsManage,
    );

    return SizedBox(
      width: Breakpoints.isDesktop(context)
          ? VenueDashboardLayout.rightColumnWidth
          : double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VenuePageSection(
            title: 'Quick Actions',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Tooltip(
                  message: canReviewQueue
                      ? 'Review queue'
                      : kAdminPermissionDeniedTooltip,
                  child: DrinkSpotButton(
                    label: 'Review Queue',
                    icon: Icons.fact_check_rounded,
                    compact: true,
                    onPressed: canReviewQueue
                        ? () => _showTodo(context, 'Review queue')
                        : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Tooltip(
                  message: canExport
                      ? 'Export CSV'
                      : kAdminPermissionDeniedTooltip,
                  child: DrinkSpotButton(
                    label: 'Export CSV',
                    icon: Icons.download_rounded,
                    compact: true,
                    variant: DrinkSpotButtonVariant.secondary,
                    onPressed: canExport
                        ? () => _showTodo(context, 'CSV export')
                        : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Tooltip(
                  message: canBroadcast
                      ? 'Broadcast notifications'
                      : kAdminPermissionDeniedTooltip,
                  child: DrinkSpotButton(
                    label: 'Broadcast',
                    icon: Icons.campaign_rounded,
                    compact: true,
                    variant: DrinkSpotButtonVariant.ghost,
                    onPressed: canBroadcast
                        ? () => _showTodo(context, 'Broadcast notifications')
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          VenuePageSection(
            title: 'Context',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ContextLine(label: 'Section', value: page.section),
                _ContextLine(label: 'Page', value: page.label),
                _ContextLine(
                  label: 'Source',
                  value: page.collectionPath ?? 'Composite',
                ),
                _ContextLine(
                  label: 'Access',
                  value: AdminPagePermissions.accessLabel(page, permissions),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          VenuePageSection(
            title: 'Live Snapshot',
            child: Column(
              children: [
                _CompactCount(
                  label: 'Venues',
                  stream: repository.watchCollectionCount('venues'),
                ),
                _CompactCount(
                  label: 'Users',
                  stream: repository.watchCollectionCount('users'),
                ),
                _CompactCount(
                  label: 'Claims',
                  stream: repository.watchPendingVenueReviewCount(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveMetricCard extends StatelessWidget {
  const _LiveMetricCard({
    required this.width,
    required this.label,
    required this.icon,
    required this.stream,
    this.valuePrefix = '',
  });

  final double width;
  final String label;
  final IconData icon;
  final Stream<int> stream;
  final String valuePrefix;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: GlassContainer(
        padding: const EdgeInsets.all(AppSpacing.lg),
        borderRadius: AppSpacing.radiusLg,
        elevation: GlassElevation.soft,
        innerHighlight: true,
        interactiveHover: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primaryPink, size: 24),
            const SizedBox(height: AppSpacing.lg),
            StreamBuilder<int>(
              stream: stream,
              builder: (context, snapshot) {
                final value = snapshot.data;
                return Text(
                  value == null ? '…' : '$valuePrefix$value',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrowthGraphCard extends StatelessWidget {
  const _GrowthGraphCard({required this.repository});

  final AdminDashboardRepository repository;

  @override
  Widget build(BuildContext context) {
    return VenuePageSection(
      title: 'Growth Graphs',
      child: SizedBox(
        height: 240,
        child: CustomPaint(
          painter: _AdminGraphPainter(),
          child: const Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              'Users · Venues · Revenue · Searches',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LatestActivityCard extends StatelessWidget {
  const _LatestActivityCard({required this.repository});

  final AdminDashboardRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AdminDocumentRow>>(
      stream: repository.watchCollection('venues', limit: 6),
      builder: (context, snapshot) {
        final rows = snapshot.data ?? const [];
        return VenuePageSection(
          title: 'Latest Platform Activity',
          child: Column(
            children: [
              for (final row in rows)
                _ActivityRow(
                  title: row.readString([
                    'name',
                    'venueName',
                  ], fallback: row.id),
                  subtitle: row.readString([
                    'category',
                    'city',
                  ], fallback: 'Venue update'),
                ),
              if (rows.isEmpty)
                const Text(
                  'No recent activity available yet.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminCell extends StatelessWidget {
  const _AdminCell({required this.row, required this.column});

  final AdminDocumentRow row;
  final _AdminColumn column;

  @override
  Widget build(BuildContext context) {
    if (column.kind == _AdminColumnKind.image) {
      final url = row.readString(column.keys, fallback: '');
      if (url.isEmpty || !url.startsWith('http')) {
        return const Icon(Icons.image_not_supported_outlined, size: 18);
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Image.network(
          url,
          width: column.label == 'Logo' ? 34 : 58,
          height: 34,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image_outlined, size: 18),
        ),
      );
    }

    if (column.kind == _AdminColumnKind.status) {
      return _StatusPill(label: row.readString(column.keys));
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 180),
      child: Text(
        row.readString(column.keys),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _AdminMapVenueDrawer extends StatelessWidget {
  const _AdminMapVenueDrawer({
    required this.venue,
    required this.permissions,
    required this.onClose,
  });

  final AdminClaimVenue? venue;
  final PermissionService permissions;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final selected = venue;
    final visible = selected != null;

    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(1.05, 0),
      duration: const Duration(milliseconds: 280),
      curve: PremiumEffects.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: PremiumEffects.easeOut,
        width: 360,
        margin: const EdgeInsets.only(
          top: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: AppSpacing.xxl,
        ),
        child: selected == null
            ? const SizedBox.shrink()
            : ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.72),
                      border: Border.all(
                        color: AppColors.primaryPurple.withValues(alpha: 0.22),
                      ),
                      boxShadow: PremiumEffects.hoverGlow(intensity: 0.22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _AdminMapVenueHero(venue: selected, onClose: onClose),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        selected.name,
                                        style: const TextStyle(
                                          color: AppColors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.35,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    _StatusPill(label: selected.claimStatus),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  selected.category,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                _AdminDrawerLine(
                                  label: 'Address',
                                  value: selected.address,
                                ),
                                _AdminDrawerLine(
                                  label: 'City',
                                  value: selected.city,
                                ),
                                _AdminDrawerLine(
                                  label: 'Postcode',
                                  value: selected.postcode,
                                ),
                                _AdminDrawerLine(
                                  label: 'Phone',
                                  value:
                                      _readRawString(selected.rawData, const [
                                        'phone',
                                        'phoneNumber',
                                        'telephone',
                                        'contactPhone',
                                      ]),
                                ),
                                _AdminDrawerLine(
                                  label: 'Website',
                                  value: _readRawString(
                                    selected.rawData,
                                    const [
                                      'website',
                                      'websiteUrl',
                                      'url',
                                      'businessUrl',
                                    ],
                                  ),
                                ),
                                _AdminDrawerLine(
                                  label: 'Source',
                                  value: _readRawString(
                                    selected.rawData,
                                    const [
                                      'source',
                                      'sourceName',
                                      'sourceLayer',
                                      'provider',
                                    ],
                                  ),
                                ),
                                _AdminDrawerLine(
                                  label: 'Created',
                                  value: _readRawDate(selected.rawData, const [
                                    'createdAt',
                                    'created',
                                    'created_at',
                                  ]),
                                ),
                                _AdminDrawerLine(
                                  label: 'Updated',
                                  value: _readRawDate(selected.rawData, const [
                                    'updatedAt',
                                    'updated',
                                    'updated_at',
                                  ]),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                Tooltip(
                                  message:
                                      permissions.has(
                                        StaffPermission.venueClaimsView,
                                      )
                                      ? 'Open claim record'
                                      : kAdminPermissionDeniedTooltip,
                                  child: DrinkSpotButton(
                                    label: 'Open Claim Record',
                                    icon: Icons.open_in_new_rounded,
                                    compact: true,
                                    onPressed:
                                        permissions.has(
                                          StaffPermission.venueClaimsView,
                                        )
                                        ? () => _showTodo(
                                            context,
                                            'Open claim record',
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Tooltip(
                                  message:
                                      permissions.has(
                                        StaffPermission.venueClaimAssign,
                                      )
                                      ? 'Assign admin'
                                      : kAdminPermissionDeniedTooltip,
                                  child: DrinkSpotButton(
                                    label: 'Assign Admin',
                                    icon: Icons.assignment_ind_rounded,
                                    compact: true,
                                    variant: DrinkSpotButtonVariant.secondary,
                                    onPressed:
                                        permissions.has(
                                          StaffPermission.venueClaimAssign,
                                        )
                                        ? () =>
                                              _showTodo(context, 'Assign admin')
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Tooltip(
                                  message:
                                      permissions.has(
                                        StaffPermission.venueClaimApprove,
                                      )
                                      ? 'Mark needs review'
                                      : kAdminPermissionDeniedTooltip,
                                  child: DrinkSpotButton(
                                    label: 'Mark Needs Review',
                                    icon: Icons.flag_rounded,
                                    compact: true,
                                    variant: DrinkSpotButtonVariant.secondary,
                                    onPressed:
                                        permissions.has(
                                          StaffPermission.venueClaimApprove,
                                        )
                                        ? () => _showTodo(
                                            context,
                                            'Mark as needs review',
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                DrinkSpotButton(
                                  label: 'Close',
                                  icon: Icons.close_rounded,
                                  compact: true,
                                  variant: DrinkSpotButtonVariant.ghost,
                                  onPressed: onClose,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _AdminMapVenueHero extends StatelessWidget {
  const _AdminMapVenueHero({required this.venue, required this.onClose});

  final AdminClaimVenue venue;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final imageUrl = _readRawString(venue.rawData, const [
      'bannerImageUrl',
      'bannerUrl',
      'imageUrl',
      'photoUrl',
      'coverImageUrl',
      'thumbnailUrl',
    ], fallback: '');

    return SizedBox(
      height: 156,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl.startsWith('http'))
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const _AdminMapHeroFallback(),
            )
          else
            const _AdminMapHeroFallback(),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
          Positioned(
            right: AppSpacing.md,
            top: AppSpacing.md,
            child: _AdminIconButton(
              icon: Icons.close_rounded,
              tooltip: 'Close venue details',
              onPressed: onClose,
            ),
          ),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: Text(
              venue.locationLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
                shadows: [Shadow(color: Colors.black, blurRadius: 14)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminMapHeroFallback extends StatelessWidget {
  const _AdminMapHeroFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPurple.withValues(alpha: 0.9),
            AppColors.primaryPink.withValues(alpha: 0.72),
            AppColors.background,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.storefront_rounded,
          color: AppColors.white.withValues(alpha: 0.78),
          size: 46,
        ),
      ),
    );
  }
}

class _AdminDrawerLine extends StatelessWidget {
  const _AdminDrawerLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final resolved = value.trim().isEmpty ? '—' : value.trim();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.white.withValues(alpha: 0.055)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              resolved,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _readRawString(
  Map<String, dynamic> data,
  List<String> keys, {
  String fallback = '—',
}) {
  for (final key in keys) {
    final value = data[key];
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty) return text;
  }
  return fallback;
}

String _readRawDate(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value is Timestamp) return _formatDateTime(value.toDate());
    if (value is DateTime) return _formatDateTime(value);
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty) return text;
  }
  return '—';
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/'
      '${local.year} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

String _formatNumber(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final remaining = text.length - i;
    buffer.write(text[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

class _ManagementToolbar extends StatelessWidget {
  const _ManagementToolbar({
    required this.searchController,
    required this.search,
    required this.statusFilter,
    required this.selectedCount,
    required this.canBulkAction,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onBulkAction,
  });

  final TextEditingController searchController;
  final String search;
  final String statusFilter;
  final int selectedCount;
  final bool canBulkAction;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onBulkAction;

  @override
  Widget build(BuildContext context) {
    return VenuePageSection(
      title: 'Search, Filters & Bulk Actions',
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 320,
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: const TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                hintText: 'Search records',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppColors.surfaceElevated.withValues(alpha: 0.78),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
          ),
          _MiniDropdown(
            label: 'Status',
            value: statusFilter,
            values: const [
              'All',
              'active',
              'pending',
              'approved',
              'rejected',
              'archived',
            ],
            onChanged: onStatusChanged,
          ),
          Tooltip(
            message: canBulkAction
                ? 'Bulk actions'
                : kAdminPermissionDeniedTooltip,
            child: DrinkSpotButton(
              label: selectedCount == 0
                  ? 'Bulk Actions'
                  : 'Bulk Actions ($selectedCount)',
              icon: Icons.checklist_rounded,
              compact: true,
              variant: DrinkSpotButtonVariant.secondary,
              onPressed: !canBulkAction || selectedCount == 0
                  ? null
                  : onBulkAction,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniDropdown extends StatelessWidget {
  const _MiniDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        dropdownColor: AppColors.surfaceElevated,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.surfaceElevated.withValues(alpha: 0.78),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
        items: values
            .map((value) => DropdownMenuItem(value: value, child: Text(value)))
            .toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}

class _SelectionBanner extends StatelessWidget {
  const _SelectionBanner({
    required this.count,
    required this.onClear,
    required this.onAction,
  });

  final int count;
  final VoidCallback onClear;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppSpacing.radiusLg,
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$count selected',
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(onPressed: onClear, child: const Text('Clear')),
          const SizedBox(width: AppSpacing.sm),
          DrinkSpotButton(
            label: 'Apply Action',
            compact: true,
            onPressed: onAction,
          ),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.pageIndex,
    required this.totalPages,
    required this.visibleCount,
    required this.totalCount,
    required this.onPrevious,
    required this.onNext,
  });

  final int pageIndex;
  final int totalPages;
  final int visibleCount;
  final int totalCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Showing $visibleCount of $totalCount · Page ${pageIndex + 1} of $totalPages',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        DrinkSpotButton(
          label: 'Previous',
          compact: true,
          variant: DrinkSpotButtonVariant.ghost,
          onPressed: onPrevious,
        ),
        const SizedBox(width: AppSpacing.sm),
        DrinkSpotButton(
          label: 'Next',
          compact: true,
          variant: DrinkSpotButtonVariant.secondary,
          onPressed: onNext,
        ),
      ],
    );
  }
}

class _AdminSidebarHeader extends StatelessWidget {
  const _AdminSidebarHeader({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: EdgeInsets.all(expanded ? AppSpacing.md : AppSpacing.sm),
      borderRadius: AppSpacing.radiusLg,
      innerHighlight: true,
      child: expanded
          ? StreamBuilder<UserRoleProfile>(
              stream: UserRoleService.currentUserProfileStream(),
              builder: (context, snapshot) {
                final uid = AuthService.currentUser?.uid;
                final profile =
                    snapshot.data ??
                    (uid != null
                        ? UserRoleService.peekCachedProfile(uid)
                        : null);
                final staffRole = StaffRole.fromLevel(profile?.roleLevel ?? 0);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vexda Platform',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _AdminStaffRoleBadge(role: staffRole),
                  ],
                );
              },
            )
          : const Icon(
              Icons.admin_panel_settings_rounded,
              color: AppColors.white,
            ),
    );
  }
}

class _AdminStaffRoleBadge extends StatelessWidget {
  const _AdminStaffRoleBadge({required this.role});

  final StaffRole role;

  @override
  Widget build(BuildContext context) {
    final accent = _staffRoleAccent(role);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: accent.withValues(alpha: 0.14),
        border: Border.all(color: accent.withValues(alpha: 0.36)),
      ),
      child: Text(
        _staffRoleLabel(role),
        style: TextStyle(
          color: accent,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AdminSectionLabel extends StatelessWidget {
  const _AdminSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.xs,
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: AppColors.textSecondary.withValues(alpha: 0.72),
          fontWeight: FontWeight.w800,
          fontSize: 10.5,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _AdminNavItem extends StatefulWidget {
  const _AdminNavItem({
    required this.page,
    required this.expanded,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final AdminDashboardPage page;
  final bool expanded;
  final bool selected;
  final bool locked;
  final VoidCallback? onTap;

  @override
  State<_AdminNavItem> createState() => _AdminNavItemState();
}

class _AdminNavItemState extends State<_AdminNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.selected || (_hovered && !widget.locked);
    final icon = widget.selected ? widget.page.selectedIcon : widget.page.icon;
    final tooltipMessage = widget.locked
        ? kAdminPermissionDeniedTooltip
        : widget.page.label;

    final item = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.locked
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: PremiumEffects.fast,
          curve: PremiumEffects.easeOut,
          height: VenueDashboardLayout.navItemHeight,
          margin: const EdgeInsets.only(bottom: AppSpacing.xs + 2),
          padding: EdgeInsets.symmetric(
            horizontal: widget.expanded ? AppSpacing.md : 0,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            gradient: widget.selected ? AppColors.brandGradient : null,
            color: widget.selected
                ? null
                : _hovered && !widget.locked
                ? AppColors.primaryPurple.withValues(alpha: 0.14)
                : Colors.transparent,
            border: widget.selected
                ? null
                : Border.all(
                    color: _hovered && !widget.locked
                        ? AppColors.primaryPurple.withValues(alpha: 0.24)
                        : Colors.transparent,
                  ),
            boxShadow: widget.selected ? PremiumEffects.activeNavGlow() : null,
          ),
          child: widget.expanded
              ? Row(
                  children: [
                    Icon(
                      icon,
                      size: 21,
                      color: highlighted
                          ? AppColors.white
                          : widget.locked
                          ? AppColors.textSecondary.withValues(alpha: 0.55)
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        widget.page.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: highlighted
                              ? AppColors.white
                              : widget.locked
                              ? AppColors.textSecondary.withValues(alpha: 0.55)
                              : AppColors.textSecondary,
                          fontWeight: widget.selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    if (widget.locked)
                      Icon(
                        Icons.lock_rounded,
                        size: 14,
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                      ),
                  ],
                )
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color: highlighted
                          ? AppColors.white
                          : widget.locked
                          ? AppColors.textSecondary.withValues(alpha: 0.55)
                          : AppColors.textSecondary,
                    ),
                    if (widget.locked)
                      Positioned(
                        right: 6,
                        bottom: 8,
                        child: Icon(
                          Icons.lock_rounded,
                          size: 10,
                          color: AppColors.trailGold.withValues(alpha: 0.9),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );

    return Tooltip(message: tooltipMessage, preferBelow: false, child: item);
  }
}

class _AdminIconButton extends StatefulWidget {
  const _AdminIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  State<_AdminIconButton> createState() => _AdminIconButtonState();
}

class _AdminIconButtonState extends State<_AdminIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _hovered ? AppColors.brandGradient : null,
              color: _hovered
                  ? null
                  : AppColors.surface.withValues(alpha: 0.55),
              border: Border.all(
                color: _hovered
                    ? Colors.transparent
                    : AppColors.primaryPurple.withValues(alpha: 0.28),
              ),
              boxShadow: _hovered
                  ? PremiumEffects.hoverGlow(intensity: 0.45)
                  : null,
            ),
            child: Icon(widget.icon, color: AppColors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final normalized = label.toLowerCase();
    final accent = normalized.contains('removed')
        ? AppColors.textSecondary
        : normalized.contains('expired')
        ? Colors.orangeAccent
        : normalized.contains('accepted') ||
              normalized.contains('approved') ||
              (normalized.contains('active') &&
                  !normalized.contains('inactive'))
        ? AppColors.primaryPink
        : normalized.contains('pending') || normalized.contains('invited')
        ? AppColors.trailGold
        : normalized.contains('disabled')
        ? AppColors.primaryPurple
        : AppColors.primaryPurple;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: accent.withValues(alpha: 0.14),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ContextLine extends StatelessWidget {
  const _ContextLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactCount extends StatelessWidget {
  const _CompactCount({required this.label, required this.stream});

  final String label;
  final Stream<int> stream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snapshot) {
        final value = snapshot.data;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
              Text(
                value?.toString() ?? '…',
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.brandGradient,
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: AppColors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodoPanel extends StatelessWidget {
  const _TodoPanel({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return VenuePageSection(
      title: title,
      child: Text(
        body,
        style: const TextStyle(color: AppColors.textSecondary, height: 1.55),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.page});

  final AdminDashboardPage page;

  @override
  Widget build(BuildContext context) {
    return VenuePageSection(
      title: 'No records yet',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(page.icon, color: AppColors.primaryPurple, size: 32),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No ${page.label.toLowerCase()} records were found in ${page.collectionPath ?? 'the configured source'}.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminLoadingPanel extends StatelessWidget {
  const _AdminLoadingPanel();

  @override
  Widget build(BuildContext context) {
    return const VenuePageSection(
      title: 'Loading records',
      child: LinearProgressIndicator(
        color: AppColors.primaryPink,
        backgroundColor: AppColors.surfaceElevated,
      ),
    );
  }
}

class _AdminColumn {
  const _AdminColumn(
    this.label,
    this.keys, {
    this.kind = _AdminColumnKind.text,
  });

  final String label;
  final List<String> keys;
  final _AdminColumnKind kind;
}

enum _AdminColumnKind { text, image, status }

List<_AdminColumn> _columnsFor(AdminDashboardPage page) {
  if (page == AdminDashboardPage.venues) {
    return const [
      _AdminColumn('Banner', [
        'bannerImageUrl',
        'bannerUrl',
        'coverImageUrl',
      ], kind: _AdminColumnKind.image),
      _AdminColumn('Logo', [
        'logoUrl',
        'logoImageUrl',
        'venueLogoUrl',
      ], kind: _AdminColumnKind.image),
      _AdminColumn('Venue', ['name', 'venueName']),
      _AdminColumn('Category', ['category', 'venueType']),
      _AdminColumn('City', ['city', 'area']),
      _AdminColumn('Owner', ['ownerId', 'ownerName']),
      _AdminColumn('Subscription', [
        'subscriptionPlan',
        'subscriptionPlanId',
        'plan',
      ]),
      _AdminColumn('Claim Status', [
        'claimStatus',
        'claimedStatus',
      ], kind: _AdminColumnKind.status),
      _AdminColumn('Status', [
        'status',
        'moderationStatus',
      ], kind: _AdminColumnKind.status),
      _AdminColumn('Created', ['createdAt', 'created_at']),
    ];
  }

  return const [
    _AdminColumn('Name / Title', [
      'name',
      'title',
      'venueName',
      'displayName',
      'email',
    ]),
    _AdminColumn('Type', ['category', 'type', 'role', 'accountType']),
    _AdminColumn('Venue', ['venueName', 'venueId']),
    _AdminColumn('Status', [
      'status',
      'claimStatus',
      'moderationStatus',
      'isActive',
    ], kind: _AdminColumnKind.status),
    _AdminColumn('Owner / User', ['ownerId', 'userId', 'createdBy', 'email']),
    _AdminColumn('Created', ['createdAt', 'created_at']),
  ];
}

List<String> _actionsFor(AdminDashboardPage page) {
  return switch (page) {
    AdminDashboardPage.venueClaims => const [
      'Approve',
      'Reject',
      'Request more information',
      'Assign reviewer',
      'Open venue profile',
    ],
    AdminDashboardPage.users => const [
      'Suspend',
      'Unsuspend',
      'Ban',
      'Change role',
      'View user',
    ],
    AdminDashboardPage.teamMembers => const [
      'Invite',
      'Change permissions',
      'Remove',
    ],
    AdminDashboardPage.drinks => const [
      'Merge duplicate',
      'Delete inappropriate',
      'Open venue',
    ],
    AdminDashboardPage.deals => const [
      'Feature',
      'Archive',
      'Delete',
      'Moderate',
    ],
    AdminDashboardPage.events => const [
      'Feature',
      'Archive',
      'Publish',
      'Moderate',
    ],
    AdminDashboardPage.trails => const [
      'Publish',
      'Archive',
      'Analytics',
      'Moderate',
    ],
    AdminDashboardPage.reviews || AdminDashboardPage.photos => const [
      'Approve',
      'Remove',
      'Restore',
      'Open appeal',
    ],
    AdminDashboardPage.subscriptions => const [
      'View subscription',
      'Override subscription',
      'Upgrade',
      'Downgrade',
      'History',
    ],
    AdminDashboardPage.payments => const [
      'Open invoice',
      'Refund',
      'View history',
    ],
    _ => const ['Open', 'Edit', 'Archive', 'View history'],
  };
}

String _staffName(AdminDocumentRow row) {
  if (_isStaffInviteRow(row)) {
    final name = row.readString([
      'name',
      'displayName',
      'fullName',
    ], fallback: '');
    if (name.isNotEmpty && name != '—') return name;
    final email = row.readString(['email'], fallback: '');
    if (email.isNotEmpty && email != '—') return email;
    return 'Invited staff member';
  }

  return row.readString([
    'name',
    'displayName',
    'fullName',
    'email',
  ], fallback: 'Unnamed staff member');
}

bool _isStaffInviteRow(AdminDocumentRow row) {
  return row.path.startsWith('staff_invites/');
}

String _staffCreatedDate(AdminDocumentRow row) {
  if (_isStaffInviteRow(row)) {
    return _readAdminDate(row.data, const [
      'invitedAt',
      'invited_at',
      'createdAt',
      'created_at',
    ]);
  }
  return _readAdminDate(row.data, const ['createdAt', 'created_at']);
}

String _teamMembersLoadErrorBody(Object? error) {
  if (error is FirebaseException) {
    return 'The staff collection could not be loaded.\n\n'
        'Firebase code: ${error.code}\n'
        'Message: ${error.message ?? error.toString()}';
  }
  return 'The staff collection could not be loaded.\n\n$error';
}

String _staffInitials(AdminDocumentRow row) {
  final name = _staffName(row);
  final parts = name
      .split(RegExp(r'\s+'))
      .where((part) => part.trim().isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'S';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return '${parts.first.characters.first}${parts.last.characters.first}'
      .toUpperCase();
}

bool _staffActive(AdminDocumentRow row) {
  if (_isStaffInviteRow(row)) return false;

  var active = true;
  for (final key in ['active', 'isActive']) {
    final value = row.data[key];
    if (value is bool) {
      active = value;
      break;
    }
  }

  var disabled = false;
  for (final key in ['disabled', 'isDisabled']) {
    final value = row.data[key];
    if (value is bool) {
      disabled = value;
      break;
    }
  }

  return active && !disabled;
}

String _staffStatus(AdminDocumentRow row) {
  final rawStatus = row.readString(['status'], fallback: '').trim();
  if (rawStatus.isNotEmpty) return rawStatus.toLowerCase();
  if (_isStaffInviteRow(row)) return 'pending';
  return _staffActive(row) ? 'active' : 'disabled';
}

String _staffStatusLabel(AdminDocumentRow row) {
  final status = _staffStatus(row);
  if (status.isEmpty) return '—';
  return status[0].toUpperCase() + status.substring(1);
}

String _staffInternalNotes(AdminDocumentRow row) {
  final notes = row.readString(['internalNotes', 'notes'], fallback: '').trim();
  if (notes.isEmpty || notes == '—') return '—';
  return notes;
}

bool _staffCanResendInvite(AdminDocumentRow row, _StaffAccessPolicy policy) {
  if (_isStaffInviteRow(row)) {
    if (!policy.canInviteAny) return false;
    final status = _staffStatus(row);
    return status == 'pending' || status == 'invited' || status == 'expired';
  }

  if (!policy.canManageRole(_StaffRoleDefinition.fromRow(row))) return false;
  final status = _staffStatus(row);
  return status == 'pending' || status == 'invited' || status == 'expired';
}

bool _staffCanRemoveInvite(AdminDocumentRow row, _StaffAccessPolicy policy) {
  if (!_isStaffInviteRow(row) ||
      !policy.permissions.has(StaffPermission.staffRemove)) {
    return false;
  }
  final status = _staffStatus(row);
  return status == 'pending' || status == 'invited' || status == 'expired';
}

String _staffInvitedBy(AdminDocumentRow row) {
  final invitedBy = row.readString([
    'invitedBy',
    'invited_by',
    'createdBy',
  ], fallback: '');
  return invitedBy.isEmpty ? '—' : invitedBy;
}

int _readAdminInt(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
  }
  return 0;
}

String _readAdminDate(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value == null) continue;
    if (value is Timestamp) return _formatDateTime(value.toDate());
    if (value is DateTime) return _formatDateTime(value);
    if (value is int) {
      final millis = value > 9999999999 ? value : value * 1000;
      return _formatDateTime(
        DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal(),
      );
    }
    if (value is num) {
      final millis = value > 9999999999
          ? value.toInt()
          : (value * 1000).toInt();
      return _formatDateTime(
        DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal(),
      );
    }
    final text = value.toString().trim();
    if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
  }
  return '—';
}

void _showAdminSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
}

void _showTodo(BuildContext context, String? action) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('${action ?? 'Action'} — backend workflow TODO.'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

String _adminWelcomeGreeting() {
  final user = AuthService.currentUser;
  final firstName = AuthService.getFirstName(user);
  final name = firstName ?? AuthService.getDisplayName(user);
  return 'Welcome $name';
}

String _staffRoleLabel(StaffRole role) {
  return switch (role) {
    StaffRole.founder => 'Founder',
    StaffRole.management => 'Management',
    StaffRole.superAdmin => 'Super Admin',
    StaffRole.admin => 'Admin',
    StaffRole.coordinator => 'Coordinator',
    StaffRole.supporter => 'Supporter',
  };
}

Color _staffRoleAccent(StaffRole role) {
  return switch (role) {
    StaffRole.founder => AppColors.trailGold,
    StaffRole.management => AppColors.primaryPurple,
    StaffRole.superAdmin => AppColors.primaryPink,
    StaffRole.admin => Colors.lightBlueAccent,
    StaffRole.coordinator => Colors.cyanAccent,
    StaffRole.supporter => AppColors.textSecondary,
  };
}

class _AdminGraphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = AppColors.brandGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height * 0.72)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.62,
        size.width * 0.24,
        size.height * 0.35,
        size.width * 0.42,
        size.height * 0.46,
      )
      ..cubicTo(
        size.width * 0.58,
        size.height * 0.56,
        size.width * 0.66,
        size.height * 0.2,
        size.width * 0.82,
        size.height * 0.28,
      )
      ..cubicTo(
        size.width * 0.9,
        size.height * 0.32,
        size.width * 0.95,
        size.height * 0.16,
        size.width,
        size.height * 0.2,
      );

    final gridPaint = Paint()
      ..color = AppColors.primaryPurple.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (var i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
