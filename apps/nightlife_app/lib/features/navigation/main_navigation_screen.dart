import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/navigation/home_navigation_service.dart';
import '../../core/widgets/premium_scaffold.dart';
import '../../core/theme/app_colors.dart';
import '../account/screens/account_management_screen.dart';
import '../artists/screens/artist_dashboard_screen.dart';
import '../artists/screens/top_artists_screen.dart';
import '../auth/screens/login_screen.dart';
import '../auth/services/user_role_service.dart';
import '../favourites/screens/favourites_screen.dart';
import '../management/screens/deleted_items_screen.dart';
import '../management/screens/manage_items_screen.dart';
import '../map/screens/venue_map_screen.dart';
import '../notifications/screens/notifications_screen.dart';
import '../notifications/services/notification_service.dart';
import '../owner/screens/business_dashboard_screen.dart';
import '../search/screens/search_screen.dart';

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUserRole>(
      stream: UserRoleService.currentUserRoleStream(),
      builder: (context, snapshot) {
        final role = snapshot.data ?? AppUserRole.user;
        return _MainNavigationShell(role: role);
      },
    );
  }
}

class _MainNavigationShell extends StatefulWidget {
  final AppUserRole role;

  const _MainNavigationShell({required this.role});

  @override
  State<_MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<_MainNavigationShell> {
  int _currentIndex = HomeNavigationService.selectedTabIndex.value;
  bool _mapNavigationActive = false;

  bool get _canManage => widget.role.canManageVenues;

  Widget _managementScreen() {
    if (widget.role == AppUserRole.owner) {
      return const BusinessDashboardScreen();
    }

    return ManagementHomeScreen(isAdmin: widget.role == AppUserRole.admin);
  }

  void _onHomeTabChanged() {
    if (!mounted) return;
    setState(() {
      _currentIndex = HomeNavigationService.selectedTabIndex.value;
    });
  }

  void _onMapNavigationModeChanged(bool active) {
    if (!mounted || _mapNavigationActive == active) return;
    setState(() => _mapNavigationActive = active);
  }

  @override
  void initState() {
    super.initState();
    HomeNavigationService.selectedTabIndex.addListener(_onHomeTabChanged);
  }

  @override
  void dispose() {
    HomeNavigationService.selectedTabIndex.removeListener(_onHomeTabChanged);
    super.dispose();
  }

  Widget _badgeIcon(IconData icon, int count) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (count > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                count > 9 ? '9+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      VenueMapScreen(onNavigationModeChanged: _onMapNavigationModeChanged),
      const SearchScreen(),
      const FavouritesScreen(),
      if (_canManage) _managementScreen(),
      const _AccountScreen(),
    ];

    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
      HomeNavigationService.selectedTabIndex.value = 0;
    }

    return StreamBuilder<int>(
      stream: NotificationService.userUnreadCountStream(),
      builder: (context, notificationSnapshot) {
        final unreadCount = notificationSnapshot.data ?? 0;

        return StreamBuilder<int>(
          stream: NotificationService.businessUnreadCountStream(),
          builder: (context, businessSnapshot) {
            final businessUnreadCount = businessSnapshot.data ?? 0;

            final destinations = <NavigationDestination>[
              const NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map),
                label: 'Map',
              ),
              const NavigationDestination(
                icon: Icon(Icons.search_outlined),
                selectedIcon: Icon(Icons.search),
                label: 'Search',
              ),
              const NavigationDestination(
                icon: Icon(Icons.favorite_border),
                selectedIcon: Icon(Icons.favorite),
                label: 'Saved',
              ),
              if (_canManage)
                NavigationDestination(
                  icon: _badgeIcon(
                    Icons.business_center_outlined,
                    businessUnreadCount,
                  ),
                  selectedIcon: _badgeIcon(
                    Icons.business_center,
                    businessUnreadCount,
                  ),
                  label: widget.role == AppUserRole.owner ||
                          widget.role == AppUserRole.employee
                      ? 'Business'
                      : 'Manage',
                ),
              NavigationDestination(
                icon: _badgeIcon(Icons.person_outline, unreadCount),
                selectedIcon: _badgeIcon(Icons.person, unreadCount),
                label: 'Account',
              ),
            ];

            return PremiumScaffold(
              extendBody: true,
              body: IndexedStack(index: _currentIndex, children: screens),
              bottomNavigationBar: _mapNavigationActive && _currentIndex == 0
                  ? null
                  : SafeArea(
                      top: false,
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withOpacity(0.96),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.38),
                              blurRadius: 28,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: NavigationBar(
                            backgroundColor: Colors.transparent,
                            selectedIndex: _currentIndex,
                            onDestinationSelected: (index) {
                              HomeNavigationService.selectedTabIndex.value =
                                  index;
                              setState(() => _currentIndex = index);
                            },
                            destinations: destinations,
                          ),
                        ),
                      ),
                    ),
            );
          },
        );
      },
    );
  }
}

class ManagementHomeScreen extends StatelessWidget {
  final bool isAdmin;

  const ManagementHomeScreen({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return PremiumScaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Admin Management' : 'Owner Management'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ManagementTile(
            icon: Icons.storefront_outlined,
            title: isAdmin ? 'Manage All Venues' : 'Manage My Venues',
            subtitle: isAdmin
                ? 'Create, edit, delete, or restore any venue'
                : 'Create and edit your own venues',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ManageItemsScreen(
                    collection: 'venues',
                    title: isAdmin ? 'All Venues' : 'My Venues',
                    titleField: 'name',
                    subtitleField: 'address',
                    isAdmin: isAdmin,
                    ownerId: currentUserId,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _ManagementTile(
            icon: Icons.local_bar_outlined,
            title: isAdmin ? 'Manage All Drinks' : 'Manage My Drinks',
            subtitle: 'Create and edit drink items',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ManageItemsScreen(
                    collection: 'drinks',
                    title: isAdmin ? 'All Drinks' : 'My Drinks',
                    titleField: 'name',
                    subtitleField: 'category',
                    isAdmin: isAdmin,
                    ownerId: currentUserId,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _ManagementTile(
            icon: Icons.local_offer_outlined,
            title: isAdmin ? 'Manage All Deals' : 'Manage My Deals',
            subtitle: 'Create and edit venue deals',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ManageItemsScreen(
                    collection: 'deals',
                    title: isAdmin ? 'All Deals' : 'My Deals',
                    titleField: 'title',
                    subtitleField: 'description',
                    isAdmin: isAdmin,
                    ownerId: currentUserId,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          if (isAdmin)
            _ManagementTile(
              icon: Icons.restore_from_trash_outlined,
              title: 'Deleted Items',
              subtitle: 'Restore deleted venues, drinks, and deals',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DeletedItemsScreen()),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ManagementTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ManagementTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _AccountInfoRow extends StatelessWidget {
  const _AccountInfoRow({
    required this.label,
    required this.value,
    this.selectable = false,
  });
  final String label;
  final String value;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: selectable ? SelectableText(value) : Text(value)),
        ],
      ),
    );
  }
}

class _AccountScreen extends StatelessWidget {
  const _AccountScreen();

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _redBadge(int count) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.notifications_outlined),
        if (count > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                count > 9 ? '9+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUserRole>(
      stream: UserRoleService.currentUserRoleStream(),
      builder: (context, snapshot) {
        final role = snapshot.data ?? AppUserRole.user;
        final user = FirebaseAuth.instance.currentUser;
        final displayName = (user?.displayName?.trim().isNotEmpty ?? false)
            ? user!.displayName!.trim()
            : (user?.email ?? 'Unknown user');
        final userId = user?.uid ?? 'Not signed in';

        return PremiumScaffold(
          appBar: AppBar(title: const Text('Account')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ExpansionTile(
                  leading: const Icon(Icons.account_circle_outlined),
                  title: const Text('Account details'),
                  subtitle: Text('${role.name.toUpperCase()} • $displayName'),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    _AccountInfoRow(
                      label: 'Role',
                      value: role.name.toUpperCase(),
                    ),
                    _AccountInfoRow(label: 'Name', value: displayName),
                    _AccountInfoRow(
                      label: 'User ID',
                      value: userId,
                      selectable: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.manage_accounts_outlined),
                  title: const Text('Manage My Account'),
                  subtitle: const Text(
                    'Change password, email, profile details and preferences',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AccountManagementScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.music_note),
                  title: const Text('Artist Dashboard'),
                  subtitle: const Text(
                    'Manage artist profile, bookings, messages and applications',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ArtistDashboardScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.emoji_events_outlined),
                  title: const Text('Top Artists'),
                  subtitle: const Text('View highest rated artists'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TopArtistsScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              StreamBuilder<int>(
                stream: NotificationService.unreadCountStream(),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;
                  return Card(
                    child: ListTile(
                      leading: _redBadge(unreadCount),
                      title: const Text('Notifications'),
                      subtitle: Text(
                        unreadCount > 0
                            ? '$unreadCount unread personal notifications'
                            : 'View personal alerts and account updates',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout / Switch Account'),
                  subtitle: const Text('Sign out or switch to another account'),
                  onTap: () => _logout(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
