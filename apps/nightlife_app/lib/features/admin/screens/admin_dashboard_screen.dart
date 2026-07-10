import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../auth/screens/login_screen.dart';
import '../../auth/services/auth_service.dart';
import '../services/admin_operations_service.dart';
import '../services/admin_permission_service.dart';
import '../../trails/models/trail_model.dart';
import '../../trails/services/trail_service.dart';
import 'trail_publish_workflow.dart';
import 'trail_route_preview_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  StaffRole _role = StaffRole.founder;
  _AdminPage _page = _AdminPage.dashboard;

  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    AdminPermissionService.getCurrentStaffRole().then((role) {
      if (mounted) setState(() => _role = role);
    });
  }

  @override
  Widget build(BuildContext context) {
    final availablePages = _AdminPage.values
        .where((page) => _role.atLeast(page.minimumRole))
        .toList();
    if (!_role.atLeast(_page.minimumRole)) _page = _AdminPage.dashboard;

    return Scaffold(
      backgroundColor: const Color(0xFF080713),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080713),
        elevation: 0,
        title: const Text('DrinkSpot Admin'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Chip(
              backgroundColor: const Color(0xFF171526),
              label: Text(_role.label),
            ),
          ),
          IconButton(
            tooltip: 'Refresh role',
            onPressed: () async {
              final role = await AdminPermissionService.getCurrentStaffRole();
              if (mounted) setState(() => _role = role);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Logout / Switch Account',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: _AdminContent(
        role: _role,
        page: _page,
        pages: availablePages,
        onPageSelected: (page) => setState(() => _page = page),
      ),
    );
  }
}

enum _AdminPage {
  dashboard,
  accountSupport,
  venues,
  drinks,
  deals,
  events,
  trails,
  users,
  reports,
  recovery,
  staff,
  userSelfService,
  analytics,
  financials,
  subscriptions,
  auditLogs,
  settings,
}

extension _AdminPageX on _AdminPage {
  String get label {
    switch (this) {
      case _AdminPage.dashboard:
        return 'Dashboard';
      case _AdminPage.accountSupport:
        return 'Account Support';
      case _AdminPage.venues:
        return 'Venues';
      case _AdminPage.drinks:
        return 'Drinks';
      case _AdminPage.deals:
        return 'Deals';
      case _AdminPage.events:
        return 'Events';
      case _AdminPage.trails:
        return 'Trails';
      case _AdminPage.users:
        return 'Users';
      case _AdminPage.reports:
        return 'Reports';
      case _AdminPage.recovery:
        return 'Recovery Centre';
      case _AdminPage.staff:
        return 'Staff Management';
      case _AdminPage.userSelfService:
        return 'User Self-Service';
      case _AdminPage.analytics:
        return 'Analytics';
      case _AdminPage.financials:
        return 'Financials';
      case _AdminPage.subscriptions:
        return 'Subscriptions';
      case _AdminPage.auditLogs:
        return 'Audit Logs';
      case _AdminPage.settings:
        return 'App Settings';
    }
  }

  IconData get icon {
    switch (this) {
      case _AdminPage.dashboard:
        return Icons.dashboard_customize;
      case _AdminPage.accountSupport:
        return Icons.support_agent;
      case _AdminPage.venues:
        return Icons.storefront;
      case _AdminPage.drinks:
        return Icons.local_bar;
      case _AdminPage.deals:
        return Icons.local_offer;
      case _AdminPage.events:
        return Icons.event;
      case _AdminPage.trails:
        return Icons.route_rounded;
      case _AdminPage.users:
        return Icons.people;
      case _AdminPage.reports:
        return Icons.report;
      case _AdminPage.recovery:
        return Icons.restore_from_trash;
      case _AdminPage.staff:
        return Icons.admin_panel_settings;
      case _AdminPage.userSelfService:
        return Icons.manage_accounts;
      case _AdminPage.analytics:
        return Icons.analytics;
      case _AdminPage.financials:
        return Icons.payments;
      case _AdminPage.subscriptions:
        return Icons.credit_card;
      case _AdminPage.auditLogs:
        return Icons.history;
      case _AdminPage.settings:
        return Icons.settings;
    }
  }

  String get adminHint {
    switch (this) {
      case _AdminPage.dashboard:
        return 'Admin home';
      case _AdminPage.accountSupport:
        return 'Help accounts';
      case _AdminPage.venues:
        return 'Review venues';
      case _AdminPage.drinks:
        return 'Moderate drinks';
      case _AdminPage.deals:
        return 'Manage deals';
      case _AdminPage.events:
        return 'Review events';
      case _AdminPage.trails:
        return 'Publish trails';
      case _AdminPage.users:
        return 'Manage users';
      case _AdminPage.reports:
        return 'Handle reports';
      case _AdminPage.recovery:
        return 'Restore items';
      case _AdminPage.staff:
        return 'Manage staff';
      case _AdminPage.userSelfService:
        return 'User tools';
      case _AdminPage.analytics:
        return 'Insights';
      case _AdminPage.financials:
        return 'Founder only';
      case _AdminPage.subscriptions:
        return 'Billing';
      case _AdminPage.auditLogs:
        return 'Audit history';
      case _AdminPage.settings:
        return 'App controls';
    }
  }

  StaffRole get minimumRole {
    switch (this) {
      case _AdminPage.dashboard:
      case _AdminPage.accountSupport:
      case _AdminPage.venues:
      case _AdminPage.reports:
      case _AdminPage.recovery:
      case _AdminPage.userSelfService:
        return StaffRole.support;
      case _AdminPage.drinks:
      case _AdminPage.deals:
      case _AdminPage.events:
      case _AdminPage.trails:
      case _AdminPage.users:
      case _AdminPage.analytics:
        return StaffRole.admin;
      case _AdminPage.staff:
      case _AdminPage.auditLogs:
      case _AdminPage.settings:
        return StaffRole.management;
      case _AdminPage.financials:
      case _AdminPage.subscriptions:
        return StaffRole.founder;
    }
  }
}

class _AdminSidebar extends StatelessWidget {
  final StaffRole role;
  final _AdminPage selected;
  final List<_AdminPage> pages;
  final ValueChanged<_AdminPage> onSelected;

  const _AdminSidebar({
    required this.role,
    required this.selected,
    required this.pages,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DRINKSPOT',
                  style: TextStyle(
                    color: Colors.white70,
                    letterSpacing: 1.5,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Staff Operations',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _RoleChip(role.label),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: pages.length,
              itemBuilder: (_, index) {
                final page = pages[index];
                final active = page == selected;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    selected: active,
                    selectedTileColor: const Color(0xFF111827),
                    selectedColor: Colors.white,
                    iconColor: active ? Colors.white : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    leading: Icon(page.icon),
                    title: Text(
                      page.label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onTap: () => onSelected(page),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminContent extends StatelessWidget {
  final StaffRole role;
  final _AdminPage page;
  final List<_AdminPage> pages;
  final ValueChanged<_AdminPage> onPageSelected;

  const _AdminContent({
    required this.role,
    required this.page,
    required this.pages,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: page == _AdminPage.dashboard
              ? _buildPage(context)
              : Column(
                  key: ValueKey('admin-page-${page.name}'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AdminBackIcon(
                      onTap: () => onPageSelected(_AdminPage.dashboard),
                    ),
                    const SizedBox(height: 10),
                    _buildPage(context),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildPage(BuildContext context) {
    if (!role.atLeast(page.minimumRole)) return const _LockedPanel();

    switch (page) {
      case _AdminPage.dashboard:
        return _DashboardPanel(
          role: role,
          pages: pages,
          onPageSelected: onPageSelected,
        );
      case _AdminPage.accountSupport:
        return _AccountSupportPanel(role: role);
      case _AdminPage.venues:
        return _VenuePanel(role: role);
      case _AdminPage.drinks:
        return _CollectionPanel(
          title: 'Drinks',
          subtitle: 'Manage drinks across all venues.',
          stream: AdminOperationsService.drinksStream(),
          icon: Icons.local_bar,
          role: role,
        );
      case _AdminPage.deals:
        return _CollectionPanel(
          title: 'Deals',
          subtitle: 'Create, edit, schedule, expire and restore deals.',
          stream: AdminOperationsService.dealsStream(),
          icon: Icons.local_offer,
          role: role,
        );
      case _AdminPage.events:
        return _CollectionPanel(
          title: 'Events',
          subtitle: 'Approve, edit and moderate venue and artist events.',
          stream: AdminOperationsService.eventsStream(),
          icon: Icons.event,
          role: role,
        );
      case _AdminPage.trails:
        return _TrailsPanel(role: role);
      case _AdminPage.users:
        return _UsersPanel(role: role);
      case _AdminPage.reports:
        return _ReportsPanel(role: role);
      case _AdminPage.recovery:
        return _RecoveryPanel(role: role);
      case _AdminPage.staff:
        return _StaffPanel(role: role);
      case _AdminPage.userSelfService:
        return const _SelfServicePanel();
      case _AdminPage.analytics:
        return _AnalyticsPanel(role: role);
      case _AdminPage.financials:
        return const _FounderOnlyPanel(
          title: 'Financials',
          subtitle:
              'Revenue, payouts, failed payments and payment-provider records.',
          metrics: {
            'Monthly Revenue': '£42.8k',
            'Net Revenue': '£36.1k',
            'Failed Payments': '18',
            'Pending Payouts': '£7.3k',
          },
        );
      case _AdminPage.subscriptions:
        return const _FounderOnlyPanel(
          title: 'Subscriptions',
          subtitle:
              'Venue and artist plan status, churn, invoices and billing controls.',
          metrics: {
            'Premium Venues': '732',
            'Artist Pro': '118',
            'Cancelled': '24',
            'Trial Accounts': '96',
          },
        );
      case _AdminPage.auditLogs:
        return _AuditPanel(role: role);
      case _AdminPage.settings:
        return _SettingsPanel(role: role);
    }
  }
}

class _DashboardPanel extends StatelessWidget {
  final StaffRole role;
  final List<_AdminPage> pages;
  final ValueChanged<_AdminPage> onPageSelected;

  const _DashboardPanel({
    required this.role,
    required this.pages,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    final hubPages = pages
        .where((page) => page != _AdminPage.dashboard)
        .toList();

    return Column(
      key: const ValueKey('dashboard'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdminHeroCard(role: role),
        const SizedBox(height: 18),
        _PageHeader(
          title: 'Admin Control Centre',
          subtitle:
              'Tap a card to manage that area. Access is automatically filtered by staff role.',
        ),
        _AdminCategoryGrid(pages: hubPages, onSelected: onPageSelected),
        const SizedBox(height: 18),
        _MetricGrid(
          cards: [
            _Metric(
              'Venues',
              '1,248',
              Icons.storefront,
              '86 pending verification',
            ),
            _Metric(
              'Normal Users',
              '92,184',
              Icons.people,
              'All customer accounts',
            ),
            _Metric(
              'Venue Accounts',
              '1,106',
              Icons.business,
              'Venue owner accounts',
            ),
            _Metric(
              'Artist Accounts',
              '384',
              Icons.music_note,
              'Performers and DJs',
            ),
            _Metric('Open Reports', '29', Icons.report, '5 high severity'),
            _Metric(
              'Deleted Items',
              '42',
              Icons.restore_from_trash,
              'Available to recover',
            ),
            if (role.canViewFinancials)
              _Metric('Revenue', '£42.8k', Icons.payments, 'Founder only'),
            if (role.canViewFinancials)
              _Metric(
                'Subscriptions',
                '850',
                Icons.credit_card,
                'Founder only',
              ),
          ],
        ),
        const SizedBox(height: 18),
        _InfoCard(
          title: 'Role summary',
          lines: [
            'Support: account help, venue name/image changes and deleted-item recovery.',
            'Admin: venue, drink, deal, event moderation and Trails review access.',
            'Management: operations, staff accounts, audit visibility and Trail publishing.',
            'Founder/App Owner: full access including financials, billing and permanent deletion.',
          ],
        ),
      ],
    );
  }
}

class _AdminHeroCard extends StatelessWidget {
  final StaffRole role;
  const _AdminHeroCard({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A0B2E).withOpacity(0.96),
            const Color(0xFF9D28FF).withOpacity(0.42),
            const Color(0xFF1E2030).withOpacity(0.72),
          ],
        ),
        border: Border.all(color: const Color(0xFF9D28FF).withOpacity(0.32)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9D28FF).withOpacity(0.14),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Staff Operations',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Signed in as ${role.label}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.76),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.security_rounded, color: Colors.white70),
        ],
      ),
    );
  }
}

class _AdminCategoryGrid extends StatelessWidget {
  final List<_AdminPage> pages;
  final ValueChanged<_AdminPage> onSelected;

  const _AdminCategoryGrid({required this.pages, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width > 1100
            ? 4
            : width > 760
            ? 3
            : width > 520
            ? 2
            : 1;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: columns == 1 ? 4.8 : 3.7,
          children: pages
              .map(
                (page) =>
                    _AdminHubCard(page: page, onTap: () => onSelected(page)),
              )
              .toList(),
        );
      },
    );
  }
}

class _AdminHubCard extends StatelessWidget {
  final _AdminPage page;
  final VoidCallback onTap;

  const _AdminHubCard({required this.page, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2030).withOpacity(0.62),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF9D28FF).withOpacity(0.22),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF9D28FF).withOpacity(0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(page.icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      page.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      page.adminHint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.62),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminBackIcon extends StatelessWidget {
  final VoidCallback onTap;
  const _AdminBackIcon({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 16,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _TrailsPanel extends StatefulWidget {
  final StaffRole role;
  const _TrailsPanel({required this.role});

  @override
  State<_TrailsPanel> createState() => _TrailsPanelState();
}

class _TrailsPanelState extends State<_TrailsPanel> {
  bool _isWorking = false;

  bool get _canManageTrails => widget.role.atLeast(StaffRole.management);

  Future<void> _runAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    if (_isWorking) return;
    setState(() => _isWorking = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Trail action failed: $error')));
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _createTrail() async {
    if (!_canManageTrails || _isWorking) return;
    final draft = await showDialog<_TrailMetadataDraft>(
      context: context,
      builder: (_) => const _TrailMetadataDialog(),
    );
    if (draft == null || !mounted) return;

    await _runAction(() async {
      final trailId = await TrailService.createTrail(
        name: draft.name,
        description: draft.description,
        bannerImageUrl: draft.bannerImageUrl,
        area: draft.area,
        availabilityStart: draft.availabilityStart,
        availabilityEnd: draft.availabilityEnd,
        trailType: draft.trailType,
      );
      if (draft.status == TrailStatus.published) {
        await TrailService.publishTrail(trailId: trailId);
      } else if (draft.status == TrailStatus.archived ||
          draft.status == TrailStatus.disabled) {
        await TrailService.archiveTrail(trailId);
      }
    }, 'Trail created.');
  }

  void _openTrailEditor(DrinkSpotTrailModel trail) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _TrailDetailScreen(trailId: trail.id, role: widget.role),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DrinkSpotTrailModel>>(
      key: const ValueKey('trails'),
      stream: TrailService.watchStaffTrails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final trails = snapshot.data ?? const <DrinkSpotTrailModel>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PageHeader(
              title: 'Trail Management',
              subtitle: 'Create trails, add venues, and publish when ready.',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _canManageTrails && !_isWorking
                    ? _createTrail
                    : null,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create Trail'),
              ),
            ),
            const SizedBox(height: 20),
            if (trails.isEmpty)
              const _TrailGlassPanel(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Text(
                      'No trails yet. Create your first trail to get started.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            else
              ...trails.map(
                (trail) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _TrailHeroCard(
                    trail: trail,
                    onTap: () => _openTrailEditor(trail),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TrailHeroCard extends StatelessWidget {
  const _TrailHeroCard({required this.trail, required this.onTap});

  final DrinkSpotTrailModel trail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: 148,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _TrailBannerImage(url: trail.bannerImageUrl),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.10),
                      Colors.black.withOpacity(0.82),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: _TrailAdminChip(
                        _trailStatusIcon(trail),
                        _trailStatusLabel(trail),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      trail.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _TrailMiniPill(
                          Icons.storefront_rounded,
                          '${trail.venueCount}',
                        ),
                        _TrailMiniPill(
                          Icons.category_rounded,
                          trail.trailType.label,
                        ),
                        _TrailMiniPill(
                          Icons.schedule_rounded,
                          _formatTrailDuration(trail.estimatedDuration),
                        ),
                        if (trail.area.trim().isNotEmpty)
                          _TrailMiniPill(Icons.place_rounded, trail.area),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrailDetailScreen extends StatefulWidget {
  const _TrailDetailScreen({required this.trailId, required this.role});

  final String trailId;
  final StaffRole role;

  @override
  State<_TrailDetailScreen> createState() => _TrailDetailScreenState();
}

class _TrailDetailScreenState extends State<_TrailDetailScreen> {
  int _selectedTab = 0;
  bool _isWorking = false;

  bool get _canManageTrails => widget.role.atLeast(StaffRole.management);
  bool get _canDeleteTrails => widget.role.atLeast(StaffRole.admin);

  Future<void> _runAction(
    Future<void> Function() action,
    String successMessage, {
    bool showSuccessSnackBar = true,
  }) async {
    if (_isWorking) return;
    setState(() => _isWorking = true);
    try {
      await action();
      if (!mounted) return;
      if (showSuccessSnackBar && successMessage.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Trail action failed: $error')));
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _saveBanner(
    DrinkSpotTrailModel trail,
    String bannerImageUrl,
  ) async {
    if (!_canManageTrails || _isWorking) return;
    await _runAction(
      () => TrailService.updateTrailMetadata(
        trailId: trail.id,
        name: trail.name,
        description: trail.description,
        bannerImageUrl: bannerImageUrl,
        area: trail.area,
        availabilityStart: trail.availabilityStart,
        availabilityEnd: trail.availabilityEnd,
        trailType: trail.trailType,
      ),
      'Trail banner saved.',
    );
  }

  Future<void> _saveMetadata(
    DrinkSpotTrailModel trail,
    _TrailMetadataDraft draft,
  ) async {
    if (!_canManageTrails || _isWorking) return;
    await _runAction(
      () => TrailService.updateTrailMetadata(
        trailId: trail.id,
        name: draft.name,
        description: draft.description,
        bannerImageUrl: draft.bannerImageUrl,
        area: draft.area,
        availabilityStart: draft.availabilityStart,
        availabilityEnd: draft.availabilityEnd,
        trailType: draft.trailType,
      ),
      'Trail details saved.',
    );
  }

  Future<void> _duplicateTrail(DrinkSpotTrailModel trail) async {
    if (!_canManageTrails || _isWorking) return;
    await _runAction(() async {
      final trailId = await TrailService.duplicateTrail(trail.id);
      if (!mounted || trailId.isEmpty) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              _TrailDetailScreen(trailId: trailId, role: widget.role),
        ),
      );
    }, 'Trail duplicated as draft.');
  }

  Future<void> _handlePublishWorkflow(DrinkSpotTrailModel trail) async {
    if (!_canManageTrails || _isWorking) return;

    final isPublished =
        trail.status == TrailStatus.published || trail.published;

    if (isPublished) {
      final confirmed = await UnpublishConfirmDialog.show(context);
      if (confirmed != true || !mounted) return;
      await _runAction(
        () => TrailService.unpublishTrail(trail.id),
        'Trail unpublished.',
      );
      return;
    }

    final result = await PublishChecklistDialog.show(
      context,
      trail: trail,
      onNavigateToTab: (tabIndex) => setState(() => _selectedTab = tabIndex),
    );
    if (result != PublishChecklistResult.publish || !mounted) return;

    await _runAction(
      () => TrailService.publishTrail(trailId: trail.id),
      '',
      showSuccessSnackBar: false,
    );
    if (!mounted) return;

    await PublishSuccessDialog.show(
      context,
      onPreviewRoute: () => _openRoutePreview(trail),
    );
  }

  Future<void> _archiveTrail(DrinkSpotTrailModel trail) async {
    if (!_canManageTrails || _isWorking) return;
    await _runAction(
      () => TrailService.archiveTrail(trail.id),
      'Trail archived.',
    );
  }

  Future<void> _deleteTrail(DrinkSpotTrailModel trail) async {
    if (!_canDeleteTrails || _isWorking) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete trail?'),
        content: Text(
          'This will permanently delete "${trail.name}" and its embedded stops.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.delete_forever_rounded),
            label: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _runAction(() async {
      await TrailService.deleteTrail(trail.id);
      if (mounted) Navigator.of(context).pop();
    }, 'Trail deleted.');
  }

  void _openRoutePreview(DrinkSpotTrailModel trail) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => TrailRoutePreviewScreen(
          trail: trail,
          onGoToVenues: () => setState(() => _selectedTab = 1),
        ),
      ),
    );
  }

  Widget _buildTabContent(DrinkSpotTrailModel trail) {
    return IndexedStack(
      index: _selectedTab,
      sizing: StackFit.expand,
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: _TrailOverviewTab(
            trail: trail,
            isWorking: _isWorking,
            canManageTrails: _canManageTrails,
            onDuplicate: () => _duplicateTrail(trail),
            onArchive: () => _archiveTrail(trail),
            onGoToVenues: () => setState(() => _selectedTab = 1),
            onPreviewRoute: () => _openRoutePreview(trail),
          ),
        ),
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: _TrailEditorCard(
            key: ValueKey('venues-${trail.id}'),
            trail: trail,
            canManageTrails: _canManageTrails,
          ),
        ),
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: _TrailBannerTab(
            key: ValueKey('banner-${trail.id}'),
            trail: trail,
            canManage: _canManageTrails,
            isWorking: _isWorking,
            onSaveBanner: (url) => _saveBanner(trail, url),
          ),
        ),
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: _TrailDetailDetailsTab(
            key: ValueKey('details-${trail.id}'),
            trail: trail,
            canManage: _canManageTrails,
            isWorking: _isWorking,
            onSave: _saveMetadata,
            onOpenBannerTab: () => setState(() => _selectedTab = 2),
          ),
        ),
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: _TrailDetailSettingsTab(
            trail: trail,
            isWorking: _isWorking,
            canManageTrails: _canManageTrails,
            canDeleteTrails: _canDeleteTrails,
            onTogglePublished: () => _handlePublishWorkflow(trail),
            onArchive: () => _archiveTrail(trail),
            onDuplicate: () => _duplicateTrail(trail),
            onDelete: () => _deleteTrail(trail),
            onPreviewRoute: () => _openRoutePreview(trail),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080713),
      body: StreamBuilder<DrinkSpotTrailModel?>(
        stream: TrailService.watchTrail(widget.trailId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final trail = snapshot.data;
          if (trail == null) {
            return const Center(
              child: Text(
                'Trail not found.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TrailManagementHeader(trail: trail),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _TrailManagementTabBar(
                  selectedIndex: _selectedTab,
                  onSelected: (index) => setState(() => _selectedTab = index),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildTabContent(trail)),
            ],
          );
        },
      ),
    );
  }
}

class _TrailManagementHeader extends StatelessWidget {
  const _TrailManagementHeader({required this.trail});

  final DrinkSpotTrailModel trail;

  @override
  Widget build(BuildContext context) {
    final trailDate = _trailAdminDateTime(trail.availabilityStart);

    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
        decoration: BoxDecoration(
          color: const Color(0xFF111218).withOpacity(0.92),
          border: Border(
            bottom: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trail.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    trailDate,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _TrailAdminChip(_trailStatusIcon(trail), _trailStatusLabel(trail)),
          ],
        ),
      ),
    );
  }
}

class _TrailManagementTabBar extends StatelessWidget {
  const _TrailManagementTabBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _tabs = [
    (Icons.dashboard_rounded, 'Overview'),
    (Icons.location_on_rounded, 'Venues'),
    (Icons.image_rounded, 'Banner'),
    (Icons.description_rounded, 'Details'),
    (Icons.settings_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _tabs.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: i == 0 ? 0 : 2,
                right: i == 4 ? 0 : 2,
              ),
              child: _TrailManagementNavItem(
                icon: _tabs[i].$1,
                label: _tabs[i].$2,
                selected: selectedIndex == i,
                onTap: () => onSelected(i),
              ),
            ),
          ),
      ],
    );
  }
}

class _TrailManagementNavItem extends StatelessWidget {
  const _TrailManagementNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const _purple = Color(0xFFFF2D95);
  static const _duration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: TweenAnimationBuilder<double>(
            duration: _duration,
            curve: Curves.easeOutCubic,
            tween: Tween<double>(end: selected ? 1 : 0),
            builder: (context, t, child) {
              final backgroundColor = Color.lerp(
                const Color(0xFF111218).withOpacity(0.72),
                _purple,
                t,
              )!;
              final borderColor = Color.lerp(
                Colors.white.withOpacity(0.08),
                _purple.withOpacity(0.85),
                t,
              )!;
              final iconColor = Color.lerp(Colors.white54, Colors.white, t)!;
              final textColor = Color.lerp(Colors.white60, Colors.white, t)!;

              return AnimatedContainer(
                duration: _duration,
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 2,
                ),
                constraints: const BoxConstraints(minHeight: 56),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                  boxShadow: t > 0.05
                      ? [
                          BoxShadow(
                            color: _purple.withOpacity(0.34 * t),
                            blurRadius: 14 * t,
                            offset: Offset(0, 4 * t),
                          ),
                        ]
                      : const [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedScale(
                      scale: 0.94 + (0.06 * t),
                      duration: _duration,
                      curve: Curves.easeOutCubic,
                      child: Icon(icon, size: 22, color: iconColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TrailManagementPlaceholderTab extends StatelessWidget {
  const _TrailManagementPlaceholderTab({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _TrailGlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFFFF2D95), size: 28),
              const SizedBox(height: 14),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This section will be built in an upcoming update.',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrailOverviewTab extends StatelessWidget {
  const _TrailOverviewTab({
    required this.trail,
    required this.isWorking,
    required this.canManageTrails,
    required this.onDuplicate,
    required this.onArchive,
    required this.onGoToVenues,
    required this.onPreviewRoute,
  });

  final DrinkSpotTrailModel trail;
  final bool isWorking;
  final bool canManageTrails;
  final VoidCallback onDuplicate;
  final VoidCallback onArchive;
  final VoidCallback onGoToVenues;
  final VoidCallback onPreviewRoute;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('trails')
          .doc(trail.id)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? const <String, dynamic>{};
        final updatedAt = data['updatedAt'];
        final String? lastUpdated = updatedAt is Timestamp
            ? _trailAdminDateTime(updatedAt.toDate())
            : null;
        final hasVenues = _trailVenueCount(trail) > 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OverviewHeroCard(trail: trail, lastUpdated: lastUpdated),
            const SizedBox(height: 16),
            if (!hasVenues)
              _OverviewEmptyState(onGoToVenues: onGoToVenues)
            else ...[
              _OverviewStatisticsRow(trail: trail),
              const SizedBox(height: 20),
              _OverviewQuickActions(
                isWorking: isWorking,
                canManageTrails: canManageTrails,
                hasVenues: hasVenues,
                onDuplicate: onDuplicate,
                onArchive: onArchive,
                onPreviewRoute: onPreviewRoute,
              ),
              const SizedBox(height: 20),
              _OverviewStatusCard(trail: trail),
              const SizedBox(height: 20),
              _OverviewInformationCard(
                trail: trail,
                firestoreData: data,
                lastUpdated: lastUpdated,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _OverviewHeroCard extends StatelessWidget {
  const _OverviewHeroCard({required this.trail, this.lastUpdated});

  final DrinkSpotTrailModel trail;
  final String? lastUpdated;

  @override
  Widget build(BuildContext context) {
    final venueCount = _trailVenueCount(trail);
    final availability =
        '${_trailAdminDateTime(trail.availabilityStart)} – ${_trailAdminDateTime(trail.availabilityEnd)}';

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 212,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _TrailBannerImage(url: trail.bannerImageUrl),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.12),
                    Colors.black.withOpacity(0.86),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: _TrailAdminChip(
                      _trailStatusIcon(trail),
                      _trailStatusLabel(trail),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    trail.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    availability,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _TrailMiniPill(
                        Icons.storefront_rounded,
                        '$venueCount venues',
                      ),
                      if (lastUpdated != null)
                        _TrailMiniPill(
                          Icons.update_rounded,
                          'Updated $lastUpdated',
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewStatisticsRow extends StatelessWidget {
  const _OverviewStatisticsRow({required this.trail});

  final DrinkSpotTrailModel trail;

  @override
  Widget build(BuildContext context) {
    final stats = [
      (Icons.location_on_rounded, 'Venues', '${_trailVenueCount(trail)}'),
      (Icons.straighten_rounded, 'Walking Distance', 'Coming Soon'),
      (Icons.directions_walk_rounded, 'Walking Time', 'Coming Soon'),
      (
        Icons.schedule_rounded,
        'Trail Duration',
        _overviewTrailDurationLabel(trail),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 4 : 2;
        const spacing = 10.0;
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final stat in stats)
              SizedBox(
                width: itemWidth,
                child: _OverviewStatCard(
                  icon: stat.$1,
                  label: stat.$2,
                  value: stat.$3,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _OverviewStatCard extends StatelessWidget {
  const _OverviewStatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _TrailGlassPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFFFF2D95)),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewQuickActions extends StatelessWidget {
  const _OverviewQuickActions({
    required this.isWorking,
    required this.canManageTrails,
    required this.hasVenues,
    required this.onDuplicate,
    required this.onArchive,
    required this.onPreviewRoute,
  });

  final bool isWorking;
  final bool canManageTrails;
  final bool hasVenues;
  final VoidCallback onDuplicate;
  final VoidCallback onArchive;
  final VoidCallback onPreviewRoute;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _TrailSectionTitle(
          title: 'Quick Actions',
          subtitle: 'Common trail management shortcuts.',
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final stack = constraints.maxWidth < 420;

            final actions = [
              _OverviewActionButton(
                icon: Icons.map_rounded,
                label: 'Preview Route',
                enabled: hasVenues,
                onPressed: hasVenues ? onPreviewRoute : null,
              ),
              _OverviewActionButton(
                icon: Icons.copy_rounded,
                label: 'Duplicate',
                enabled: canManageTrails && !isWorking,
                onPressed: onDuplicate,
              ),
              _OverviewActionButton(
                icon: Icons.archive_rounded,
                label: 'Archive',
                enabled: canManageTrails && !isWorking,
                onPressed: onArchive,
              ),
            ];

            if (stack) {
              return Column(
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    actions[i],
                    if (i < actions.length - 1) const SizedBox(height: 10),
                  ],
                ],
              );
            }

            return Row(
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  Expanded(child: actions[i]),
                  if (i < actions.length - 1) const SizedBox(width: 10),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _OverviewActionButton extends StatelessWidget {
  const _OverviewActionButton({
    required this.icon,
    required this.label,
    this.badge,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String? badge;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.55,
          duration: const Duration(milliseconds: 180),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF111218).withOpacity(0.72),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: enabled ? const Color(0xFFFF2D95) : Colors.white54,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: enabled ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    badge!,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

int _trailVenueCount(DrinkSpotTrailModel trail) {
  return trail.stops.isNotEmpty ? trail.stops.length : trail.venueCount;
}

String _overviewTrailDurationLabel(DrinkSpotTrailModel trail) {
  if (trail.estimatedDuration.inMinutes > 0) {
    return _formatTrailDuration(trail.estimatedDuration);
  }
  final span = trail.availabilityEnd.difference(trail.availabilityStart);
  if (span.inMinutes > 0) {
    return _formatTrailDuration(span);
  }
  return 'Coming Soon';
}

class _OverviewStatusCard extends StatelessWidget {
  const _OverviewStatusCard({required this.trail});

  final DrinkSpotTrailModel trail;

  @override
  Widget build(BuildContext context) {
    final items = _overviewStatusItems(trail);

    return _TrailGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TrailSectionTitle(
            title: 'Trail Status',
            subtitle: 'A quick visual guide to trail readiness.',
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < items.length; i++) ...[
            _OverviewChecklistRow(item: items[i]),
            if (i < items.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _OverviewChecklistItem {
  const _OverviewChecklistItem({
    required this.isComplete,
    required this.completeLabel,
    required this.incompleteLabel,
  });

  final bool isComplete;
  final String completeLabel;
  final String incompleteLabel;
}

class _OverviewChecklistRow extends StatelessWidget {
  const _OverviewChecklistRow({required this.item});

  final _OverviewChecklistItem item;

  @override
  Widget build(BuildContext context) {
    final label = item.isComplete ? item.completeLabel : item.incompleteLabel;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(item.isComplete ? 0.18 : 0.24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isComplete
              ? const Color(0xFFFF2D95).withOpacity(0.22)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Icon(
            item.isComplete ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 20,
            color: item.isComplete
                ? const Color(0xFFFF2D95)
                : const Color(0xFFFF6B6B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: item.isComplete ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<_OverviewChecklistItem> _overviewStatusItems(DrinkSpotTrailModel trail) {
  final hasName = trail.name.trim().isNotEmpty;
  final hasBanner = trail.bannerImageUrl.trim().isNotEmpty;
  final hasVenues = _trailVenueCount(trail) > 0;
  final hasAvailability = trail.availabilityEnd.isAfter(
    trail.availabilityStart,
  );
  final hasSettings =
      trail.area.trim().isNotEmpty || trail.description.trim().isNotEmpty;

  return [
    _OverviewChecklistItem(
      isComplete: hasName,
      completeLabel: 'Trail Name',
      incompleteLabel: 'Trail Name Missing',
    ),
    _OverviewChecklistItem(
      isComplete: hasBanner,
      completeLabel: 'Banner',
      incompleteLabel: 'Banner Missing',
    ),
    _OverviewChecklistItem(
      isComplete: hasVenues,
      completeLabel: 'Venues',
      incompleteLabel: 'No Venues Added',
    ),
    _OverviewChecklistItem(
      isComplete: hasAvailability,
      completeLabel: 'Availability',
      incompleteLabel: 'Availability Not Set',
    ),
    _OverviewChecklistItem(
      isComplete: hasSettings,
      completeLabel: 'Settings',
      incompleteLabel: 'Settings Incomplete',
    ),
  ];
}

class _OverviewInformationCard extends StatelessWidget {
  const _OverviewInformationCard({
    required this.trail,
    required this.firestoreData,
    required this.lastUpdated,
  });

  final DrinkSpotTrailModel trail;
  final Map<String, dynamic> firestoreData;
  final String? lastUpdated;

  String? _timestampLabel(dynamic value) {
    if (value is Timestamp) {
      return _trailAdminDateTime(value.toDate());
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final created =
        _timestampLabel(firestoreData['createdAt']) ??
        _trailAdminDateTime(trail.generatedAt);
    final availability =
        '${_trailAdminDateTime(trail.availabilityStart)} – ${_trailAdminDateTime(trail.availabilityEnd)}';
    final duration = _overviewTrailDurationLabel(trail);

    return _TrailGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TrailSectionTitle(
            title: 'Trail Information',
            subtitle: 'Read-only trail metadata and timestamps.',
          ),
          const SizedBox(height: 16),
          _TrailInfoRow(
            icon: Icons.tag_rounded,
            label: 'Trail ID',
            value: trail.id,
          ),
          _TrailInfoRow(
            icon: Icons.add_circle_outline_rounded,
            label: 'Created',
            value: created,
          ),
          if (lastUpdated != null)
            _TrailInfoRow(
              icon: Icons.update_rounded,
              label: 'Last Updated',
              value: lastUpdated!,
            ),
          _TrailInfoRow(
            icon: Icons.event_available_rounded,
            label: 'Available Date',
            value: availability,
          ),
          _TrailInfoRow(
            icon: Icons.flag_rounded,
            label: 'Current Status',
            value: _trailStatusLabel(trail),
          ),
          _TrailInfoRow(
            icon: Icons.schedule_rounded,
            label: 'Estimated Duration',
            value: duration,
          ),
        ],
      ),
    );
  }
}

class _OverviewEmptyState extends StatelessWidget {
  const _OverviewEmptyState({required this.onGoToVenues});

  final VoidCallback onGoToVenues;

  @override
  Widget build(BuildContext context) {
    return _TrailGlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      child: Column(
        children: [
          const Icon(
            Icons.location_on_rounded,
            size: 56,
            color: Color(0xFFFF2D95),
          ),
          const SizedBox(height: 18),
          const Text(
            'Add venues to get started',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'This trail does not have any venues yet. Add stops to build the route and unlock the full overview dashboard.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onGoToVenues,
              icon: const Icon(Icons.local_bar_rounded),
              label: const Text('Go to Venues'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrailBannerTab extends StatefulWidget {
  const _TrailBannerTab({
    super.key,
    required this.trail,
    required this.canManage,
    required this.isWorking,
    required this.onSaveBanner,
  });

  final DrinkSpotTrailModel trail;
  final bool canManage;
  final bool isWorking;
  final Future<void> Function(String bannerImageUrl) onSaveBanner;

  @override
  State<_TrailBannerTab> createState() => _TrailBannerTabState();
}

class _TrailBannerTabState extends State<_TrailBannerTab> {
  late String _previewUrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _previewUrl = widget.trail.bannerImageUrl;
  }

  @override
  void didUpdateWidget(covariant _TrailBannerTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trail.bannerImageUrl != widget.trail.bannerImageUrl &&
        _previewUrl == oldWidget.trail.bannerImageUrl) {
      _previewUrl = widget.trail.bannerImageUrl;
    }
  }

  bool get _hasPreview => _previewUrl.trim().isNotEmpty;
  bool get _hasUnsavedChanges =>
      _previewUrl.trim() != widget.trail.bannerImageUrl.trim();

  List<_VenueBannerOption> get _venueBannerOptions {
    final seen = <String>{};
    final options = <_VenueBannerOption>[];
    for (final stop in widget.trail.stops) {
      final url = stop.bannerImageUrl.trim();
      if (url.isEmpty || seen.contains(url)) continue;
      seen.add(url);
      options.add(_VenueBannerOption(venueName: stop.venueName, url: url));
    }
    return options;
  }

  Future<void> _promptBannerUrl() async {
    if (!widget.canManage) return;
    final controller = TextEditingController(text: _previewUrl);
    final url = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Upload New Banner'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Banner image URL',
            hintText: 'https://...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Use Banner'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (url == null || !mounted) return;
    setState(() => _previewUrl = url.trim());
  }

  Future<void> _savePreview() async {
    if (!widget.canManage || _saving || widget.isWorking) return;
    setState(() => _saving = true);
    try {
      await widget.onSaveBanner(_previewUrl.trim());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final venueBanners = _venueBannerOptions;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('trails')
          .doc(widget.trail.id)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? const <String, dynamic>{};
        final updatedAt = data['updatedAt'];
        final String? lastUpdated = updatedAt is Timestamp
            ? _trailAdminDateTime(updatedAt.toDate())
            : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: _TrailSectionTitle(
                    title: 'Banner',
                    subtitle: 'Preview and choose the trail hero image.',
                  ),
                ),
                FilledButton.icon(
                  onPressed:
                      widget.canManage &&
                          !_saving &&
                          !widget.isWorking &&
                          _hasUnsavedChanges
                      ? _savePreview
                      : null,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: const Text('Save Banner'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _BannerPreviewCard(
              trailName: widget.trail.name,
              bannerUrl: _previewUrl,
            ),
            if (!_hasPreview) ...[
              const SizedBox(height: 16),
              const _BannerEmptyState(),
            ],
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 620 ? 2 : 1;
                const spacing = 12.0;
                final itemWidth = columns == 1
                    ? constraints.maxWidth
                    : (constraints.maxWidth - spacing) / 2;

                final cards = [
                  _BannerSourceCard(
                    icon: Icons.collections_rounded,
                    title: 'DrinkSpot Banner Library',
                    subtitle: 'Choose from DrinkSpot banner designs.',
                    badge: 'Coming Soon',
                    enabled: false,
                    onTap: null,
                  ),
                  _BannerSourceCard(
                    icon: Icons.history_rounded,
                    title: 'Previously Uploaded',
                    subtitle: 'Reuse banners you\'ve already uploaded.',
                    badge: 'Coming Soon',
                    enabled: false,
                    onTap: null,
                  ),
                  _BannerSourceCard(
                    icon: Icons.storefront_rounded,
                    title: 'Venue Banners',
                    subtitle:
                        'Choose the banner from one of the venues in this trail.',
                    enabled: venueBanners.isNotEmpty,
                    onTap: null,
                  ),
                  _BannerSourceCard(
                    icon: Icons.upload_rounded,
                    title: 'Upload New Banner',
                    subtitle: 'Upload a custom banner.',
                    enabled: widget.canManage,
                    onTap: widget.canManage ? _promptBannerUrl : null,
                  ),
                ];

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final card in cards)
                      SizedBox(width: itemWidth, child: card),
                  ],
                );
              },
            ),
            if (venueBanners.isNotEmpty) ...[
              const SizedBox(height: 16),
              _VenueBannerSelector(
                options: venueBanners,
                selectedUrl: _previewUrl,
                onSelected: widget.canManage
                    ? (url) => setState(() => _previewUrl = url)
                    : null,
              ),
            ],
            const SizedBox(height: 20),
            _BannerInformationCard(
              bannerUrl: _previewUrl,
              savedBannerUrl: widget.trail.bannerImageUrl,
              lastUpdated: lastUpdated,
              hasUnsavedChanges: _hasUnsavedChanges,
            ),
          ],
        );
      },
    );
  }
}

class _VenueBannerOption {
  const _VenueBannerOption({required this.venueName, required this.url});

  final String venueName;
  final String url;
}

class _BannerPreviewCard extends StatelessWidget {
  const _BannerPreviewCard({required this.trailName, required this.bannerUrl});

  final String trailName;
  final String bannerUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 220,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _TrailBannerImage(url: bannerUrl),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.10),
                    Colors.black.withOpacity(0.82),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _TrailMiniPill(
                    Icons.visibility_rounded,
                    'Live Preview',
                  ),
                  const SizedBox(height: 10),
                  Text(
                    trailName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                      height: 1.05,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerSourceCard extends StatelessWidget {
  const _BannerSourceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.55,
          duration: const Duration(milliseconds: 180),
          child: _TrailGlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 28, color: const Color(0xFFFF2D95)),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(subtitle, style: const TextStyle(color: Colors.white70)),
                if (badge != null) ...[
                  const SizedBox(height: 10),
                  _TrailMiniPill(Icons.schedule_rounded, badge!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VenueBannerSelector extends StatelessWidget {
  const _VenueBannerSelector({
    required this.options,
    required this.selectedUrl,
    required this.onSelected,
  });

  final List<_VenueBannerOption> options;
  final String selectedUrl;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    return _TrailGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Venue banner options',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 118,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: options.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final option = options[index];
                final selected = selectedUrl.trim() == option.url.trim();

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onSelected == null
                        ? null
                        : () => onSelected!(option.url),
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 168,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFFFF2D95)
                              : Colors.white.withOpacity(0.08),
                          width: selected ? 2 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _TrailBannerImage(url: option.url),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.82),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 10,
                            right: 10,
                            bottom: 10,
                            child: Text(
                              option.venueName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerInformationCard extends StatelessWidget {
  const _BannerInformationCard({
    required this.bannerUrl,
    required this.savedBannerUrl,
    required this.lastUpdated,
    required this.hasUnsavedChanges,
  });

  final String bannerUrl;
  final String savedBannerUrl;
  final String? lastUpdated;
  final bool hasUnsavedChanges;

  @override
  Widget build(BuildContext context) {
    final hasBanner = bannerUrl.trim().isNotEmpty;
    final status = !hasBanner
        ? 'No banner selected'
        : hasUnsavedChanges
        ? 'Preview updated — save to apply'
        : savedBannerUrl.trim().isNotEmpty
        ? 'Banner set'
        : 'Banner ready to save';

    return _TrailGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TrailSectionTitle(
            title: 'Current Banner Information',
            subtitle: 'Details about the selected trail banner.',
          ),
          const SizedBox(height: 16),
          _TrailInfoRow(
            icon: Icons.image_rounded,
            label: 'Current banner status',
            value: status,
          ),
          _BannerResolutionRow(bannerUrl: bannerUrl),
          if (lastUpdated != null)
            _TrailInfoRow(
              icon: Icons.update_rounded,
              label: 'Last updated',
              value: lastUpdated!,
            ),
        ],
      ),
    );
  }
}

class _BannerResolutionRow extends StatefulWidget {
  const _BannerResolutionRow({required this.bannerUrl});

  final String bannerUrl;

  @override
  State<_BannerResolutionRow> createState() => _BannerResolutionRowState();
}

class _BannerResolutionRowState extends State<_BannerResolutionRow> {
  String? _resolution;
  ImageStreamListener? _listener;
  ImageStream? _stream;

  @override
  void didUpdateWidget(covariant _BannerResolutionRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bannerUrl != widget.bannerUrl) {
      _resolution = null;
      _resolveResolution();
    }
  }

  @override
  void initState() {
    super.initState();
    _resolveResolution();
  }

  @override
  void dispose() {
    if (_listener != null && _stream != null) {
      _stream!.removeListener(_listener!);
    }
    super.dispose();
  }

  void _resolveResolution() {
    if (_listener != null && _stream != null) {
      _stream!.removeListener(_listener!);
      _listener = null;
      _stream = null;
    }

    final url = widget.bannerUrl.trim();
    if (url.isEmpty) {
      setState(() => _resolution = null);
      return;
    }

    final image = NetworkImage(url);
    _stream = image.resolve(const ImageConfiguration());
    _listener = ImageStreamListener(
      (info, _) {
        if (!mounted) return;
        setState(() {
          _resolution = '${info.image.width} x ${info.image.height}';
        });
      },
      onError: (_, _) {
        if (!mounted) return;
        setState(() => _resolution = 'Unavailable');
      },
    );
    _stream!.addListener(_listener!);
  }

  @override
  Widget build(BuildContext context) {
    return _TrailInfoRow(
      icon: Icons.aspect_ratio_rounded,
      label: 'Image resolution',
      value:
          _resolution ??
          (widget.bannerUrl.trim().isEmpty ? 'Not set' : 'Loading...'),
    );
  }
}

class _BannerEmptyState extends StatelessWidget {
  const _BannerEmptyState();

  @override
  Widget build(BuildContext context) {
    return _TrailGlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFF2D95).withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.image_outlined, color: Color(0xFFFF2D95)),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose a banner to complete your trail',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Upload a custom image or pick a banner from one of your venue stops to preview how the trail will appear.',
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
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

class _TrailDetailDetailsTab extends StatefulWidget {
  const _TrailDetailDetailsTab({
    super.key,
    required this.trail,
    required this.canManage,
    required this.isWorking,
    required this.onSave,
    required this.onOpenBannerTab,
  });

  final DrinkSpotTrailModel trail;
  final bool canManage;
  final bool isWorking;
  final Future<void> Function(DrinkSpotTrailModel, _TrailMetadataDraft) onSave;
  final VoidCallback onOpenBannerTab;

  @override
  State<_TrailDetailDetailsTab> createState() => _TrailDetailDetailsTabState();
}

class _TrailDetailDetailsTabState extends State<_TrailDetailDetailsTab> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late DateTime _availabilityStart;
  late DateTime _availabilityEnd;

  @override
  void initState() {
    super.initState();
    final trail = widget.trail;
    _nameController = TextEditingController(text: trail.name);
    _descriptionController = TextEditingController(text: trail.description);
    _availabilityStart = trail.availabilityStart;
    _availabilityEnd = trail.availabilityEnd;
  }

  @override
  void didUpdateWidget(covariant _TrailDetailDetailsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trail.id != widget.trail.id) {
      _nameController.text = widget.trail.name;
      _descriptionController.text = widget.trail.description;
      _availabilityStart = widget.trail.availabilityStart;
      _availabilityEnd = widget.trail.availabilityEnd;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final current = start ? _availabilityStart : _availabilityEnd;
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (date == null || !mounted) return;

    final next = DateTime(
      date.year,
      date.month,
      date.day,
      current.hour,
      current.minute,
    );
    setState(() {
      if (start) {
        _availabilityStart = next;
        if (_availabilityEnd.isBefore(_availabilityStart)) {
          _availabilityEnd = _availabilityStart.add(const Duration(hours: 4));
        }
      } else {
        _availabilityEnd = next;
      }
    });
  }

  Future<void> _pickTime({required bool start}) async {
    final current = start ? _availabilityStart : _availabilityEnd;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null || !mounted) return;

    final next = DateTime(
      current.year,
      current.month,
      current.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (start) {
        _availabilityStart = next;
        if (_availabilityEnd.isBefore(_availabilityStart)) {
          _availabilityEnd = _availabilityStart.add(const Duration(hours: 4));
        }
      } else {
        _availabilityEnd = next;
      }
    });
  }

  Future<void> _save() async {
    await widget.onSave(
      widget.trail,
      _TrailMetadataDraft(
        name: _nameController.text,
        description: _descriptionController.text,
        bannerImageUrl: widget.trail.bannerImageUrl,
        area: widget.trail.area,
        availabilityStart: _availabilityStart,
        availabilityEnd: _availabilityEnd,
        trailType: widget.trail.trailType,
        status: widget.trail.status,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('trails')
          .doc(widget.trail.id)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? const <String, dynamic>{};
        final created =
            _detailsTimestampLabel(data['createdAt']) ??
            _trailAdminDateTime(widget.trail.generatedAt);
        final updatedAt = data['updatedAt'];
        final String? lastUpdated = updatedAt is Timestamp
            ? _trailAdminDateTime(updatedAt.toDate())
            : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: _TrailSectionTitle(
                    title: 'Details',
                    subtitle: 'Edit trail listing information.',
                  ),
                ),
                FilledButton.icon(
                  onPressed: widget.canManage && !widget.isWorking
                      ? _save
                      : null,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Save Details'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DetailsBasicInformationCard(
              nameController: _nameController,
              descriptionController: _descriptionController,
              enabled: widget.canManage,
            ),
            const SizedBox(height: 16),
            _DetailsAvailabilityCard(
              availabilityStart: _availabilityStart,
              availabilityEnd: _availabilityEnd,
              enabled: widget.canManage,
              onPickStartDate: () => _pickDate(start: true),
              onPickStartTime: () => _pickTime(start: true),
              onPickEndDate: () => _pickDate(start: false),
              onPickEndTime: () => _pickTime(start: false),
            ),
            const SizedBox(height: 16),
            _DetailsTrailInformationCard(
              trailId: widget.trail.id,
              created: created,
              lastUpdated: lastUpdated,
            ),
            const SizedBox(height: 16),
            _DetailsBannerRedirectCard(
              bannerUrl: widget.trail.bannerImageUrl,
              onOpenBannerTab: widget.onOpenBannerTab,
            ),
          ],
        );
      },
    );
  }
}

String? _detailsTimestampLabel(dynamic value) {
  if (value is Timestamp) {
    return _trailAdminDateTime(value.toDate());
  }
  return null;
}

String _detailsDateLabel(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

class _DetailsBasicInformationCard extends StatelessWidget {
  const _DetailsBasicInformationCard({
    required this.nameController,
    required this.descriptionController,
    required this.enabled,
  });

  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return _TrailGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TrailSectionTitle(
            title: 'Basic Information',
            subtitle: 'The public name and description for this trail.',
          ),
          const SizedBox(height: 20),
          TextField(
            controller: nameController,
            enabled: enabled,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
            decoration: const InputDecoration(
              labelText: 'Trail Name',
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: descriptionController,
            enabled: enabled,
            minLines: 4,
            maxLines: 8,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.45,
            ),
            decoration: const InputDecoration(
              labelText: 'Description',
              alignLabelWithHint: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsAvailabilityCard extends StatelessWidget {
  const _DetailsAvailabilityCard({
    required this.availabilityStart,
    required this.availabilityEnd,
    required this.enabled,
    required this.onPickStartDate,
    required this.onPickStartTime,
    required this.onPickEndDate,
    required this.onPickEndTime,
  });

  final DateTime availabilityStart;
  final DateTime availabilityEnd;
  final bool enabled;
  final VoidCallback onPickStartDate;
  final VoidCallback onPickStartTime;
  final VoidCallback onPickEndDate;
  final VoidCallback onPickEndTime;

  @override
  Widget build(BuildContext context) {
    final duration = _formatTrailDuration(
      availabilityEnd.difference(availabilityStart),
    );

    return _TrailGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TrailSectionTitle(
            title: 'Availability',
            subtitle: 'When this trail is available to users.',
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final stack = constraints.maxWidth < 420;

              Widget pickerRow({
                required String dateLabel,
                required String dateValue,
                required VoidCallback onDateTap,
                required String timeLabel,
                required String timeValue,
                required VoidCallback onTimeTap,
              }) {
                final dateField = _DetailsPickerField(
                  label: dateLabel,
                  value: dateValue,
                  icon: Icons.calendar_today_rounded,
                  enabled: enabled,
                  onTap: onDateTap,
                );
                final timeField = _DetailsPickerField(
                  label: timeLabel,
                  value: timeValue,
                  icon: Icons.schedule_rounded,
                  enabled: enabled,
                  onTap: onTimeTap,
                );

                if (stack) {
                  return Column(
                    children: [
                      dateField,
                      const SizedBox(height: 10),
                      timeField,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: dateField),
                    const SizedBox(width: 12),
                    Expanded(child: timeField),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Start',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  pickerRow(
                    dateLabel: 'Start Date',
                    dateValue: _detailsDateLabel(availabilityStart),
                    onDateTap: onPickStartDate,
                    timeLabel: 'Start Time',
                    timeValue: _trailAdminTime(availabilityStart),
                    onTimeTap: onPickStartTime,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'End',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  pickerRow(
                    dateLabel: 'End Date',
                    dateValue: _detailsDateLabel(availabilityEnd),
                    onDateTap: onPickEndDate,
                    timeLabel: 'End Time',
                    timeValue: _trailAdminTime(availabilityEnd),
                    onTimeTap: onPickEndTime,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _TrailMiniPill(Icons.timelapse_rounded, 'Duration $duration'),
        ],
      ),
    );
  }
}

class _DetailsPickerField extends StatelessWidget {
  const _DetailsPickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.55,
          duration: const Duration(milliseconds: 180),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: const Color(0xFFFF2D95)),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailsTrailInformationCard extends StatelessWidget {
  const _DetailsTrailInformationCard({
    required this.trailId,
    required this.created,
    this.lastUpdated,
  });

  final String trailId;
  final String created;
  final String? lastUpdated;

  @override
  Widget build(BuildContext context) {
    return _TrailGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TrailSectionTitle(
            title: 'Trail Information',
            subtitle: 'Read-only trail metadata.',
          ),
          const SizedBox(height: 16),
          _TrailInfoRow(
            icon: Icons.tag_rounded,
            label: 'Trail ID',
            value: trailId,
          ),
          _TrailInfoRow(
            icon: Icons.add_circle_outline_rounded,
            label: 'Created',
            value: created,
          ),
          if (lastUpdated != null)
            _TrailInfoRow(
              icon: Icons.update_rounded,
              label: 'Last Updated',
              value: lastUpdated!,
            ),
        ],
      ),
    );
  }
}

class _DetailsBannerRedirectCard extends StatelessWidget {
  const _DetailsBannerRedirectCard({
    required this.bannerUrl,
    required this.onOpenBannerTab,
  });

  final String bannerUrl;
  final VoidCallback onOpenBannerTab;

  @override
  Widget build(BuildContext context) {
    final hasBanner = bannerUrl.trim().isNotEmpty;

    return _TrailGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TrailSectionTitle(
            title: 'Banner',
            subtitle: 'Manage the trail hero image.',
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 88,
                  height: 56,
                  child: _TrailBannerImage(url: bannerUrl),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasBanner ? 'Current Banner' : 'No banner selected',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Banner management has moved to the Banner tab.',
                      style: TextStyle(color: Colors.white70, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOpenBannerTab,
              icon: const Icon(Icons.image_rounded),
              label: const Text('Open Banner Tab'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrailDetailInfoTab extends StatelessWidget {
  const _TrailDetailInfoTab({required this.trailId, required this.trail});

  final String trailId;
  final DrinkSpotTrailModel trail;

  String _formatWalkingDistance(int meters) {
    if (meters <= 0) return 'Not calculated';
    if (meters < 1609) return '${meters}m';
    final miles = meters / 1609.344;
    return '${miles.toStringAsFixed(1)} mi';
  }

  String? _timestampLabel(dynamic value) {
    if (value is Timestamp) {
      return _trailAdminDateTime(value.toDate());
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('trails')
          .doc(trailId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? const <String, dynamic>{};
        final created =
            _timestampLabel(data['createdAt']) ??
            _trailAdminDateTime(trail.generatedAt);
        final published = _timestampLabel(data['publishedAt']);

        return _TrailGlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _TrailSectionTitle(
                title: 'Info',
                subtitle: 'Summary stats for this trail.',
              ),
              const SizedBox(height: 16),
              _TrailInfoRow(
                icon: Icons.storefront_rounded,
                label: 'Venue count',
                value:
                    '${trail.stops.isNotEmpty ? trail.stops.length : trail.venueCount}',
              ),
              _TrailInfoRow(
                icon: Icons.schedule_rounded,
                label: 'Estimated duration',
                value: _formatTrailDuration(trail.estimatedDuration),
              ),
              _TrailInfoRow(
                icon: Icons.directions_walk_rounded,
                label: 'Walking distance',
                value: _formatWalkingDistance(trail.estimatedWalkingDistance),
              ),
              _TrailInfoRow(
                icon: Icons.flag_rounded,
                label: 'Status',
                value: _trailStatusLabel(trail),
              ),
              _TrailInfoRow(
                icon: Icons.category_rounded,
                label: 'Trail type',
                value: trail.trailType.label,
              ),
              _TrailInfoRow(
                icon: Icons.place_rounded,
                label: 'Area',
                value: trail.area.trim().isEmpty ? 'Not set' : trail.area,
              ),
              _TrailInfoRow(
                icon: Icons.calendar_today_rounded,
                label: 'Created',
                value: created,
              ),
              if (published != null)
                _TrailInfoRow(
                  icon: Icons.public_rounded,
                  label: 'Published',
                  value: published,
                ),
              _TrailInfoRow(
                icon: Icons.event_available_rounded,
                label: 'Availability',
                value:
                    '${_trailAdminDateTime(trail.availabilityStart)} – ${_trailAdminDateTime(trail.availabilityEnd)}',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TrailInfoRow extends StatelessWidget {
  const _TrailInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFFFF2D95)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
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

class _TrailDetailSettingsTab extends StatelessWidget {
  const _TrailDetailSettingsTab({
    required this.trail,
    required this.isWorking,
    required this.canManageTrails,
    required this.canDeleteTrails,
    required this.onTogglePublished,
    required this.onArchive,
    required this.onDuplicate,
    required this.onDelete,
    required this.onPreviewRoute,
  });

  final DrinkSpotTrailModel trail;
  final bool isWorking;
  final bool canManageTrails;
  final bool canDeleteTrails;
  final VoidCallback onTogglePublished;
  final VoidCallback onArchive;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onPreviewRoute;

  @override
  Widget build(BuildContext context) {
    final hasVenues = _trailVenueCount(trail) > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _TrailSectionTitle(
          title: 'Settings',
          subtitle: 'Control publishing, visibility, and trail management.',
        ),
        const SizedBox(height: 16),
        _SettingsPublishStatusCard(
          trail: trail,
          canManageTrails: canManageTrails,
          isWorking: isWorking,
          onTogglePublished: onTogglePublished,
        ),
        const SizedBox(height: 16),
        _SettingsVisibilityCard(trail: trail),
        const SizedBox(height: 16),
        _SettingsParticipationCard(trail: trail),
        const SizedBox(height: 16),
        _SettingsRoutePreviewCard(
          hasVenues: hasVenues,
          onPreviewRoute: onPreviewRoute,
        ),
        const SizedBox(height: 16),
        _SettingsManagementActionsCard(
          canManageTrails: canManageTrails,
          canDeleteTrails: canDeleteTrails,
          isWorking: isWorking,
          onDuplicate: onDuplicate,
          onArchive: onArchive,
          onDelete: onDelete,
        ),
        const SizedBox(height: 16),
        const _SettingsDiagnosticsCard(),
      ],
    );
  }
}

class _SettingsPublishStatusCard extends StatelessWidget {
  const _SettingsPublishStatusCard({
    required this.trail,
    required this.canManageTrails,
    required this.isWorking,
    required this.onTogglePublished,
  });

  final DrinkSpotTrailModel trail;
  final bool canManageTrails;
  final bool isWorking;
  final VoidCallback onTogglePublished;

  @override
  Widget build(BuildContext context) {
    final published = trail.status == TrailStatus.published || trail.published;
    final statusLabel = published ? 'Published' : 'Draft';
    final explanation = published
        ? 'This trail is published and can appear to users when visibility requirements are met.'
        : 'This trail is a draft. Publish it when you are ready for users to discover it.';

    return _TrailGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TrailSectionTitle(
            title: 'Publishing Status',
            subtitle: 'Control whether this trail is live for users.',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: published
                      ? const Color(0xFFFF2D95).withOpacity(0.16)
                      : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: published
                        ? const Color(0xFFFF2D95).withOpacity(0.34)
                        : Colors.white.withOpacity(0.10),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      published
                          ? Icons.public_rounded
                          : Icons.edit_note_rounded,
                      size: 16,
                      color: published
                          ? const Color(0xFFFF2D95)
                          : Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: published ? Colors.white : Colors.white70,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            explanation,
            style: const TextStyle(color: Colors.white70, height: 1.45),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: canManageTrails && !isWorking
                  ? onTogglePublished
                  : null,
              icon: Icon(
                published
                    ? Icons.visibility_off_rounded
                    : Icons.rocket_launch_rounded,
              ),
              label: Text(published ? 'Unpublish / Move to Draft' : 'Publish'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsVisibilityCard extends StatelessWidget {
  const _SettingsVisibilityCard({required this.trail});

  final DrinkSpotTrailModel trail;

  @override
  Widget build(BuildContext context) {
    final visible = trail.isVisible;
    final detail = _settingsVisibilityDetail(trail);

    return _TrailGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TrailSectionTitle(
            title: 'Visibility',
            subtitle: 'How this trail appears in discovery today.',
          ),
          const SizedBox(height: 16),
          _SettingsStatusRow(
            icon: Icons.travel_explore_rounded,
            label: 'Discovery visibility',
            value: visible ? 'Visible now' : 'Hidden',
            positive: visible,
          ),
          const SizedBox(height: 10),
          _SettingsStatusRow(
            icon: Icons.flag_rounded,
            label: 'Publishing state',
            value: _trailStatusLabel(trail),
            positive: trail.status == TrailStatus.published || trail.published,
          ),
          const SizedBox(height: 10),
          _SettingsStatusRow(
            icon: Icons.storefront_rounded,
            label: 'Venue requirement',
            value: _trailVenueCount(trail) > 0 ? 'Venues added' : 'No venues',
            positive: _trailVenueCount(trail) > 0,
          ),
          const SizedBox(height: 12),
          Text(
            detail,
            style: const TextStyle(color: Colors.white70, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _SettingsParticipationCard extends StatelessWidget {
  const _SettingsParticipationCard({required this.trail});

  final DrinkSpotTrailModel trail;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final withinWindow =
        !now.isBefore(trail.availabilityStart) &&
        !now.isAfter(trail.availabilityEnd);
    final availability =
        '${_trailAdminDateTime(trail.availabilityStart)} – ${_trailAdminDateTime(trail.availabilityEnd)}';

    return _TrailGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TrailSectionTitle(
            title: 'Participation',
            subtitle: 'Availability and join behaviour for this trail.',
          ),
          const SizedBox(height: 16),
          _SettingsStatusRow(
            icon: Icons.event_available_rounded,
            label: 'Availability window',
            value: availability,
            positive: trail.availabilityEnd.isAfter(trail.availabilityStart),
          ),
          const SizedBox(height: 10),
          _SettingsStatusRow(
            icon: Icons.schedule_rounded,
            label: 'Currently joinable',
            value: withinWindow ? 'Within window' : 'Outside window',
            positive: withinWindow,
          ),
          const SizedBox(height: 10),
          _SettingsStatusRow(
            icon: Icons.category_rounded,
            label: 'Trail type',
            value: trail.trailType.label,
            positive: true,
          ),
          const SizedBox(height: 12),
          const Text(
            'Users can join this trail during its availability window once it is published and visible.',
            style: TextStyle(color: Colors.white70, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _SettingsRoutePreviewCard extends StatelessWidget {
  const _SettingsRoutePreviewCard({
    required this.hasVenues,
    required this.onPreviewRoute,
  });

  final bool hasVenues;
  final VoidCallback onPreviewRoute;

  @override
  Widget build(BuildContext context) {
    return _TrailGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TrailSectionTitle(
            title: 'Route Preview',
            subtitle: 'Visualise the trail route before publishing.',
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: hasVenues ? onPreviewRoute : null,
              icon: const Icon(Icons.map_rounded),
              label: const Text('Preview Route'),
            ),
          ),
          if (!hasVenues) ...[
            const SizedBox(height: 10),
            const Text(
              'Add venues before previewing the route.',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }
}

class _SettingsStatusRow extends StatelessWidget {
  const _SettingsStatusRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.positive,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: positive ? const Color(0xFFFF2D95) : Colors.white54,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
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

class _SettingsManagementActionsCard extends StatelessWidget {
  const _SettingsManagementActionsCard({
    required this.canManageTrails,
    required this.canDeleteTrails,
    required this.isWorking,
    required this.onDuplicate,
    required this.onArchive,
    required this.onDelete,
  });

  final bool canManageTrails;
  final bool canDeleteTrails;
  final bool isWorking;
  final VoidCallback onDuplicate;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return _TrailGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TrailSectionTitle(
            title: 'Management Actions',
            subtitle: 'Administrative actions for this trail.',
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: canManageTrails && !isWorking ? onDuplicate : null,
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Duplicate'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: canManageTrails && !isWorking ? onArchive : null,
              icon: const Icon(Icons.archive_rounded),
              label: const Text('Archive'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: BorderSide(color: Colors.white.withOpacity(0.16)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: canDeleteTrails && !isWorking ? onDelete : null,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Delete'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF8A8A),
                side: BorderSide(
                  color: const Color(0xFFFF6B6B).withOpacity(0.35),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsDiagnosticsCard extends StatelessWidget {
  const _SettingsDiagnosticsCard();

  @override
  Widget build(BuildContext context) {
    return _TrailGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TrailSectionTitle(
            title: 'Why isn\'t my trail visible?',
            subtitle: 'General guidance for trail visibility.',
          ),
          const SizedBox(height: 16),
          for (final tip in _settingsVisibilityTips) ...[
            _SettingsDiagnosticTip(text: tip),
            if (tip != _settingsVisibilityTips.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _SettingsDiagnosticTip extends StatelessWidget {
  const _SettingsDiagnosticTip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle_outline_rounded,
          size: 18,
          color: Color(0xFFFF2D95),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, height: 1.45),
          ),
        ),
      ],
    );
  }
}

const _settingsVisibilityTips = [
  'Make sure the trail is published.',
  'Make sure it has venues.',
  'Make sure the availability window is valid.',
  'Make sure it has a banner.',
];

String _settingsVisibilityDetail(DrinkSpotTrailModel trail) {
  if (trail.isVisible) {
    return 'This trail currently meets DrinkSpot visibility requirements and can appear in discovery.';
  }

  final reason = trail.visibilityRejectionReason();
  if (reason == null) {
    return 'This trail is not currently visible to users.';
  }
  if (reason.startsWith('not published')) {
    return 'This trail is not published yet. Publish it to make it eligible for discovery.';
  }
  if (reason.startsWith('no stops')) {
    return 'This trail needs at least one venue before it can appear publicly.';
  }
  if (reason.startsWith('availabilityEnd before')) {
    return 'The availability window is invalid. Check the end date is after the start date.';
  }
  if (reason.startsWith('before availabilityStart')) {
    return 'This trail is scheduled for a future date outside the current discovery window.';
  }
  if (reason.startsWith('availabilityEnd in the past')) {
    return 'The availability window has ended, so this trail is no longer visible.';
  }
  return 'This trail is not currently visible to users.';
}

class _TrailGlassPanel extends StatelessWidget {
  const _TrailGlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF111218).withOpacity(0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: child,
    );
  }
}

class _TrailSectionTitle extends StatelessWidget {
  const _TrailSectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}

class _TrailMiniPill extends StatelessWidget {
  const _TrailMiniPill(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.32),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFFFF2D95)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrailVenuePickerScreen extends StatefulWidget {
  const _TrailVenuePickerScreen({required this.future});

  final Future<List<TrailVenueOption>> future;

  @override
  State<_TrailVenuePickerScreen> createState() =>
      _TrailVenuePickerScreenState();
}

class _TrailVenuePickerScreenState extends State<_TrailVenuePickerScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080713),
      appBar: AppBar(
        title: const Text('Add Venue'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<List<TrailVenueOption>>(
        future: widget.future,
        builder: (context, snapshot) {
          final venues = snapshot.data ?? const <TrailVenueOption>[];
          final filtered = venues.where((venue) {
            final q = _query.trim().toLowerCase();
            if (q.isEmpty) return true;
            return venue.name.toLowerCase().contains(q) ||
                venue.address.toLowerCase().contains(q);
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Search venues',
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator())
              else if (filtered.isEmpty)
                const Text(
                  'No venues found.',
                  style: TextStyle(color: Colors.white70),
                )
              else
                ...filtered.map(
                  (venue) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(venue),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.10),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.black.withOpacity(0.35),
                              backgroundImage: venue.logoUrl.trim().isEmpty
                                  ? null
                                  : NetworkImage(venue.logoUrl),
                              child: venue.logoUrl.trim().isEmpty
                                  ? const Icon(Icons.storefront_rounded)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    venue.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    venue.address,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TrailBannerImage extends StatelessWidget {
  const _TrailBannerImage({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A1841), Color(0xFF111218)],
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white54,
            size: 38,
          ),
        ),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      cacheWidth: 900,
      errorBuilder: (_, _, _) => Container(
        color: const Color(0xFF1E2030),
        child: const Icon(
          Icons.image_not_supported_rounded,
          color: Colors.white54,
        ),
      ),
    );
  }
}

class _TrailMetadataDraft {
  final String name;
  final String description;
  final String bannerImageUrl;
  final String area;
  final DateTime availabilityStart;
  final DateTime availabilityEnd;
  final TrailType trailType;
  final TrailStatus status;

  const _TrailMetadataDraft({
    required this.name,
    required this.description,
    required this.bannerImageUrl,
    required this.area,
    required this.availabilityStart,
    required this.availabilityEnd,
    required this.trailType,
    this.status = TrailStatus.draft,
  });
}

class _TrailMetadataDialog extends StatefulWidget {
  final DrinkSpotTrailModel? trail;
  const _TrailMetadataDialog({this.trail});

  @override
  State<_TrailMetadataDialog> createState() => _TrailMetadataDialogState();
}

class _TrailMetadataDialogState extends State<_TrailMetadataDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _bannerController;
  late final TextEditingController _areaController;
  late DateTime _availabilityStart;
  late DateTime _availabilityEnd;
  late TrailType _trailType;
  late TrailStatus _status;

  @override
  void initState() {
    super.initState();
    final trail = widget.trail;
    final now = DateTime.now();
    _nameController = TextEditingController(
      text: trail?.name ?? "Tonight's New Trail",
    );
    _descriptionController = TextEditingController(
      text: trail?.description ?? 'Describe the night out.',
    );
    _bannerController = TextEditingController(
      text: trail?.bannerImageUrl ?? '',
    );
    _areaController = TextEditingController(text: trail?.area ?? 'City Centre');
    _availabilityStart =
        trail?.availabilityStart ?? DateTime(now.year, now.month, now.day, 19);
    _availabilityEnd =
        trail?.availabilityEnd ??
        DateTime(now.year, now.month, now.day, 23, 59);
    _trailType = trail?.trailType ?? TrailType.curated;
    _status = trail?.status ?? TrailStatus.draft;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _bannerController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool start}) async {
    final current = start ? _availabilityStart : _availabilityEnd;
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null || !mounted) return;

    final next = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (start) {
        _availabilityStart = next;
        if (_availabilityEnd.isBefore(_availabilityStart)) {
          _availabilityEnd = _availabilityStart.add(const Duration(hours: 4));
        }
      } else {
        _availabilityEnd = next;
      }
    });
  }

  void _submit() {
    Navigator.of(context).pop(
      _TrailMetadataDraft(
        name: _nameController.text,
        description: _descriptionController.text,
        bannerImageUrl: _bannerController.text,
        area: _areaController.text,
        availabilityStart: _availabilityStart,
        availabilityEnd: _availabilityEnd,
        trailType: _trailType,
        status: _status,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.trail == null ? 'Create New Trail' : 'Edit Trail'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _bannerController,
                decoration: const InputDecoration(
                  labelText: 'Banner Image URL',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _areaController,
                decoration: const InputDecoration(labelText: 'Area'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<TrailType>(
                value: _trailType,
                decoration: const InputDecoration(labelText: 'Trail Type'),
                items: TrailType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _trailType = value);
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<TrailStatus>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items:
                    const [
                          TrailStatus.draft,
                          TrailStatus.published,
                          TrailStatus.archived,
                        ]
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(status.label),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDateTime(start: true),
                      icon: const Icon(Icons.event_available_rounded),
                      label: Text(
                        'Start ${_trailAdminDateTime(_availabilityStart)}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDateTime(start: false),
                      icon: const Icon(Icons.event_busy_rounded),
                      label: Text(
                        'End ${_trailAdminDateTime(_availabilityEnd)}',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}

class _TrailEditorCard extends StatefulWidget {
  final DrinkSpotTrailModel trail;
  final bool canManageTrails;

  const _TrailEditorCard({
    super.key,
    required this.trail,
    required this.canManageTrails,
  });

  @override
  State<_TrailEditorCard> createState() => _TrailEditorCardState();
}

class _TrailEditorCardState extends State<_TrailEditorCard> {
  late List<TrailStopModel> _stops;
  bool _saving = false;
  Future<List<TrailVenueOption>>? _venueOptionsFuture;

  @override
  void initState() {
    super.initState();
    _stops = _renumber(widget.trail.stops);
  }

  @override
  void didUpdateWidget(covariant _TrailEditorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trail.generatedAt != widget.trail.generatedAt ||
        oldWidget.trail.stops.length != widget.trail.stops.length) {
      _stops = _renumber(widget.trail.stops);
    }
  }

  List<TrailStopModel> _renumber(List<TrailStopModel> stops) {
    return [
      for (var i = 0; i < stops.length; i++) stops[i].copyWith(order: i + 1),
    ];
  }

  void _replaceStop(int index, TrailStopModel stop) {
    setState(() {
      _stops[index] = stop.copyWith(order: index + 1);
      _stops = _renumber(_stops);
    });
  }

  Future<void> _saveDraft() async {
    if (_saving || !widget.canManageTrails) return;
    setState(() => _saving = true);
    try {
      await TrailService.saveTrailStops(_stops, trailId: widget.trail.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trail edits saved as draft. Publish when ready.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save trail edits: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickTime(int index, bool isArrival) async {
    final current = isArrival ? _stops[index].arriveAt : _stops[index].leaveAt;
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (selected == null || !mounted) return;

    final updated = DateTime(
      current.year,
      current.month,
      current.day,
      selected.hour,
      selected.minute,
    );

    _replaceStop(
      index,
      isArrival
          ? _stops[index].copyWith(arriveAt: updated)
          : _stops[index].copyWith(leaveAt: updated),
    );
  }

  Future<void> _swapVenue(int index) async {
    final selected = await showDialog<TrailVenueOption>(
      context: context,
      builder: (_) => const _TrailVenuePickerDialog(),
    );
    if (selected == null || !mounted) return;

    _replaceStop(
      index,
      _stops[index].copyWith(
        venueId: selected.id,
        venueName: selected.name,
        address: selected.address,
        bannerImageUrl: selected.bannerImageUrl,
        logoUrl: selected.logoUrl,
      ),
    );
  }

  Future<void> _addVenue() async {
    if (!widget.canManageTrails) return;
    _venueOptionsFuture ??= TrailService.fetchVenueOptions();
    final venue = await Navigator.of(context).push<TrailVenueOption>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _TrailVenuePickerScreen(future: _venueOptionsFuture!),
      ),
    );
    if (venue == null || !mounted) return;

    final arriveAt = _stops.isEmpty
        ? widget.trail.availabilityStart
        : _stops.last.leaveAt.add(const Duration(minutes: 15));
    final leaveAt = arriveAt.add(const Duration(minutes: 75));

    setState(() {
      _stops = _renumber([
        ..._stops,
        TrailStopModel(
          venueId: venue.id,
          venueName: venue.name,
          address: venue.address,
          bannerImageUrl: venue.bannerImageUrl,
          logoUrl: venue.logoUrl,
          order: _stops.length + 1,
          score: 0,
          arriveAt: arriveAt,
          leaveAt: leaveAt,
        ),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: _TrailSectionTitle(
                title: 'Route Builder',
                subtitle: 'Build your trail route stop by stop.',
              ),
            ),
            FilledButton.icon(
              onPressed: widget.canManageTrails && !_saving ? _saveDraft : null,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: const Text('Save Venues'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (!widget.canManageTrails)
          const _TrailGlassPanel(
            child: Text(
              'Only Management and Founder roles can edit trails.',
              style: TextStyle(color: Colors.white70),
            ),
          )
        else if (_stops.isEmpty)
          _VenueEmptyState(onAddFirstVenue: _addVenue)
        else ...[
          for (var i = 0; i < _stops.length; i++) ...[
            _VenueRouteCard(
              key: ValueKey('${_stops[i].venueId}-${_stops[i].order}'),
              stop: _stops[i],
              canMoveUp: i > 0,
              canMoveDown: i < _stops.length - 1,
              onMoveUp: () => setState(() {
                final item = _stops.removeAt(i);
                _stops.insert(i - 1, item);
                _stops = _renumber(_stops);
              }),
              onMoveDown: () => setState(() {
                final item = _stops.removeAt(i);
                _stops.insert(i + 1, item);
                _stops = _renumber(_stops);
              }),
              onRemove: () => setState(() {
                _stops.removeAt(i);
                _stops = _renumber(_stops);
              }),
              onSwapVenue: () => _swapVenue(i),
              onArrivalTap: () => _pickTime(i, true),
              onLeaveTap: () => _pickTime(i, false),
              onDiscountChanged: (value) =>
                  _replaceStop(i, _stops[i].copyWith(discountLabel: value)),
            ),
            if (i < _stops.length - 1) const _RouteConnector(),
          ],
          const SizedBox(height: 16),
          _AddVenueCard(onTap: _addVenue),
        ],
      ],
    );
  }
}

class _VenueRouteCard extends StatelessWidget {
  const _VenueRouteCard({
    super.key,
    required this.stop,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
    required this.onSwapVenue,
    required this.onArrivalTap,
    required this.onLeaveTap,
    required this.onDiscountChanged,
  });

  final TrailStopModel stop;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;
  final VoidCallback onSwapVenue;
  final VoidCallback onArrivalTap;
  final VoidCallback onLeaveTap;
  final ValueChanged<String> onDiscountChanged;

  @override
  Widget build(BuildContext context) {
    return _TrailGlassPanel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: SizedBox(
              height: 108,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _TrailBannerImage(url: stop.bannerImageUrl),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.08),
                          Colors.black.withOpacity(0.78),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    top: 12,
                    child: Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF2D95).withOpacity(0.92),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF2D95).withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        stop.order.toString().padLeft(2, '0'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 78,
                    right: 14,
                    bottom: 12,
                    child: Row(
                      children: [
                        _VenueRouteLogo(url: stop.logoUrl),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            stop.venueName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (stop.address.isNotEmpty) ...[
                  Text(
                    stop.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                ],
                _VenueRouteMetaRow(venueId: stop.venueId),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.drag_indicator_rounded,
                            color: Colors.white.withOpacity(0.72),
                            size: 22,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Reorder',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Move stop up',
                      onPressed: canMoveUp ? onMoveUp : null,
                      icon: const Icon(Icons.keyboard_arrow_up_rounded),
                    ),
                    IconButton(
                      tooltip: 'Move stop down',
                      onPressed: canMoveDown ? onMoveDown : null,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    ),
                    IconButton(
                      tooltip: 'Remove stop',
                      onPressed: onRemove,
                      icon: const Icon(Icons.close_rounded),
                      color: const Color(0xFFFF6B6B),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onSwapVenue,
                      icon: const Icon(Icons.swap_horiz_rounded),
                      label: const Text('Swap venue'),
                    ),
                    OutlinedButton.icon(
                      onPressed: onArrivalTap,
                      icon: const Icon(Icons.login_rounded),
                      label: Text('Arrive ${_trailAdminTime(stop.arriveAt)}'),
                    ),
                    OutlinedButton.icon(
                      onPressed: onLeaveTap,
                      icon: const Icon(Icons.logout_rounded),
                      label: Text('Leave ${_trailAdminTime(stop.leaveAt)}'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: stop.discountLabel,
                  onChanged: onDiscountChanged,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Trail discount label',
                    hintText: 'e.g. 10% off, 2-for-1 cocktails, free shot',
                    helperText:
                        'Only use this if the venue has agreed to the trail offer.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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

class _VenueRouteLogo extends StatelessWidget {
  const _VenueRouteLogo({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.18)),
        color: const Color(0xFF111218),
      ),
      clipBehavior: Clip.antiAlias,
      child: url.trim().isEmpty
          ? const Icon(
              Icons.storefront_rounded,
              color: Colors.white54,
              size: 20,
            )
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(
                Icons.storefront_rounded,
                color: Colors.white54,
                size: 20,
              ),
            ),
    );
  }
}

class _VenueRouteMetaRow extends StatelessWidget {
  const _VenueRouteMetaRow({required this.venueId});

  final String venueId;

  @override
  Widget build(BuildContext context) {
    if (venueId.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('venues')
          .doc(venueId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final category = _venueCategoryLabel(data);
        final openStatus = _venueOpenStatusLabel(data);
        if (category == null && openStatus == null) {
          return const SizedBox.shrink();
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (category != null)
              _TrailMiniPill(Icons.category_rounded, category),
            if (openStatus != null)
              _TrailMiniPill(
                openStatus.isOpen
                    ? Icons.check_circle_rounded
                    : Icons.schedule_rounded,
                openStatus.label,
              ),
          ],
        );
      },
    );
  }
}

class _VenueOpenStatusView {
  const _VenueOpenStatusView({required this.isOpen, required this.label});

  final bool isOpen;
  final String label;
}

class _RouteConnector extends StatelessWidget {
  const _RouteConnector();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Icon(
            Icons.arrow_downward_rounded,
            color: Colors.white.withOpacity(0.42),
            size: 22,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text('🚶', style: TextStyle(fontSize: 16)),
              SizedBox(width: 6),
              Text(
                'Walking Time',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Coming Soon',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Walking Distance',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Coming Soon',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddVenueCard extends StatelessWidget {
  const _AddVenueCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: _TrailGlassPanel(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF2D95).withOpacity(0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFF2D95).withOpacity(0.28),
                  ),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Color(0xFFFF2D95),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Venue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Add another stop to this trail.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VenueEmptyState extends StatelessWidget {
  const _VenueEmptyState({required this.onAddFirstVenue});

  final VoidCallback onAddFirstVenue;

  @override
  Widget build(BuildContext context) {
    return _TrailGlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          const Icon(
            Icons.location_on_rounded,
            size: 56,
            color: Color(0xFFFF2D95),
          ),
          const SizedBox(height: 18),
          const Text(
            'No venues added yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Start building your trail route by adding the first venue stop.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAddFirstVenue,
              icon: const Icon(Icons.add_location_alt_rounded),
              label: const Text('Add First Venue'),
            ),
          ),
        ],
      ),
    );
  }
}

String? _venueCategoryLabel(Map<String, dynamic>? data) {
  if (data == null) return null;
  final category = (data['category'] ?? data['venueType'] ?? '')
      .toString()
      .trim();
  return category.isEmpty ? null : category;
}

_VenueOpenStatusView? _venueOpenStatusLabel(Map<String, dynamic>? data) {
  if (data == null) return null;
  final hours = data['openingHours'];
  if (hours is! Map || hours.isEmpty) return null;

  const dayKeys = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];
  final today = dayKeys[DateTime.now().weekday - 1];
  final day = hours[today];
  if (day is! Map) {
    return const _VenueOpenStatusView(isOpen: false, label: 'Closed');
  }
  if (day['closed'] == true || day['isClosed'] == true) {
    return const _VenueOpenStatusView(isOpen: false, label: 'Closed');
  }

  int? parseMinutes(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return null;
    final parts = text.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }

  final open = parseMinutes(day['open']);
  final close = parseMinutes(day['close']);
  if (open == null || close == null) {
    return const _VenueOpenStatusView(isOpen: false, label: 'Hours listed');
  }

  final nowMinutes = DateTime.now().hour * 60 + DateTime.now().minute;
  final isOpen = close <= open
      ? nowMinutes >= open || nowMinutes < close
      : nowMinutes >= open && nowMinutes < close;

  return _VenueOpenStatusView(
    isOpen: isOpen,
    label: isOpen ? 'Open' : 'Closed',
  );
}

class _TrailVenuePickerDialog extends StatefulWidget {
  const _TrailVenuePickerDialog();

  @override
  State<_TrailVenuePickerDialog> createState() =>
      _TrailVenuePickerDialogState();
}

class _TrailVenuePickerDialogState extends State<_TrailVenuePickerDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Swap venue'),
      content: SizedBox(
        width: 520,
        height: 520,
        child: FutureBuilder<List<TrailVenueOption>>(
          future: TrailService.fetchVenueOptions(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final venues = snapshot.data ?? const <TrailVenueOption>[];
            final filtered = venues.where((venue) {
              final q = _query.toLowerCase().trim();
              if (q.isEmpty) return true;
              return venue.name.toLowerCase().contains(q) ||
                  venue.address.toLowerCase().contains(q);
            }).toList();

            return Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search venues',
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('No venues found'))
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final venue = filtered[index];
                            return ListTile(
                              title: Text(venue.name),
                              subtitle: venue.address.isEmpty
                                  ? null
                                  : Text(venue.address),
                              onTap: () => Navigator.pop(context, venue),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _TrailAdminChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrailAdminChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF9D28FF).withOpacity(0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF9D28FF)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

String _trailAdminTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _trailAdminDateTime(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month ${_trailAdminTime(value)}';
}

String _formatTrailDuration(Duration duration) {
  final minutes = duration.inMinutes;
  if (minutes <= 0) return 'TBC';
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final remaining = minutes % 60;
  if (remaining == 0) return '${hours}h';
  return '${hours}h ${remaining}m';
}

IconData _trailStatusIcon(DrinkSpotTrailModel trail) {
  switch (trail.status) {
    case TrailStatus.published:
      return Icons.circle;
    case TrailStatus.draft:
      return Icons.circle;
    case TrailStatus.archived:
    case TrailStatus.disabled:
      return Icons.circle;
  }
}

String _trailStatusLabel(DrinkSpotTrailModel trail) {
  switch (trail.status) {
    case TrailStatus.published:
      return '🟢 Published';
    case TrailStatus.draft:
      return '🟡 Draft';
    case TrailStatus.archived:
    case TrailStatus.disabled:
      return '⚫ Archived';
  }
}

class _AccountSupportPanel extends StatefulWidget {
  final StaffRole role;
  const _AccountSupportPanel({required this.role});

  @override
  State<_AccountSupportPanel> createState() => _AccountSupportPanelState();
}

class _AccountSupportPanelState extends State<_AccountSupportPanel> {
  String _query = '';
  SupportedAccountType? _type;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('accounts'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageHeader(
          title: 'Account Support',
          subtitle:
              'Support normal user, venue and artist accounts from one screen.',
        ),
        _SearchAndFilters(
          hint: 'Search by name, email, city, UID, venue or artist name...',
          onChanged: (value) => setState(() => _query = value.toLowerCase()),
          filter: DropdownButton<SupportedAccountType?>(
            value: _type,
            hint: const Text('All account types'),
            items: [
              const DropdownMenuItem<SupportedAccountType?>(
                value: null,
                child: Text('All account types'),
              ),
              ...SupportedAccountType.values.map(
                (type) =>
                    DropdownMenuItem(value: type, child: Text(type.label)),
              ),
            ],
            onChanged: (value) => setState(() => _type = value),
          ),
        ),
        _StreamList(
          stream: AdminOperationsService.accountsStream(),
          emptyText: 'No accounts found yet.',
          fallback: _sampleAccounts,
          itemBuilder: (context, id, data) {
            final type = SupportedAccountTypeX.fromValue(
              data['accountType'] ?? data['role'],
            );
            final name = _display(data, [
              'name',
              'displayName',
              'venueName',
              'artistName',
            ], 'Unnamed account');
            final email = _display(data, ['email'], 'No email');
            final haystack =
                '$name $email ${data['city'] ?? ''} $id ${type.label}'
                    .toLowerCase();
            if (_type != null && _type != type) return const SizedBox.shrink();
            if (_query.isNotEmpty && !haystack.contains(_query))
              return const SizedBox.shrink();

            return _AdminRecordCard(
              icon: _accountTypeIcon(type),
              title: name,
              subtitle: '${type.label} • $email',
              chips: [
                data['status']?.toString() ?? 'active',
                data['verified'] == true ? 'verified' : 'unverified',
                if ((data['reports'] ?? 0) != 0) '${data['reports']} reports',
              ],
              actions: [
                OutlinedButton.icon(
                  onPressed: () => _showAccountDetails(context, id, data),
                  icon: const Icon(Icons.visibility),
                  label: const Text('View'),
                ),
                OutlinedButton.icon(
                  onPressed: email == 'No email'
                      ? null
                      : () => _sendReset(context, email),
                  icon: const Icon(Icons.lock_reset),
                  label: const Text('Password reset'),
                ),
                if (widget.role.canEditFullContent)
                  FilledButton.icon(
                    onPressed: () => _updateStatus(context, id, 'suspended'),
                    icon: const Icon(Icons.block),
                    label: const Text('Suspend'),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _VenuePanel extends StatefulWidget {
  final StaffRole role;
  const _VenuePanel({required this.role});

  @override
  State<_VenuePanel> createState() => _VenuePanelState();
}

class _VenuePanelState extends State<_VenuePanel> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('venues'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageHeader(
          title: 'Venue Management',
          subtitle: widget.role == StaffRole.support
              ? 'Support can safely change venue names/images and recover venue content.'
              : 'Manage venue profiles, verification, ownership, status, images and reports.',
          action: widget.role.canEditFullContent
              ? FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Add Venue'),
                )
              : null,
        ),
        _SearchAndFilters(
          hint: 'Search venues...',
          onChanged: (value) => setState(() => _query = value.toLowerCase()),
        ),
        _StreamList(
          stream: AdminOperationsService.venuesStream(),
          emptyText: 'No venues found yet.',
          fallback: _sampleVenues,
          itemBuilder: (context, id, data) {
            final name = _display(data, ['name', 'venueName'], 'Unnamed venue');
            final haystack =
                '$name ${data['city'] ?? ''} ${data['ownerEmail'] ?? ''} $id'
                    .toLowerCase();
            if (_query.isNotEmpty && !haystack.contains(_query))
              return const SizedBox.shrink();
            return _AdminRecordCard(
              icon: Icons.storefront,
              title: name,
              subtitle:
                  '${data['city'] ?? 'Unknown city'} • ${data['ownerEmail'] ?? data['ownerUid'] ?? 'No owner'}',
              chips: [
                data['status']?.toString() ?? 'active',
                data['verified'] == true ? 'verified' : 'unverified',
              ],
              actions: [
                OutlinedButton.icon(
                  onPressed: () => _editVenueSupport(context, id, name),
                  icon: const Icon(Icons.edit),
                  label: const Text('Name'),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.image),
                  label: const Text('Images'),
                ),
                if (widget.role.canEditFullContent)
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.tune),
                    label: const Text('Full edit'),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CollectionPanel extends StatefulWidget {
  final String title;
  final String subtitle;
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final IconData icon;
  final StaffRole role;

  const _CollectionPanel({
    required this.title,
    required this.subtitle,
    required this.stream,
    required this.icon,
    required this.role,
  });

  @override
  State<_CollectionPanel> createState() => _CollectionPanelState();
}

class _CollectionPanelState extends State<_CollectionPanel> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey(widget.title),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageHeader(
          title: widget.title,
          subtitle: widget.subtitle,
          action: FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: Text(
              'Add ${widget.title.substring(0, widget.title.length - 1)}',
            ),
          ),
        ),
        _SearchAndFilters(
          hint: 'Search ${widget.title.toLowerCase()}...',
          onChanged: (value) => setState(() => _query = value.toLowerCase()),
        ),
        _StreamList(
          stream: widget.stream,
          emptyText: 'No ${widget.title.toLowerCase()} found yet.',
          fallback: _fallbackFor(widget.title),
          itemBuilder: (context, id, data) {
            final name = _display(data, ['name', 'title'], 'Untitled');
            final venue = _display(data, ['venueName', 'venueId'], 'No venue');
            final haystack = '$name $venue ${data['status'] ?? ''} $id'
                .toLowerCase();
            if (_query.isNotEmpty && !haystack.contains(_query))
              return const SizedBox.shrink();
            return _AdminRecordCard(
              icon: widget.icon,
              title: name,
              subtitle: venue,
              chips: [
                data['status']?.toString() ?? 'active',
                if (data['price'] != null) '£${data['price']}',
              ],
              actions: [
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.visibility_off),
                  label: const Text('Hide'),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _UsersPanel extends StatelessWidget {
  final StaffRole role;
  const _UsersPanel({required this.role});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('users'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageHeader(
          title: 'Users',
          subtitle:
              'Review users, venue owners, artists, suspensions and account deletion requests.',
        ),
        const _MetricGrid(
          cards: [
            _Metric(
              'Total Users',
              '92,184',
              Icons.people,
              'Normal app accounts',
            ),
            _Metric(
              'Venue Owners',
              '1,106',
              Icons.business,
              'Linked to venues',
            ),
            _Metric(
              'Artist Accounts',
              '384',
              Icons.music_note,
              'DJs and performers',
            ),
            _Metric(
              'Deletion Requests',
              '11',
              Icons.delete_outline,
              'Pending review',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _InfoCard(
          title: 'User account controls',
          lines: [
            'Users can manage their own password, details, notification preferences, privacy settings and account deletion requests.',
            'Venue accounts can manage venue details, opening hours, images, drinks, deals, events and team members.',
            'Artist accounts can manage artist profiles, genres, availability, booking contacts, socials and performances.',
          ],
        ),
      ],
    );
  }
}

class _ReportsPanel extends StatelessWidget {
  final StaffRole role;
  const _ReportsPanel({required this.role});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('reports'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageHeader(
          title: 'Reports & Moderation',
          subtitle:
              'Reported venues, images, drinks, deals, users, venue accounts and artist accounts.',
        ),
        _StreamList(
          stream: AdminOperationsService.reportsStream(),
          emptyText: 'No reports yet.',
          fallback: _sampleReports,
          itemBuilder: (context, id, data) => _AdminRecordCard(
            icon: Icons.report,
            title: _display(data, ['type', 'title'], 'Report'),
            subtitle: _display(data, ['targetName', 'targetId'], id),
            chips: [
              data['severity']?.toString() ?? 'low',
              data['status']?.toString() ?? 'open',
            ],
            actions: [
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecoveryPanel extends StatelessWidget {
  final StaffRole role;
  const _RecoveryPanel({required this.role});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('recovery'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageHeader(
          title: 'Recovery Centre',
          subtitle:
              'Restore deleted venues, drinks, deals, events, images, users, venue accounts and artist accounts.',
        ),
        _StreamList(
          stream: AdminOperationsService.deletedItemsStream(),
          emptyText: 'No deleted items found.',
          fallback: _sampleDeleted,
          itemBuilder: (context, id, data) => _AdminRecordCard(
            icon: Icons.restore_from_trash,
            title: _display(data, [
              'name',
              'title',
              'originalId',
            ], 'Deleted item'),
            subtitle:
                '${data['itemType'] ?? 'item'} • deleted by ${data['deletedBy'] ?? 'unknown'}',
            chips: [data['restored'] == true ? 'restored' : 'deleted'],
            actions: [
              FilledButton.icon(
                onPressed: () => _restore(context, id),
                icon: const Icon(Icons.restore),
                label: const Text('Restore'),
              ),
              if (role.canHardDelete)
                OutlinedButton.icon(
                  onPressed: () => _hardDelete(context, id),
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Permanent delete'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StaffPanel extends StatefulWidget {
  final StaffRole role;
  const _StaffPanel({required this.role});

  @override
  State<_StaffPanel> createState() => _StaffPanelState();
}

class _StaffPanelState extends State<_StaffPanel> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  StaffRole _newRole = StaffRole.support;

  @override
  Widget build(BuildContext context) {
    final assignableRoles = StaffRole.values
        .where(widget.role.canAssign)
        .toList();
    if (!assignableRoles.contains(_newRole)) _newRole = assignableRoles.first;

    return Column(
      key: const ValueKey('staff'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageHeader(
          title: 'Staff Management',
          subtitle:
              'Management can create Support/Admin staff. Founder can assign Management and Founder roles.',
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create staff invite',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 12),
                Wrap(
                  runSpacing: 12,
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 230,
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 260,
                      child: TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                    ),
                    SizedBox(
                      width: 240,
                      child: DropdownButtonFormField<StaffRole>(
                        value: _newRole,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items: assignableRoles
                            .map(
                              (role) => DropdownMenuItem(
                                value: role,
                                child: Text(role.label),
                              ),
                            )
                            .toList(),
                        onChanged: (role) => setState(
                          () => _newRole = role ?? StaffRole.support,
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => _createInvite(context),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Create invite'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _StreamList(
          stream: AdminOperationsService.staffStream(),
          emptyText: 'No staff accounts found yet.',
          fallback: _sampleStaff,
          itemBuilder: (context, id, data) {
            final targetRole = StaffRoleX.fromValue(data['role']);
            return _AdminRecordCard(
              icon: Icons.admin_panel_settings,
              title: _display(data, ['displayName', 'name'], 'Staff member'),
              subtitle: _display(data, ['email'], id),
              chips: [
                targetRole.label,
                data['status']?.toString() ?? 'active',
                data['twoFactorRequired'] == true
                    ? '2FA required'
                    : '2FA optional',
              ],
              actions: [
                OutlinedButton.icon(
                  onPressed: widget.role.canManageStaffMember(targetRole)
                      ? () => AdminOperationsService.disableStaff(id)
                      : null,
                  icon: const Icon(Icons.block),
                  label: const Text('Disable'),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _createInvite(BuildContext context) async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and email are required')),
      );
      return;
    }
    if (!widget.role.canAssign(_newRole)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot assign this role')),
      );
      return;
    }
    await AdminOperationsService.createStaffInvite(
      email: _emailController.text,
      displayName: _nameController.text,
      role: _newRole,
    );
    _nameController.clear();
    _emailController.clear();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Staff invite created')));
  }
}

class _SelfServicePanel extends StatelessWidget {
  const _SelfServicePanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('self-service'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageHeader(
          title: 'User Self-Service',
          subtitle:
              'Areas users, venues and artists can manage themselves inside the app.',
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 900;
            return GridView.count(
              crossAxisCount: wide ? 3 : 1,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: wide ? 1.1 : 1.8,
              children: const [
                _SelfServiceCard(
                  title: 'Normal User Account',
                  icon: Icons.person,
                  fields: [
                    'Profile photo',
                    'Display name',
                    'Email address',
                    'Phone number',
                    'Change password',
                    'Notification preferences',
                    'Privacy settings',
                    'Saved venues',
                    'Favourite drinks',
                    'Blocked users',
                    'Delete account request',
                  ],
                ),
                _SelfServiceCard(
                  title: 'Venue Account',
                  icon: Icons.storefront,
                  fields: [
                    'Venue profile',
                    'Venue pictures',
                    'Opening hours',
                    'Drinks menu',
                    'Deals',
                    'Events',
                    'Venue team members',
                    'Subscription plan',
                    'Notification settings',
                  ],
                ),
                _SelfServiceCard(
                  title: 'Artist Account',
                  icon: Icons.music_note,
                  fields: [
                    'Artist profile',
                    'Profile pictures',
                    'Genre/categories',
                    'Availability',
                    'Booking contact details',
                    'Social media links',
                    'Upcoming performances',
                    'Notification settings',
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _AnalyticsPanel extends StatelessWidget {
  final StaffRole role;
  const _AnalyticsPanel({required this.role});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('analytics'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageHeader(
          title: 'Analytics',
          subtitle:
              'Operational analytics for Management/Admin. Financial analytics remain Founder-only.',
        ),
        _MetricGrid(
          cards: [
            const _Metric(
              'Searches Today',
              '18,482',
              Icons.search,
              'Drink, venue and city searches',
            ),
            const _Metric(
              'Most Active City',
              'London',
              Icons.location_city,
              '32% of traffic',
            ),
            const _Metric(
              'Deal Clicks',
              '6,209',
              Icons.local_offer,
              'Last 7 days',
            ),
            const _Metric(
              'Venue Views',
              '44,102',
              Icons.visibility,
              'Last 7 days',
            ),
            if (role.canViewFinancials)
              const _Metric(
                'Revenue Conversion',
                '£9.8k',
                Icons.payments,
                'Founder only',
              ),
          ],
        ),
      ],
    );
  }
}

class _FounderOnlyPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Map<String, String> metrics;

  const _FounderOnlyPanel({
    required this.title,
    required this.subtitle,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey(title),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageHeader(title: title, subtitle: subtitle),
        _MetricGrid(
          cards: metrics.entries
              .map(
                (e) => _Metric(e.key, e.value, Icons.insights, 'Founder-only'),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _AuditPanel extends StatelessWidget {
  final StaffRole role;
  const _AuditPanel({required this.role});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('audit'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageHeader(
          title: 'Audit Logs',
          subtitle:
              'Immutable staff action history for accountability and recovery.',
        ),
        _StreamList(
          stream: AdminOperationsService.auditLogsStream(),
          emptyText: 'No audit logs yet.',
          fallback: _sampleAudit,
          itemBuilder: (context, id, data) => _AdminRecordCard(
            icon: Icons.history,
            title: data['action']?.toString() ?? 'Action',
            subtitle:
                '${data['actorEmail'] ?? data['actorUid'] ?? 'Unknown'} • ${data['targetType'] ?? 'target'}: ${data['targetId'] ?? id}',
            chips: [
              data['createdAt'] is Timestamp
                  ? (data['createdAt'] as Timestamp).toDate().toString()
                  : 'logged',
            ],
            actions: const [],
          ),
        ),
      ],
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  final StaffRole role;
  const _SettingsPanel({required this.role});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('settings'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageHeader(
          title: 'App Settings',
          subtitle:
              'Management can view operational settings. Founder can edit critical platform settings.',
        ),
        _InfoCard(
          title: 'Protected settings',
          lines: [
            'Venue auto-approval: ${role.canViewFinancials ? 'editable' : 'view only'}',
            'Push notification approval flow: ${role.canViewFinancials ? 'editable' : 'view only'}',
            'Staff 2FA enforcement: ${role.canViewFinancials ? 'editable' : 'view only'}',
            'Maintenance mode: Founder only',
          ],
        ),
      ],
    );
  }
}

class _PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;

  const _PageHeader({required this.title, required this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.white.withOpacity(0.68)),
                ),
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  final List<_Metric> cards;
  const _MetricGrid({required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final width = constraints.maxWidth;
        final columns = width > 1050
            ? 4
            : width > 700
            ? 2
            : 1;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: columns == 1 ? 3.2 : 2.2,
          children: cards.map((metric) => _MetricCard(metric)).toList(),
        );
      },
    );
  }
}

class _Metric {
  final String label;
  final String value;
  final IconData icon;
  final String helper;
  const _Metric(this.label, this.value, this.icon, this.helper);
}

class _MetricCard extends StatelessWidget {
  final _Metric metric;
  const _MetricCard(this.metric);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: primary.withOpacity(0.12),
              child: Icon(metric.icon, color: primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(metric.label, style: const TextStyle(fontSize: 13)),
                  Text(
                    metric.value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    metric.helper,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<String> lines;
  const _InfoCard({required this.title, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 18,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(line)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminRecordCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> chips;
  final List<Widget> actions;

  const _AdminRecordCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.chips,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 12,
          spacing: 12,
          children: [
            SizedBox(
              width: 420,
              child: Row(
                children: [
                  CircleAvatar(child: Icon(icon)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.68),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: chips
                              .where((chip) => chip.trim().isNotEmpty)
                              .map(_RoleChip.new)
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  const _RoleChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9FE),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF9D28FF).withOpacity(0.65)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: Color(0xFF3B0764),
        ),
      ),
    );
  }
}

class _SearchAndFilters extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final Widget? filter;

  const _SearchAndFilters({
    required this.hint,
    required this.onChanged,
    this.filter,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: onChanged,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: hint,
                ),
              ),
            ),
            if (filter != null) ...[const SizedBox(width: 12), filter!],
          ],
        ),
      ),
    );
  }
}

class _StreamList extends StatelessWidget {
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final String emptyText;
  final List<MapEntry<String, Map<String, dynamic>>> fallback;
  final Widget Function(
    BuildContext context,
    String id,
    Map<String, dynamic> data,
  )
  itemBuilder;

  const _StreamList({
    required this.stream,
    required this.emptyText,
    required this.itemBuilder,
    this.fallback = const [],
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            fallback.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs =
            snapshot.data?.docs
                .map((doc) => MapEntry(doc.id, doc.data()))
                .toList() ??
            fallback;
        if (docs.isEmpty) return _EmptyPanel(text: emptyText);

        return Column(
          children: docs
              .map((entry) => itemBuilder(context, entry.key, entry.value))
              .where((widget) => widget is! SizedBox || widget.height != 0)
              .toList(),
        );
      },
    );
  }
}

class _SelfServiceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> fields;

  const _SelfServiceCard({
    required this.title,
    required this.icon,
    required this.fields,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Icon(icon)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: fields
                    .map(
                      (field) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(field),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final String text;
  const _EmptyPanel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: Text(text)),
      ),
    );
  }
}

class _LockedPanel extends StatelessWidget {
  const _LockedPanel();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('Access denied for your staff role.')),
      ),
    );
  }
}

String _display(Map<String, dynamic> data, List<String> keys, String fallback) {
  for (final key in keys) {
    final value = data[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return fallback;
}

IconData _accountTypeIcon(SupportedAccountType type) {
  switch (type) {
    case SupportedAccountType.normalUser:
      return Icons.person;
    case SupportedAccountType.venue:
      return Icons.storefront;
    case SupportedAccountType.artist:
      return Icons.music_note;
  }
}

List<MapEntry<String, Map<String, dynamic>>> _fallbackFor(String title) {
  if (title == 'Drinks') return _sampleDrinks;
  if (title == 'Deals') return _sampleDeals;
  if (title == 'Events') return _sampleEvents;
  return const [];
}

Future<void> _sendReset(BuildContext context, String email) async {
  try {
    await AdminOperationsService.sendPasswordReset(email);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Password reset sent to $email')));
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Could not send reset: $error')));
  }
}

Future<void> _updateStatus(
  BuildContext context,
  String uid,
  String status,
) async {
  await AdminOperationsService.updateAccountStatus(uid: uid, status: status);
  if (!context.mounted) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('Account marked as $status')));
}

Future<void> _restore(BuildContext context, String id) async {
  await AdminOperationsService.restoreDeletedItem(id);
  if (!context.mounted) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Item restored')));
}

Future<void> _hardDelete(BuildContext context, String id) async {
  await AdminOperationsService.hardDeleteDeletedItem(id);
  if (!context.mounted) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Item permanently deleted')));
}

Future<void> _editVenueSupport(
  BuildContext context,
  String venueId,
  String currentName,
) async {
  final controller = TextEditingController(text: currentName);
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit venue name'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(labelText: 'Venue name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  if (result == null || result.trim().isEmpty) return;
  await AdminOperationsService.updateVenueSupportFields(
    venueId: venueId,
    name: result,
  );
  if (!context.mounted) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Venue name updated')));
}

void _showAccountDetails(
  BuildContext context,
  String id,
  Map<String, dynamic> data,
) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        _display(data, [
          'name',
          'displayName',
          'venueName',
          'artistName',
        ], 'Account'),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ID: $id'),
            const SizedBox(height: 8),
            ...data.entries
                .take(20)
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('${entry.key}: ${entry.value}'),
                  ),
                ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

const _sampleAccounts = [
  MapEntry('user_001', {
    'name': 'Jamie Carter',
    'email': 'jamie@example.com',
    'accountType': 'user',
    'status': 'active',
    'city': 'London',
    'verified': true,
    'reports': 0,
  }),
  MapEntry('venue_001', {
    'name': 'The Crown Bar Owner',
    'email': 'owner@crownbars.com',
    'accountType': 'venue',
    'status': 'active',
    'city': 'London',
    'verified': true,
    'reports': 1,
  }),
  MapEntry('artist_001', {
    'name': 'DJ Nova',
    'email': 'bookings@djnova.com',
    'accountType': 'artist',
    'status': 'pending',
    'city': 'Manchester',
    'verified': false,
    'reports': 0,
  }),
];

const _sampleVenues = [
  MapEntry('venue_001', {
    'name': 'The Crown Bar',
    'city': 'London',
    'ownerEmail': 'owner@crownbars.com',
    'status': 'active',
    'verified': true,
  }),
  MapEntry('venue_002', {
    'name': 'Neon Lounge',
    'city': 'Manchester',
    'ownerEmail': 'neon@example.com',
    'status': 'pending',
    'verified': false,
  }),
  MapEntry('venue_003', {
    'name': 'Harbour Tap',
    'city': 'Bristol',
    'ownerEmail': 'tap@example.com',
    'status': 'suspended',
    'verified': true,
  }),
];

const _sampleDrinks = [
  MapEntry('drink_001', {
    'name': 'Espresso Martini',
    'venueName': 'The Crown Bar',
    'price': '9.50',
    'status': 'active',
  }),
  MapEntry('drink_002', {
    'name': 'House Lager',
    'venueName': 'Neon Lounge',
    'price': '5.20',
    'status': 'active',
  }),
];

const _sampleDeals = [
  MapEntry('deal_001', {
    'title': '2-for-1 Cocktails',
    'venueName': 'The Crown Bar',
    'status': 'live',
  }),
  MapEntry('deal_002', {
    'title': 'Student Night',
    'venueName': 'Neon Lounge',
    'status': 'scheduled',
  }),
];

const _sampleEvents = [
  MapEntry('event_001', {
    'title': 'Live DJ Night',
    'venueName': 'Neon Lounge',
    'status': 'approved',
  }),
  MapEntry('event_002', {
    'title': 'Quiz Night',
    'venueName': 'The Crown Bar',
    'status': 'pending',
  }),
];

const _sampleReports = [
  MapEntry('report_001', {
    'type': 'Venue image',
    'targetName': 'Neon Lounge',
    'severity': 'medium',
    'status': 'open',
  }),
  MapEntry('report_002', {
    'type': 'Incorrect drink price',
    'targetName': 'House Lager',
    'severity': 'low',
    'status': 'open',
  }),
];

const _sampleDeleted = [
  MapEntry('deleted_001', {
    'itemType': 'deal',
    'name': 'Monday Mojitos',
    'deletedBy': 'Aaron Admin',
    'restored': false,
  }),
  MapEntry('deleted_002', {
    'itemType': 'artist',
    'name': 'DJ Legacy Profile',
    'deletedBy': 'Nina Manager',
    'restored': false,
  }),
];

const _sampleStaff = [
  MapEntry('staff_001', {
    'displayName': 'Mia Support',
    'email': 'mia@appteam.com',
    'role': 'support',
    'status': 'active',
    'twoFactorRequired': false,
  }),
  MapEntry('staff_002', {
    'displayName': 'Aaron Admin',
    'email': 'aaron@appteam.com',
    'role': 'admin',
    'status': 'active',
    'twoFactorRequired': true,
  }),
  MapEntry('staff_003', {
    'displayName': 'Nina Manager',
    'email': 'nina@appteam.com',
    'role': 'management',
    'status': 'active',
    'twoFactorRequired': true,
  }),
  MapEntry('staff_004', {
    'displayName': 'Founder Account',
    'email': 'owner@app.com',
    'role': 'founder',
    'status': 'active',
    'twoFactorRequired': true,
  }),
];

const _sampleAudit = [
  MapEntry('log_001', {
    'actorEmail': 'mia@appteam.com',
    'action': 'VENUE_IMAGE_CHANGED',
    'targetType': 'venue',
    'targetId': 'The Crown Bar',
  }),
  MapEntry('log_002', {
    'actorEmail': 'nina@appteam.com',
    'action': 'STAFF_INVITE_CREATED',
    'targetType': 'staff_invite',
    'targetId': 'new.admin@appteam.com',
  }),
];
