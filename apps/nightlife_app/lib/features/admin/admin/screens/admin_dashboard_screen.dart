import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../auth/screens/login_screen.dart';
import '../../auth/services/auth_service.dart';
import '../services/admin_operations_service.dart';
import '../services/admin_permission_service.dart';

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
    final availablePages = _AdminPage.values.where((page) => _role.atLeast(page.minimumRole)).toList();
    if (!_role.atLeast(_page.minimumRole)) _page = _AdminPage.dashboard;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Admin Panel'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<StaffRole>(
                value: _role,
                borderRadius: BorderRadius.circular(16),
                items: StaffRole.values
                    .map((role) => DropdownMenuItem(value: role, child: Text(role.label)))
                    .toList(),
                onChanged: (role) {
                  if (role != null) setState(() => _role = role);
                },
              ),
            ),
          ),
          IconButton(
            tooltip: 'Logout / Switch Account',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final content = _AdminContent(role: _role, page: _page);

          if (!wide) {
            return Column(
              children: [
                SizedBox(
                  height: 58,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (_, index) {
                      final page = availablePages[index];
                      return ChoiceChip(
        side: const BorderSide(color: Color(0xFF9D28FF), width: 1),
                        avatar: Icon(page.icon, size: 18),
                        label: Text(page.label),
                        selected: _page == page,
                        onSelected: (_) => setState(() => _page = page),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemCount: availablePages.length,
                  ),
                ),
                Expanded(child: content),
              ],
            );
          }

          return Row(
            children: [
              _AdminSidebar(
                role: _role,
                selected: _page,
                pages: availablePages,
                onSelected: (page) => setState(() => _page = page),
              ),
              Expanded(child: content),
            ],
          );
        },
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

  const _AdminSidebar({required this.role, required this.selected, required this.pages, required this.onSelected});

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
                const Text('DRINKSPOT', style: TextStyle(color: Colors.white70, letterSpacing: 1.5, fontSize: 11)),
                const SizedBox(height: 8),
                const Text('Staff Operations', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    leading: Icon(page.icon),
                    title: Text(page.label, style: const TextStyle(fontWeight: FontWeight.w700)),
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

  const _AdminContent({required this.role, required this.page});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _buildPage(context),
        ),
      ],
    );
  }

  Widget _buildPage(BuildContext context) {
    if (!role.atLeast(page.minimumRole)) return const _LockedPanel();

    switch (page) {
      case _AdminPage.dashboard:
        return _DashboardPanel(role: role);
      case _AdminPage.accountSupport:
        return _AccountSupportPanel(role: role);
      case _AdminPage.venues:
        return _VenuePanel(role: role);
      case _AdminPage.drinks:
        return _CollectionPanel(title: 'Drinks', subtitle: 'Manage drinks across all venues.', stream: AdminOperationsService.drinksStream(), icon: Icons.local_bar, role: role);
      case _AdminPage.deals:
        return _CollectionPanel(title: 'Deals', subtitle: 'Create, edit, schedule, expire and restore deals.', stream: AdminOperationsService.dealsStream(), icon: Icons.local_offer, role: role);
      case _AdminPage.events:
        return _CollectionPanel(title: 'Events', subtitle: 'Approve, edit and moderate venue and artist events.', stream: AdminOperationsService.eventsStream(), icon: Icons.event, role: role);
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
        return const _FounderOnlyPanel(title: 'Financials', subtitle: 'Revenue, payouts, failed payments and payment-provider records.', metrics: {'Monthly Revenue': '£42.8k', 'Net Revenue': '£36.1k', 'Failed Payments': '18', 'Pending Payouts': '£7.3k'});
      case _AdminPage.subscriptions:
        return const _FounderOnlyPanel(title: 'Subscriptions', subtitle: 'Venue and artist plan status, churn, invoices and billing controls.', metrics: {'Premium Venues': '732', 'Artist Pro': '118', 'Cancelled': '24', 'Trial Accounts': '96'});
      case _AdminPage.auditLogs:
        return _AuditPanel(role: role);
      case _AdminPage.settings:
        return _SettingsPanel(role: role);
    }
  }
}

class _DashboardPanel extends StatelessWidget {
  final StaffRole role;
  const _DashboardPanel({required this.role});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('dashboard'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageHeader(title: 'Dashboard', subtitle: 'Operational overview for staff running the app.'),
        _MetricGrid(cards: [
          _Metric('Venues', '1,248', Icons.storefront, '86 pending verification'),
          _Metric('Normal Users', '92,184', Icons.people, 'All customer accounts'),
          _Metric('Venue Accounts', '1,106', Icons.business, 'Venue owner accounts'),
          _Metric('Artist Accounts', '384', Icons.music_note, 'Performers and DJs'),
          _Metric('Open Reports', '29', Icons.report, '5 high severity'),
          _Metric('Deleted Items', '42', Icons.restore_from_trash, 'Available to recover'),
          if (role.canViewFinancials) _Metric('Revenue', '£42.8k', Icons.payments, 'Founder only'),
          if (role.canViewFinancials) _Metric('Subscriptions', '850', Icons.credit_card, 'Founder only'),
        ]),
        const SizedBox(height: 18),
        _InfoCard(
          title: 'Role summary',
          lines: [
            'Support: account help, venue name/image changes and deleted-item recovery.',
            'Admin: all venue, drink, deal, event and moderation controls.',
            'Management: operations, staff accounts and audit visibility, but no financial details.',
            'Founder/App Owner: full access including financials, billing and permanent deletion.',
          ],
        ),
      ],
    );
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
        _PageHeader(title: 'Account Support', subtitle: 'Support normal user, venue and artist accounts from one screen.'),
        _SearchAndFilters(
          hint: 'Search by name, email, city, UID, venue or artist name...',
          onChanged: (value) => setState(() => _query = value.toLowerCase()),
          filter: DropdownButton<SupportedAccountType?>(
            value: _type,
            hint: const Text('All account types'),
            items: [
              const DropdownMenuItem<SupportedAccountType?>(value: null, child: Text('All account types')),
              ...SupportedAccountType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.label))),
            ],
            onChanged: (value) => setState(() => _type = value),
          ),
        ),
        _StreamList(
          stream: AdminOperationsService.accountsStream(),
          emptyText: 'No accounts found yet.',
          fallback: _sampleAccounts,
          itemBuilder: (context, id, data) {
            final type = SupportedAccountTypeX.fromValue(data['accountType'] ?? data['role']);
            final name = _display(data, ['name', 'displayName', 'venueName', 'artistName'], 'Unnamed account');
            final email = _display(data, ['email'], 'No email');
            final haystack = '$name $email ${data['city'] ?? ''} $id ${type.label}'.toLowerCase();
            if (_type != null && _type != type) return const SizedBox.shrink();
            if (_query.isNotEmpty && !haystack.contains(_query)) return const SizedBox.shrink();

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
                OutlinedButton.icon(onPressed: () => _showAccountDetails(context, id, data), icon: const Icon(Icons.visibility), label: const Text('View')),
                OutlinedButton.icon(onPressed: email == 'No email' ? null : () => _sendReset(context, email), icon: const Icon(Icons.lock_reset), label: const Text('Password reset')),
                if (widget.role.canEditFullContent) FilledButton.icon(onPressed: () => _updateStatus(context, id, 'suspended'), icon: const Icon(Icons.block), label: const Text('Suspend')),
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
          action: widget.role.canEditFullContent ? FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('Add Venue')) : null,
        ),
        _SearchAndFilters(hint: 'Search venues...', onChanged: (value) => setState(() => _query = value.toLowerCase())),
        _StreamList(
          stream: AdminOperationsService.venuesStream(),
          emptyText: 'No venues found yet.',
          fallback: _sampleVenues,
          itemBuilder: (context, id, data) {
            final name = _display(data, ['name', 'venueName'], 'Unnamed venue');
            final haystack = '$name ${data['city'] ?? ''} ${data['ownerEmail'] ?? ''} $id'.toLowerCase();
            if (_query.isNotEmpty && !haystack.contains(_query)) return const SizedBox.shrink();
            return _AdminRecordCard(
              icon: Icons.storefront,
              title: name,
              subtitle: '${data['city'] ?? 'Unknown city'} • ${data['ownerEmail'] ?? data['ownerUid'] ?? 'No owner'}',
              chips: [data['status']?.toString() ?? 'active', data['verified'] == true ? 'verified' : 'unverified'],
              actions: [
                OutlinedButton.icon(onPressed: () => _editVenueSupport(context, id, name), icon: const Icon(Icons.edit), label: const Text('Name')),
                OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.image), label: const Text('Images')),
                if (widget.role.canEditFullContent) FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.tune), label: const Text('Full edit')),
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

  const _CollectionPanel({required this.title, required this.subtitle, required this.stream, required this.icon, required this.role});

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
        _PageHeader(title: widget.title, subtitle: widget.subtitle, action: FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: Text('Add ${widget.title.substring(0, widget.title.length - 1)}'))),
        _SearchAndFilters(hint: 'Search ${widget.title.toLowerCase()}...', onChanged: (value) => setState(() => _query = value.toLowerCase())),
        _StreamList(
          stream: widget.stream,
          emptyText: 'No ${widget.title.toLowerCase()} found yet.',
          fallback: _fallbackFor(widget.title),
          itemBuilder: (context, id, data) {
            final name = _display(data, ['name', 'title'], 'Untitled');
            final venue = _display(data, ['venueName', 'venueId'], 'No venue');
            final haystack = '$name $venue ${data['status'] ?? ''} $id'.toLowerCase();
            if (_query.isNotEmpty && !haystack.contains(_query)) return const SizedBox.shrink();
            return _AdminRecordCard(
              icon: widget.icon,
              title: name,
              subtitle: venue,
              chips: [data['status']?.toString() ?? 'active', if (data['price'] != null) '£${data['price']}'],
              actions: [
                FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.edit), label: const Text('Edit')),
                OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.visibility_off), label: const Text('Hide')),
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
        _PageHeader(title: 'Users', subtitle: 'Review users, venue owners, artists, suspensions and account deletion requests.'),
        const _MetricGrid(cards: [
          _Metric('Total Users', '92,184', Icons.people, 'Normal app accounts'),
          _Metric('Venue Owners', '1,106', Icons.business, 'Linked to venues'),
          _Metric('Artist Accounts', '384', Icons.music_note, 'DJs and performers'),
          _Metric('Deletion Requests', '11', Icons.delete_outline, 'Pending review'),
        ]),
        const SizedBox(height: 16),
        _InfoCard(title: 'User account controls', lines: [
          'Users can manage their own password, details, notification preferences, privacy settings and account deletion requests.',
          'Venue accounts can manage venue details, opening hours, images, drinks, deals, events and team members.',
          'Artist accounts can manage artist profiles, genres, availability, booking contacts, socials and performances.',
        ]),
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
        _PageHeader(title: 'Reports & Moderation', subtitle: 'Reported venues, images, drinks, deals, users, venue accounts and artist accounts.'),
        _StreamList(
          stream: AdminOperationsService.reportsStream(),
          emptyText: 'No reports yet.',
          fallback: _sampleReports,
          itemBuilder: (context, id, data) => _AdminRecordCard(
            icon: Icons.report,
            title: _display(data, ['type', 'title'], 'Report'),
            subtitle: _display(data, ['targetName', 'targetId'], id),
            chips: [data['severity']?.toString() ?? 'low', data['status']?.toString() ?? 'open'],
            actions: [FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.open_in_new), label: const Text('Open'))],
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
        _PageHeader(title: 'Recovery Centre', subtitle: 'Restore deleted venues, drinks, deals, events, images, users, venue accounts and artist accounts.'),
        _StreamList(
          stream: AdminOperationsService.deletedItemsStream(),
          emptyText: 'No deleted items found.',
          fallback: _sampleDeleted,
          itemBuilder: (context, id, data) => _AdminRecordCard(
            icon: Icons.restore_from_trash,
            title: _display(data, ['name', 'title', 'originalId'], 'Deleted item'),
            subtitle: '${data['itemType'] ?? 'item'} • deleted by ${data['deletedBy'] ?? 'unknown'}',
            chips: [data['restored'] == true ? 'restored' : 'deleted'],
            actions: [
              FilledButton.icon(onPressed: () => _restore(context, id), icon: const Icon(Icons.restore), label: const Text('Restore')),
              if (role.canHardDelete) OutlinedButton.icon(onPressed: () => _hardDelete(context, id), icon: const Icon(Icons.delete_forever), label: const Text('Permanent delete')),
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
    final assignableRoles = StaffRole.values.where(widget.role.canAssign).toList();
    if (!assignableRoles.contains(_newRole)) _newRole = assignableRoles.first;

    return Column(
      key: const ValueKey('staff'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageHeader(title: 'Staff Management', subtitle: 'Management can create Support/Admin staff. Founder can assign Management and Founder roles.'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Create staff invite', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 12),
                Wrap(
                  runSpacing: 12,
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(width: 230, child: TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full name'))),
                    SizedBox(width: 260, child: TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email'))),
                    SizedBox(
                      width: 240,
                      child: DropdownButtonFormField<StaffRole>(
                        value: _newRole,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items: assignableRoles.map((role) => DropdownMenuItem(value: role, child: Text(role.label))).toList(),
                        onChanged: (role) => setState(() => _newRole = role ?? StaffRole.support),
                      ),
                    ),
                    FilledButton.icon(onPressed: () => _createInvite(context), icon: const Icon(Icons.person_add), label: const Text('Create invite')),
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
              chips: [targetRole.label, data['status']?.toString() ?? 'active', data['twoFactorRequired'] == true ? '2FA required' : '2FA optional'],
              actions: [
                OutlinedButton.icon(
                  onPressed: widget.role.canManageStaffMember(targetRole) ? () => AdminOperationsService.disableStaff(id) : null,
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
    if (_nameController.text.trim().isEmpty || _emailController.text.trim().isEmpty) {
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Staff invite created')),
    );
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
        _PageHeader(title: 'User Self-Service', subtitle: 'Areas users, venues and artists can manage themselves inside the app.'),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 900;
            return GridView.count(
              crossAxisCount: wide ? 3 : 1,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: wide ? 1.1 : 1.8,
              children: const [
                _SelfServiceCard(title: 'Normal User Account', icon: Icons.person, fields: ['Profile photo', 'Display name', 'Email address', 'Phone number', 'Change password', 'Notification preferences', 'Privacy settings', 'Saved venues', 'Favourite drinks', 'Blocked users', 'Delete account request']),
                _SelfServiceCard(title: 'Venue Account', icon: Icons.storefront, fields: ['Venue profile', 'Venue pictures', 'Opening hours', 'Drinks menu', 'Deals', 'Events', 'Venue team members', 'Subscription plan', 'Notification settings']),
                _SelfServiceCard(title: 'Artist Account', icon: Icons.music_note, fields: ['Artist profile', 'Profile pictures', 'Genre/categories', 'Availability', 'Booking contact details', 'Social media links', 'Upcoming performances', 'Notification settings']),
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
        _PageHeader(title: 'Analytics', subtitle: 'Operational analytics for Management/Admin. Financial analytics remain Founder-only.'),
        _MetricGrid(cards: [
          const _Metric('Searches Today', '18,482', Icons.search, 'Drink, venue and city searches'),
          const _Metric('Most Active City', 'London', Icons.location_city, '32% of traffic'),
          const _Metric('Deal Clicks', '6,209', Icons.local_offer, 'Last 7 days'),
          const _Metric('Venue Views', '44,102', Icons.visibility, 'Last 7 days'),
          if (role.canViewFinancials) const _Metric('Revenue Conversion', '£9.8k', Icons.payments, 'Founder only'),
        ]),
      ],
    );
  }
}

class _FounderOnlyPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Map<String, String> metrics;

  const _FounderOnlyPanel({required this.title, required this.subtitle, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey(title),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageHeader(title: title, subtitle: subtitle),
        _MetricGrid(cards: metrics.entries.map((e) => _Metric(e.key, e.value, Icons.insights, 'Founder-only')).toList()),
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
        _PageHeader(title: 'Audit Logs', subtitle: 'Immutable staff action history for accountability and recovery.'),
        _StreamList(
          stream: AdminOperationsService.auditLogsStream(),
          emptyText: 'No audit logs yet.',
          fallback: _sampleAudit,
          itemBuilder: (context, id, data) => _AdminRecordCard(
            icon: Icons.history,
            title: data['action']?.toString() ?? 'Action',
            subtitle: '${data['actorEmail'] ?? data['actorUid'] ?? 'Unknown'} • ${data['targetType'] ?? 'target'}: ${data['targetId'] ?? id}',
            chips: [data['createdAt'] is Timestamp ? (data['createdAt'] as Timestamp).toDate().toString() : 'logged'],
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
        _PageHeader(title: 'App Settings', subtitle: 'Management can view operational settings. Founder can edit critical platform settings.'),
        _InfoCard(title: 'Protected settings', lines: [
          'Venue auto-approval: ${role.canViewFinancials ? 'editable' : 'view only'}',
          'Push notification approval flow: ${role.canViewFinancials ? 'editable' : 'view only'}',
          'Staff 2FA enforcement: ${role.canViewFinancials ? 'editable' : 'view only'}',
          'Maintenance mode: Founder only',
        ]),
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
                Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
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
        final columns = width > 1050 ? 4 : width > 700 ? 2 : 1;
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
            CircleAvatar(backgroundColor: primary.withOpacity(0.12), child: Icon(metric.icon, color: primary)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(metric.label, style: const TextStyle(fontSize: 13)),
                  Text(metric.value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(metric.helper, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
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
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...lines.map((line) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.check_circle, size: 18, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(child: Text(line)),
                  ]),
                )),
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

  const _AdminRecordCard({required this.icon, required this.title, required this.subtitle, required this.chips, required this.actions});

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
                        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
                        const SizedBox(height: 8),
                        Wrap(spacing: 6, runSpacing: 6, children: chips.where((chip) => chip.trim().isNotEmpty).map(_RoleChip.new).toList()),
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
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF3B0764))),
    );
  }
}

class _SearchAndFilters extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final Widget? filter;

  const _SearchAndFilters({required this.hint, required this.onChanged, this.filter});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(child: TextField(onChanged: onChanged, decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: hint))),
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
  final Widget Function(BuildContext context, String id, Map<String, dynamic> data) itemBuilder;

  const _StreamList({required this.stream, required this.emptyText, required this.itemBuilder, this.fallback = const []});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && fallback.isEmpty) {
          return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));
        }

        final docs = snapshot.data?.docs.map((doc) => MapEntry(doc.id, doc.data())).toList() ?? fallback;
        if (docs.isEmpty) return _EmptyPanel(text: emptyText);

        return Column(
          children: docs.map((entry) => itemBuilder(context, entry.key, entry.value)).where((widget) => widget is! SizedBox || widget.height != 0).toList(),
        );
      },
    );
  }
}

class _SelfServiceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> fields;

  const _SelfServiceCard({required this.title, required this.icon, required this.fields});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [CircleAvatar(child: Icon(icon)), const SizedBox(width: 10), Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)))]),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: fields.map((field) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(12)), child: Text(field)),
                )).toList(),
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
    return Card(child: Padding(padding: const EdgeInsets.all(24), child: Center(child: Text(text))));
  }
}

class _LockedPanel extends StatelessWidget {
  const _LockedPanel();

  @override
  Widget build(BuildContext context) {
    return const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Access denied for your staff role.'))));
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password reset sent to $email')));
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not send reset: $error')));
  }
}

Future<void> _updateStatus(BuildContext context, String uid, String status) async {
  await AdminOperationsService.updateAccountStatus(uid: uid, status: status);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Account marked as $status')));
}

Future<void> _restore(BuildContext context, String id) async {
  await AdminOperationsService.restoreDeletedItem(id);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item restored')));
}

Future<void> _hardDelete(BuildContext context, String id) async {
  await AdminOperationsService.hardDeleteDeletedItem(id);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item permanently deleted')));
}

Future<void> _editVenueSupport(BuildContext context, String venueId, String currentName) async {
  final controller = TextEditingController(text: currentName);
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit venue name'),
      content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Venue name')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
      ],
    ),
  );
  if (result == null || result.trim().isEmpty) return;
  await AdminOperationsService.updateVenueSupportFields(venueId: venueId, name: result);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Venue name updated')));
}

void _showAccountDetails(BuildContext context, String id, Map<String, dynamic> data) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(_display(data, ['name', 'displayName', 'venueName', 'artistName'], 'Account')),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ID: $id'),
            const SizedBox(height: 8),
            ...data.entries.take(20).map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('${entry.key}: ${entry.value}'),
                )),
          ],
        ),
      ),
      actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
    ),
  );
}


const _sampleAccounts = [
  MapEntry('user_001', {'name': 'Jamie Carter', 'email': 'jamie@example.com', 'accountType': 'user', 'status': 'active', 'city': 'London', 'verified': true, 'reports': 0}),
  MapEntry('venue_001', {'name': 'The Crown Bar Owner', 'email': 'owner@crownbars.com', 'accountType': 'venue', 'status': 'active', 'city': 'London', 'verified': true, 'reports': 1}),
  MapEntry('artist_001', {'name': 'DJ Nova', 'email': 'bookings@djnova.com', 'accountType': 'artist', 'status': 'pending', 'city': 'Manchester', 'verified': false, 'reports': 0}),
];

const _sampleVenues = [
  MapEntry('venue_001', {'name': 'The Crown Bar', 'city': 'London', 'ownerEmail': 'owner@crownbars.com', 'status': 'active', 'verified': true}),
  MapEntry('venue_002', {'name': 'Neon Lounge', 'city': 'Manchester', 'ownerEmail': 'neon@example.com', 'status': 'pending', 'verified': false}),
  MapEntry('venue_003', {'name': 'Harbour Tap', 'city': 'Bristol', 'ownerEmail': 'tap@example.com', 'status': 'suspended', 'verified': true}),
];

const _sampleDrinks = [
  MapEntry('drink_001', {'name': 'Espresso Martini', 'venueName': 'The Crown Bar', 'price': '9.50', 'status': 'active'}),
  MapEntry('drink_002', {'name': 'House Lager', 'venueName': 'Neon Lounge', 'price': '5.20', 'status': 'active'}),
];

const _sampleDeals = [
  MapEntry('deal_001', {'title': '2-for-1 Cocktails', 'venueName': 'The Crown Bar', 'status': 'live'}),
  MapEntry('deal_002', {'title': 'Student Night', 'venueName': 'Neon Lounge', 'status': 'scheduled'}),
];

const _sampleEvents = [
  MapEntry('event_001', {'title': 'Live DJ Night', 'venueName': 'Neon Lounge', 'status': 'approved'}),
  MapEntry('event_002', {'title': 'Quiz Night', 'venueName': 'The Crown Bar', 'status': 'pending'}),
];

const _sampleReports = [
  MapEntry('report_001', {'type': 'Venue image', 'targetName': 'Neon Lounge', 'severity': 'medium', 'status': 'open'}),
  MapEntry('report_002', {'type': 'Incorrect drink price', 'targetName': 'House Lager', 'severity': 'low', 'status': 'open'}),
];

const _sampleDeleted = [
  MapEntry('deleted_001', {'itemType': 'deal', 'name': 'Monday Mojitos', 'deletedBy': 'Aaron Admin', 'restored': false}),
  MapEntry('deleted_002', {'itemType': 'artist', 'name': 'DJ Legacy Profile', 'deletedBy': 'Nina Manager', 'restored': false}),
];

const _sampleStaff = [
  MapEntry('staff_001', {'displayName': 'Mia Support', 'email': 'mia@appteam.com', 'role': 'support', 'status': 'active', 'twoFactorRequired': false}),
  MapEntry('staff_002', {'displayName': 'Aaron Admin', 'email': 'aaron@appteam.com', 'role': 'admin', 'status': 'active', 'twoFactorRequired': true}),
  MapEntry('staff_003', {'displayName': 'Nina Manager', 'email': 'nina@appteam.com', 'role': 'management', 'status': 'active', 'twoFactorRequired': true}),
  MapEntry('staff_004', {'displayName': 'Founder Account', 'email': 'owner@app.com', 'role': 'founder', 'status': 'active', 'twoFactorRequired': true}),
];

const _sampleAudit = [
  MapEntry('log_001', {'actorEmail': 'mia@appteam.com', 'action': 'VENUE_IMAGE_CHANGED', 'targetType': 'venue', 'targetId': 'The Crown Bar'}),
  MapEntry('log_002', {'actorEmail': 'nina@appteam.com', 'action': 'STAFF_INVITE_CREATED', 'targetType': 'staff_invite', 'targetId': 'new.admin@appteam.com'}),
];
