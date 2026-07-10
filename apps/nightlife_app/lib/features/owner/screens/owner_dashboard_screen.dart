import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

import '../../../core/widgets/home_icon_button.dart';

import '../../auth/screens/login_screen.dart';
import '../../auth/services/auth_service.dart';
import '../../analytics/widgets/venue_analytics_card.dart';
import '../../home/models/venue_model.dart';
import '../../home/services/venue_service.dart';
import '../../monetisation/screens/boost_venue_screen.dart';
import '../../monetisation/screens/owner_upgrade_screen.dart';
import '../../venues/screens/add_event_screen.dart';
import 'add_deal_screen.dart';
import 'add_venue_screen.dart';
import 'my_venues_screen.dart';
import 'owner_analytics_dashboard_screen.dart';
import 'update_crowd_screen.dart';

class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  void _goToAddVenue(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddVenueScreen(),
      ),
    );
  }

  void _goToMyVenues(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MyVenuesScreen(),
      ),
    );
  }

  void _pickVenueForAction(
    BuildContext context,
    List<VenueModel> venues,
    String title,
    void Function(VenueModel venue) onVenueSelected,
  ) {
    if (venues.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a venue first.')),
      );
      return;
    }

    if (venues.length == 1) {
      onVenueSelected(venues.first);
      return;
    }

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(title: Text(title)),
            ...venues.map(
              (venue) => ListTile(
                leading: const Icon(Icons.storefront),
                title: Text(venue.name),
                subtitle: Text(venue.address),
                onTap: () {
                  Navigator.pop(context);
                  onVenueSelected(venue);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _goToBoostVenue(BuildContext context, List<VenueModel> venues) {
    if (venues.isEmpty) return;
    if (venues.length == 1) {
      final venue = venues.first;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BoostVenueScreen(
            venueId: venue.id,
            venueName: venue.name,
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Choose a venue to boost')),
            ...venues.map(
              (venue) => ListTile(
                leading: const Icon(Icons.storefront),
                title: Text(venue.name),
                subtitle: Text(venue.address),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BoostVenueScreen(
                        venueId: venue.id,
                        venueName: venue.name,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon'),
      ),
    );
  }

  void _showAddMenu(
    BuildContext context, {
    bool venueSelected = false,
  }) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Add New',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                if (!venueSelected)
                  _AddMenuTile(
                    icon: Icons.storefront,
                    title: 'Venue',
                    subtitle: 'Create a new business listing',
                    onTap: () {
                      Navigator.pop(context);
                      _goToAddVenue(context);
                    },
                  ),

                _AddMenuTile(
                  icon: Icons.local_offer,
                  title: 'Deal',
                  subtitle: venueSelected
                      ? 'Add a deal to this venue'
                      : 'Add a happy hour or promotion',
                  onTap: () {
                    Navigator.pop(context);
                    _comingSoon(context, 'Add deal');
                  },
                ),

                _AddMenuTile(
                  icon: Icons.event,
                  title: 'Event',
                  subtitle: venueSelected
                      ? 'Add an event to this venue'
                      : 'Add live music, DJ nights or special events',
                  onTap: () {
                    Navigator.pop(context);
                    _comingSoon(context, 'Add event');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = AuthService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        actions: [
          const HomeIconButton(),
          IconButton(
            tooltip: 'Log out',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMenu(context),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withOpacity(0.75),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.nightlife,
                  color: Colors.white,
                  size: 42,
                ),
                const SizedBox(height: 16),
                FutureBuilder<String>(
                  future: AuthService.getCurrentUserDisplayName(),
                  initialData: AuthService.getLocalDisplayName(),
                  builder: (context, snapshot) {
                    final name = snapshot.data?.trim();
                    final displayName = name == null || name.isEmpty
                        ? 'Owner'
                        : name;

                    return Text(
                      'Welcome back, $displayName',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 6),
                const Text(
                  'Business Tools',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Manage your venues, drinks, deals, events and customer experience from one place.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          if (user == null) ...[
            const Center(child: Text('Not logged in')),
          ] else ...[
            StreamBuilder<List<VenueModel>>(
              stream: VenueService.getVenuesForOwner(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final venues = snapshot.data ?? [];

                if (venues.isEmpty) {
                  return _EmptyDashboardCard(
                    onTap: () => _showAddMenu(context),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _OwnerStatsSection(venues: venues),
                    const SizedBox(height: 14),
                    _DashboardActionCard(
                      icon: Icons.query_stats,
                      title: 'Owner Analytics',
                      subtitle: 'See views, saves, conversion, drinks, deals, events and crowd engagement.',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OwnerAnalyticsDashboardScreen(venues: venues))),
                    ),
                    const SizedBox(height: 14),
                    _DashboardActionCard(
                      icon: Icons.rocket_launch,
                      title: 'Boost a Venue',
                      subtitle: 'Promote a venue in Trending and increase visibility.',
                      onTap: () => _goToBoostVenue(context, venues),
                    ),
                    const SizedBox(height: 14),
                    _DashboardActionCard(
                      icon: Icons.workspace_premium,
                      title: 'Owner Pro',
                      subtitle: 'Unlock advanced analytics, featured map visibility and business growth tools.',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerUpgradeScreen())),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 28),
            const _SectionTitle(
              icon: Icons.flash_on,
              title: 'Quick Actions',
            ),
            const SizedBox(height: 14),

            _OwnerTipCard(),

            const SizedBox(height: 14),

            StreamBuilder<List<VenueModel>>(
              stream: user == null ? const Stream.empty() : VenueService.getVenuesForOwner(user.uid),
              builder: (context, snapshot) {
                final venues = snapshot.data ?? [];
                return Column(
                  children: [
                    _DashboardActionCard(
                      icon: Icons.storefront,
                      title: 'My Venues',
                      subtitle: 'Edit venues, opening details, drinks and business info.',
                      onTap: () => _goToMyVenues(context),
                    ),
                    const SizedBox(height: 14),
                    _DashboardActionCard(
                      icon: Icons.local_offer,
                      title: 'Manage Deals',
                      subtitle: 'Add offers, happy hours and limited-time promotions.',
                      onTap: () => _pickVenueForAction(
                        context,
                        venues,
                        'Choose a venue for this deal',
                        (venue) => Navigator.push(context, MaterialPageRoute(builder: (_) => AddDealScreen(venue: venue))),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _DashboardActionCard(
                      icon: Icons.event_available,
                      title: 'Manage Events',
                      subtitle: 'Promote DJs, live music, themed nights and special events.',
                      onTap: () => _pickVenueForAction(
                        context,
                        venues,
                        'Choose a venue for this event',
                        (venue) => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEventScreen(venueId: venue.id, venueName: venue.name))),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _DashboardActionCard(
                      icon: Icons.groups,
                      title: 'Update Crowd Level',
                      subtitle: 'Let users know how busy your venue is right now.',
                      onTap: () => _pickVenueForAction(
                        context,
                        venues,
                        'Choose a venue to update',
                        (venue) => Navigator.push(context, MaterialPageRoute(builder: (_) => UpdateCrowdScreen(venueId: venue.id, venueName: venue.name, currentLevel: venue.crowdLevel))),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],

          const SizedBox(height: 28),
        ],
      ),
    );
  }
}



class _OwnerTipCard extends StatelessWidget {
  const _OwnerTipCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.25)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lightbulb_outline),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Tip: Keep deals, events and crowd levels updated so customers see your venue as active.',
              style: TextStyle(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerStatsSection extends StatelessWidget {
  final List<VenueModel> venues;

  const _OwnerStatsSection({required this.venues});

  @override
  Widget build(BuildContext context) {
    final venueIds = venues.map((venue) => venue.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon: Icons.analytics_outlined,
          title: 'Business Stats',
        ),
        const SizedBox(height: 14),
        OwnerAnalyticsSummaryCard(venueIds: venueIds),
      ],
    );
  }
}

class _EmptyDashboardCard extends StatelessWidget {
  final VoidCallback onTap;

  const _EmptyDashboardCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primaryPurple.withOpacity(0.65),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.add_business,
            size: 52,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 14),
          const Text(
            'Add your first venue',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start by creating your first business listing. Once added, you can manage drinks, deals, events and crowd levels.',
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.4),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 54,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primaryPurple.withOpacity(0.65),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DashboardActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: AppColors.primaryPurple.withOpacity(0.65),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: colorScheme.primary.withOpacity(0.12),
                child: Icon(
                  icon,
                  color: colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AddMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: AppColors.primaryPurple.withOpacity(0.65),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: colorScheme.primary.withOpacity(0.12),
          child: Icon(
            icon,
            color: colorScheme.primary,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}