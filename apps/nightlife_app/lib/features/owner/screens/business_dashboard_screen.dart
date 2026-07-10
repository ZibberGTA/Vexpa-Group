import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/premium_scaffold.dart';
import '../../../core/theme/app_colors.dart';

import '../../../core/widgets/home_icon_button.dart';
import '../../analytics/services/analytics_service.dart';
import '../../analytics/widgets/venue_analytics_card.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/services/auth_service.dart';
import '../../home/models/venue_model.dart';
import '../../home/services/venue_service.dart';
import '../../monetisation/screens/boost_venue_screen.dart';
import '../../monetisation/screens/owner_upgrade_screen.dart';
import '../../venues/screens/add_event_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import 'owner_artist_applications_screen.dart';
import 'owner_add_content_screen.dart';
import 'owner_event_calendar_screen.dart';
import 'add_deal_screen.dart';
import 'add_drink_screen.dart';
import 'add_venue_screen.dart';
import 'my_venues_screen.dart';
import 'owner_analytics_dashboard_screen.dart';
import 'update_crowd_screen.dart';
import 'owner_event_calendar_overview_screen.dart';

class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({super.key});

  @override
  State<BusinessDashboardScreen> createState() => _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<BusinessDashboardCounts> _loadCounts(List<VenueModel> venues) async {
    if (venues.isEmpty) return const BusinessDashboardCounts();

    final venueIds = venues.map((venue) => venue.id).toList();
    final chunks = <List<String>>[];
    for (var i = 0; i < venueIds.length; i += 10) {
      chunks.add(venueIds.sublist(i, i + 10 > venueIds.length ? venueIds.length : i + 10));
    }

    var drinks = 0;
    var deals = 0;
    var events = 0;

    for (final chunk in chunks) {
      final drinkSnapshot = await FirebaseFirestore.instance
          .collection('drinks')
          .where('venueId', whereIn: chunk)
          .where('isDeleted', isEqualTo: false)
          .get();
      final dealSnapshot = await FirebaseFirestore.instance
          .collection('deals')
          .where('venueId', whereIn: chunk)
          .where('isDeleted', isEqualTo: false)
          .get();
      final eventSnapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('venueId', whereIn: chunk)
          .where('isDeleted', isEqualTo: false)
          .get();

      drinks += drinkSnapshot.docs.length;
      deals += dealSnapshot.docs.length;
      events += eventSnapshot.docs.length;
    }

    return BusinessDashboardCounts(
      drinks: drinks,
      deals: deals,
      events: events,
    );
  }

  void _pickVenue(
    List<VenueModel> venues,
    String title,
    void Function(VenueModel venue) onSelected,
  ) {
    if (venues.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a venue first.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFF111218),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            10,
            18,
            MediaQuery.of(context).padding.bottom + 18,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: venues.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final venue = venues[index];

                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        Navigator.pop(context);
                        onSelected(venue);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFF9D28FF).withValues(alpha: 0.65),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: const Color(0xFF05000A),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFF9D28FF),
                                  width: 1.2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                venue.name.isNotEmpty ? venue.name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
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
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    venue.address,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.62),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFFFF2D95),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _openAddMenu(List<VenueModel> venues) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Create Business Content',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _AddMenuTile(
                icon: Icons.local_bar,
                title: 'New drink',
                subtitle: 'Add a drink menu item',
                onTap: () {
                  Navigator.pop(context);
                  _pickVenue(
                    venues,
                    'Choose a venue for this drink',
                    (venue) => Navigator.push(context, MaterialPageRoute(builder: (_) => AddDrinkScreen(venue: venue))),
                  );
                },
              ),
              _AddMenuTile(
                icon: Icons.local_offer,
                title: 'New deal',
                subtitle: 'Add happy hour or promotion',
                onTap: () {
                  Navigator.pop(context);
                  _pickVenue(
                    venues,
                    'Choose a venue for this deal',
                    (venue) => Navigator.push(context, MaterialPageRoute(builder: (_) => AddDealScreen(venue: venue))),
                  );
                },
              ),
              _AddMenuTile(
                icon: Icons.event,
                title: 'New event',
                subtitle: 'Promote DJ nights, live music or themed events',
                onTap: () {
                  Navigator.pop(context);
                  _pickVenue(
                    venues,
                    'Choose a venue for this event',
                    (venue) => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEventScreen(venueId: venue.id, venueName: venue.name))),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    return PremiumScaffold(
      appBar: AppBar(
        title: const Text('Business Dashboard'),
        actions: [
          const HomeIconButton(),
          IconButton(
            tooltip: 'Log out',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Overview'),
            Tab(icon: Icon(Icons.edit_note), text: 'Manage'),
            Tab(icon: Icon(Icons.query_stats), text: 'Analytics'),
            Tab(icon: Icon(Icons.rocket_launch), text: 'Growth'),
          ],
        ),
      ),
      body: user == null
          ? const PremiumEmptyState(icon: Icons.lock_outline_rounded, title: 'Not logged in', subtitle: 'Sign in to manage your business dashboard.')
          : StreamBuilder<List<VenueModel>>(
              stream: VenueService.getVenuesForOwner(user.uid),
              builder: (context, venueSnapshot) {
                if (venueSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (venueSnapshot.hasError) {
                  return Center(child: Text('Could not load dashboard: ${venueSnapshot.error}'));
                }

                final venues = venueSnapshot.data ?? [];

                return FutureBuilder<BusinessDashboardCounts>(
                  future: _loadCounts(venues),
                  builder: (context, countSnapshot) {
                    final counts = countSnapshot.data ?? const BusinessDashboardCounts();
                    final isLoadingCounts = countSnapshot.connectionState == ConnectionState.waiting;

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _OverviewTab(
                          venues: venues,
                          counts: counts,
                          isLoadingCounts: isLoadingCounts,
                          onAddPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerAddContentScreen())),
                          onAddVenuePressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddVenueScreen())),
                          onManageVenuesPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyVenuesScreen())),
                          onCrowdPressed: () => _pickVenue(
                            venues,
                            'Choose a venue to update crowd',
                            (venue) => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UpdateCrowdScreen(
                                  venueId: venue.id,
                                  venueName: venue.name,
                                  currentLevel: venue.crowdLevel,
                                ),
                              ),
                            ),
                          ),
                          onArtistApplicationsPressed: () => _pickVenue(
                            venues,
                            'Choose a venue for artist applications',
                            (venue) => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => OwnerArtistApplicationsScreen(venue: venue)),
                            ),
                          ),
                          onCalendarPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const OwnerEventCalendarOverviewScreen(),
                            ),
                          ),
                          onNotificationsPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                          ),
                        ),
                        _ManageTab(
                          venues: venues,
                          onAddPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerAddContentScreen())),
                          onMyVenuesPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyVenuesScreen())),
                          onDrinkPressed: () => _pickVenue(
                            venues,
                            'Choose a venue for this drink',
                            (venue) => Navigator.push(context, MaterialPageRoute(builder: (_) => AddDrinkScreen(venue: venue))),
                          ),
                          onDealPressed: () => _pickVenue(
                            venues,
                            'Choose a venue for this deal',
                            (venue) => Navigator.push(context, MaterialPageRoute(builder: (_) => AddDealScreen(venue: venue))),
                          ),
                          onEventPressed: () => _pickVenue(
                            venues,
                            'Choose a venue for this event',
                            (venue) => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEventScreen(venueId: venue.id, venueName: venue.name))),
                          ),
                          onCrowdPressed: () => _pickVenue(
                            venues,
                            'Choose a venue to update',
                            (venue) => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UpdateCrowdScreen(
                                  venueId: venue.id,
                                  venueName: venue.name,
                                  currentLevel: venue.crowdLevel,
                                ),
                              ),
                            ),
                          ),
                          onArtistApplicationsPressed: () => _pickVenue(
                            venues,
                            'Choose a venue for artist applications',
                            (venue) => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => OwnerArtistApplicationsScreen(venue: venue)),
                            ),
                          ),
                          onCalendarPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const OwnerEventCalendarOverviewScreen(),
                            ),
                          ),
                          onNotificationsPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                          ),
                        ),
                        _AnalyticsTab(
                          venues: venues,
                          onFullAnalyticsPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => OwnerAnalyticsDashboardScreen(venues: venues)),
                          ),
                        ),
                        _GrowthTab(
                          venues: venues,
                          onBoostPressed: () => _pickVenue(
                            venues,
                            'Choose a venue to boost',
                            (venue) => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BoostVenueScreen(
                                  venueId: venue.id,
                                  venueName: venue.name,
                                ),
                              ),
                            ),
                          ),
                          onUpgradePressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerUpgradeScreen())),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
      floatingActionButton: user == null
          ? null
          : StreamBuilder<List<VenueModel>>(
              stream: VenueService.getVenuesForOwner(user.uid),
              builder: (context, snapshot) {
                return FloatingActionButton.extended(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerAddContentScreen())),
                  icon: const Icon(Icons.add),
                  label: const Text('Create'),
                );
              },
            ),
    );
  }
}

class BusinessDashboardCounts {
  final int drinks;
  final int deals;
  final int events;

  const BusinessDashboardCounts({
    this.drinks = 0,
    this.deals = 0,
    this.events = 0,
  });
}


class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.venues,
    required this.counts,
    required this.isLoadingCounts,
    required this.onAddPressed,
    required this.onAddVenuePressed,
    required this.onManageVenuesPressed,
    required this.onCrowdPressed,
    required this.onArtistApplicationsPressed,
    required this.onCalendarPressed,
    required this.onNotificationsPressed,
  });

  final List<VenueModel> venues;
  final BusinessDashboardCounts counts;
  final bool isLoadingCounts;
  final VoidCallback onAddPressed;
  final VoidCallback onAddVenuePressed;
  final VoidCallback onManageVenuesPressed;
  final VoidCallback onCrowdPressed;
  final VoidCallback onArtistApplicationsPressed;
  final VoidCallback onCalendarPressed;
  final VoidCallback onNotificationsPressed;

  int get liveDeals => venues.where((venue) => venue.hasDeals).length;
  int get busyVenues => venues
      .where((venue) => venue.crowdLevel.toLowerCase().contains('busy'))
      .length;

  String get planName => venues.isEmpty ? 'Light' : 'Light';

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 150;

    return ListView(
      padding: EdgeInsets.fromLTRB(18, 18, 18, bottomPadding),
      children: [
        _BusinessPlanCard(
          planName: planName,
          venueCount: venues.length,
          drinkCount: counts.drinks,
          eventCount: counts.events,
          dealCount: counts.deals,
          isLoadingCounts: isLoadingCounts,
          onUpgradePressed: onAddPressed,
          onVenuesPressed: onManageVenuesPressed,
        ),
        const SizedBox(height: 16),
        _QuickActionsPanel(
          onAddPressed: onAddPressed,
          onVenuesPressed: onManageVenuesPressed,
          onCrowdPressed: onCrowdPressed,
          onArtistApplicationsPressed: onArtistApplicationsPressed,
          onCalendarPressed: onCalendarPressed,
          onNotificationsPressed: onNotificationsPressed,
        ),
        const SizedBox(height: 16),
        _DashboardSectionHeader(
          title: 'Business snapshot',
          subtitle: 'Live content across your DrinkSpot profile.',
          icon: Icons.grid_view_rounded,
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 16) / 3;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CompactMetricTile(width: cardWidth, label: 'Venues', value: venues.length.toString(), icon: Icons.storefront_rounded),
                _CompactMetricTile(width: cardWidth, label: 'Drinks', value: isLoadingCounts ? '...' : counts.drinks.toString(), icon: Icons.local_bar_rounded),
                _CompactMetricTile(width: cardWidth, label: 'Deals', value: isLoadingCounts ? '...' : counts.deals.toString(), icon: Icons.local_offer_rounded),
                _CompactMetricTile(width: cardWidth, label: 'Events', value: isLoadingCounts ? '...' : counts.events.toString(), icon: Icons.event_available_rounded),
                _CompactMetricTile(width: cardWidth, label: 'Live deals', value: liveDeals.toString(), icon: Icons.savings_rounded),
                _CompactMetricTile(width: cardWidth, label: 'Busy now', value: busyVenues.toString(), icon: Icons.groups_rounded),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        if (venues.isEmpty)
          _EmptyBusinessCard(onAddVenuePressed: onAddVenuePressed)
        else ...[
          _DashboardSectionHeader(
            title: 'Venue performance',
            subtitle: 'Keep an eye on what customers see first.',
            icon: Icons.trending_up_rounded,
          ),
          const SizedBox(height: 10),
          ...venues.take(3).map((venue) => _PremiumVenuePerformanceCard(venue: venue)),
          if (venues.length > 3) ...[
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: onManageVenuesPressed,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text('View all ${venues.length} venues'),
            ),
          ],
        ],
        const SizedBox(height: 18),
        _DashboardSectionHeader(
          title: 'Upgrade opportunities',
          subtitle: 'Light, Pro and Premium tools for growing venues.',
          icon: Icons.workspace_premium_rounded,
        ),
        const SizedBox(height: 10),
        const _UpgradeOpportunityCard(
          title: 'Pro analytics',
          subtitle: 'See search views, profile views, save intent and top-performing drinks.',
          plan: 'Pro',
          icon: Icons.query_stats_rounded,
        ),
        const SizedBox(height: 10),
        const _UpgradeOpportunityCard(
          title: 'Premium growth tools',
          subtitle: 'Boosted placement, push campaigns and featured visibility for busy nights.',
          plan: 'Premium',
          icon: Icons.rocket_launch_rounded,
        ),
      ],
    );
  }
}

class _BusinessPlanCard extends StatelessWidget {
  const _BusinessPlanCard({
    required this.planName,
    required this.venueCount,
    required this.drinkCount,
    required this.eventCount,
    required this.dealCount,
    required this.isLoadingCounts,
    required this.onUpgradePressed,
    required this.onVenuesPressed,
  });

  final String planName;
  final int venueCount;
  final int drinkCount;
  final int eventCount;
  final int dealCount;
  final bool isLoadingCounts;
  final VoidCallback onUpgradePressed;
  final VoidCallback onVenuesPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2B0D4D),
            Color(0xFF7A1CFF),
            Color(0xFF25112F),
          ],
        ),
        border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withValues(alpha: 0.20),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.16),
                ),
                child: const Icon(Icons.business_center_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$planName plan',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your DrinkSpot control centre',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    color: Color(0xFF55FF8A),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PlanMiniStat(label: 'Venues', value: venueCount.toString()),
              _PlanMiniStat(label: 'Drinks', value: isLoadingCounts ? '...' : drinkCount.toString()),
              _PlanMiniStat(label: 'Deals', value: isLoadingCounts ? '...' : dealCount.toString()),
              _PlanMiniStat(label: 'Events', value: isLoadingCounts ? '...' : eventCount.toString()),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: onUpgradePressed,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Create'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: onVenuesPressed,
                    icon: const Icon(Icons.storefront_rounded, size: 18),
                    label: const Text('My venues'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.65)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanMiniStat extends StatelessWidget {
  const _PlanMiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.64),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsPanel extends StatelessWidget {
  const _QuickActionsPanel({
    required this.onAddPressed,
    required this.onVenuesPressed,
    required this.onCrowdPressed,
    required this.onArtistApplicationsPressed,
    required this.onCalendarPressed,
    required this.onNotificationsPressed,
  });

  final VoidCallback onAddPressed;
  final VoidCallback onVenuesPressed;
  final VoidCallback onCrowdPressed;
  final VoidCallback onArtistApplicationsPressed;
  final VoidCallback onCalendarPressed;
  final VoidCallback onNotificationsPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _QuickActionButton(icon: Icons.add_circle_outline_rounded, label: 'Add', onTap: onAddPressed)),
              const SizedBox(width: 8),
              Expanded(child: _QuickActionButton(icon: Icons.storefront_rounded, label: 'Venues', onTap: onVenuesPressed)),
              const SizedBox(width: 8),
              Expanded(child: _QuickActionButton(icon: Icons.groups_rounded, label: 'Crowd', onTap: onCrowdPressed)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _QuickActionButton(icon: Icons.person_search_rounded, label: 'Artists', onTap: onArtistApplicationsPressed)),
              const SizedBox(width: 8),
              Expanded(child: _QuickActionButton(icon: Icons.event_available_rounded, label: 'Calendar', onTap: onCalendarPressed)),
              const SizedBox(width: 8),
              Expanded(child: _QuickActionButton(icon: Icons.notifications_active_rounded, label: 'Notify', onTap: onNotificationsPressed)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2030).withValues(alpha: 0.60),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.34)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primaryPink, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardSectionHeader extends StatelessWidget {
  const _DashboardSectionHeader({required this.title, required this.subtitle, required this.icon});

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.purpleSoft, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, height: 1.25),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactMetricTile extends StatelessWidget {
  const _CompactMetricTile({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        height: 92,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2030).withValues(alpha: 0.60),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: AppColors.purpleSoft, size: 19),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumVenuePerformanceCard extends StatelessWidget {
  const _PremiumVenuePerformanceCard({required this.venue});

  final VenueModel venue;

  @override
  Widget build(BuildContext context) {
    final crowd = venue.crowdLevel.trim().isEmpty ? 'Unknown' : venue.crowdLevel;
    final category = venue.category.trim().isEmpty ? 'Venue' : venue.category;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2030).withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryPink.withValues(alpha: 0.9), AppColors.primaryPurple.withValues(alpha: 0.9)],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              venue.name.isEmpty ? '?' : venue.name.characters.first.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
            ),
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  '$category • Crowd: $crowd',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FutureBuilder<WeeklyGrowthMetric>(
            future: AnalyticsService.getWeeklyGrowthForVenue(venueId: venue.id),
            builder: (context, snapshot) {
              final metric = snapshot.data;
              final isLoading = snapshot.connectionState == ConnectionState.waiting;
              final isGrowing = metric?.isGrowing ?? true;
              final label = isLoading
                  ? 'Growth ...'
                  : (metric?.dashboardLabel ?? 'No activity yet');
              final badgeColor = !isLoading && metric != null && !isGrowing
                  ? Colors.orangeAccent
                  : const Color(0xFF31E981);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.95)),
                  boxShadow: [
                    BoxShadow(
                      color: badgeColor.withValues(alpha: 0.18),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _UpgradeOpportunityCard extends StatelessWidget {
  const _UpgradeOpportunityCard({required this.title, required this.subtitle, required this.plan, required this.icon});

  final String title;
  final String subtitle;
  final String plan;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryPurple.withValues(alpha: 0.18),
            ),
            child: Icon(icon, color: AppColors.purpleSoft, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPink.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.primaryPink.withValues(alpha: 0.55)),
                      ),
                      child: Text(
                        plan,
                        style: const TextStyle(
                          color: AppColors.primaryPink,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12, height: 1.25),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.lock_rounded, size: 18, color: Colors.white54),
        ],
      ),
    );
  }
}

class _ManageTab extends StatelessWidget {
  const _ManageTab({
    required this.venues,
    required this.onAddPressed,
    required this.onMyVenuesPressed,
    required this.onDrinkPressed,
    required this.onDealPressed,
    required this.onEventPressed,
    required this.onCrowdPressed,
    required this.onArtistApplicationsPressed,
    required this.onCalendarPressed,
    required this.onNotificationsPressed,
  });

  final List<VenueModel> venues;
  final VoidCallback onAddPressed;
  final VoidCallback onMyVenuesPressed;
  final VoidCallback onDrinkPressed;
  final VoidCallback onDealPressed;
  final VoidCallback onEventPressed;
  final VoidCallback onCrowdPressed;
  final VoidCallback onArtistApplicationsPressed;
  final VoidCallback onCalendarPressed;
  final VoidCallback onNotificationsPressed;

  int get venuesWithDeals => venues.where((venue) => venue.hasDeals).length;
  int get taggedVenues => venues.where((venue) => venue.featureTags.isNotEmpty).length;
  int get venuesWithContact => venues.where((venue) => venue.phone.trim().isNotEmpty || venue.websiteUrl.trim().isNotEmpty).length;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 150;

    return ListView(
      padding: EdgeInsets.fromLTRB(18, 18, 18, bottomPadding),
      children: [
        _ManagePlanHeader(
          venueCount: venues.length,
          venuesWithDeals: venuesWithDeals,
          taggedVenues: taggedVenues,
          onMyVenuesPressed: onMyVenuesPressed,
        ),
        const SizedBox(height: 16),
        _DashboardSectionHeader(
          title: 'Venue operations',
          subtitle: 'Manage live content across every venue included in your plan.',
          icon: Icons.tune_rounded,
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ManageActionTile(width: cardWidth, icon: Icons.local_bar_rounded, title: 'Drinks', subtitle: 'Menus and stock', onTap: onDrinkPressed),
                _ManageActionTile(width: cardWidth, icon: Icons.local_offer_rounded, title: 'Deals', subtitle: 'Promotions', onTap: onDealPressed),
                _ManageActionTile(width: cardWidth, icon: Icons.event_available_rounded, title: 'Events', subtitle: 'Create events', onTap: onEventPressed),
                _ManageActionTile(width: cardWidth, icon: Icons.groups_rounded, title: 'Crowd', subtitle: 'Live status', onTap: onCrowdPressed),
                _ManageActionTile(width: cardWidth, icon: Icons.storefront_rounded, title: 'Venues', subtitle: 'Details and media', onTap: onMyVenuesPressed),
                _ManageActionTile(width: cardWidth, icon: Icons.add_circle_outline_rounded, title: 'Add', subtitle: 'Content menu', onTap: onAddPressed),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        _DashboardSectionHeader(
          title: 'Advanced management',
          subtitle: 'Tools for bookings, artists, calendars and customer contact.',
          icon: Icons.admin_panel_settings_rounded,
        ),
        const SizedBox(height: 10),
        _ManageWideAction(
          icon: Icons.person_search_rounded,
          title: 'Artist applications',
          subtitle: 'Review DJs, performers and artists applying to play at your venues.',
          onTap: onArtistApplicationsPressed,
        ),
        _ManageWideAction(
          icon: Icons.calendar_month_rounded,
          title: 'Venue events calendar',
          subtitle: 'Open the calendar for a selected venue and review scheduled events.',
          onTap: onCalendarPressed,
        ),
        _ManageWideAction(
          icon: Icons.notifications_active_rounded,
          title: 'Notifications',
          subtitle: 'Review customer notifications and smart alerts.',
          onTap: onNotificationsPressed,
        ),
        const SizedBox(height: 18),
        _DashboardSectionHeader(
          title: 'Subscription capacity',
          subtitle: 'Your plan controls how many venues and premium tools you can manage.',
          icon: Icons.workspace_premium_rounded,
        ),
        const SizedBox(height: 10),
        _ManageCapacityCard(
          venueCount: venues.length,
          taggedVenues: taggedVenues,
          venuesWithContact: venuesWithContact,
          onUpgradePressed: onAddPressed,
        ),
        if (venues.isEmpty) ...[
          const SizedBox(height: 14),
          _EmptyBusinessCard(onAddVenuePressed: onMyVenuesPressed),
        ],
      ],
    );
  }
}

class _ManagePlanHeader extends StatelessWidget {
  const _ManagePlanHeader({
    required this.venueCount,
    required this.venuesWithDeals,
    required this.taggedVenues,
    required this.onMyVenuesPressed,
  });

  final int venueCount;
  final int venuesWithDeals;
  final int taggedVenues;
  final VoidCallback onMyVenuesPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2030).withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryPink, AppColors.primaryPurple],
                  ),
                ),
                child: const Icon(Icons.business_center_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Manage your venues', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(
                      'Light plan • $venueCount active ${venueCount == 1 ? 'venue' : 'venues'}',
                      style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onMyVenuesPressed,
                child: const Text('View all'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _ManageMiniMetric(label: 'Venues', value: venueCount.toString(), icon: Icons.storefront_rounded)),
              const SizedBox(width: 8),
              Expanded(child: _ManageMiniMetric(label: 'Deals', value: venuesWithDeals.toString(), icon: Icons.local_offer_rounded)),
              const SizedBox(width: 8),
              Expanded(child: _ManageMiniMetric(label: 'Tagged', value: taggedVenues.toString(), icon: Icons.sell_rounded)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ManageMiniMetric extends StatelessWidget {
  const _ManageMiniMetric({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.purpleSoft, size: 17),
          const SizedBox(width: 7),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManageActionTile extends StatelessWidget {
  const _ManageActionTile({required this.width, required this.icon, required this.title, required this.subtitle, required this.onTap});

  final double width;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          height: 118,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2030).withValues(alpha: 0.60),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.primaryPurple.withValues(alpha: 0.16),
                    ),
                    child: Icon(icon, color: AppColors.purpleSoft, size: 19),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.42)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManageWideAction extends StatelessWidget {
  const _ManageWideAction({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2030).withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          radius: 23,
          backgroundColor: AppColors.primaryPurple.withValues(alpha: 0.14),
          child: Icon(icon, color: AppColors.purpleSoft),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _ManageCapacityCard extends StatelessWidget {
  const _ManageCapacityCard({
    required this.venueCount,
    required this.taggedVenues,
    required this.venuesWithContact,
    required this.onUpgradePressed,
  });

  final int venueCount;
  final int taggedVenues;
  final int venuesWithContact;
  final VoidCallback onUpgradePressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2030).withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Light plan controls', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: const Text('Light', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$venueCount venues managed • $taggedVenues tagged • $venuesWithContact with contact details',
            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, height: 1.35),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _LockedFeaturePill(icon: Icons.analytics_rounded, label: 'Deep analytics', plan: 'Pro'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LockedFeaturePill(icon: Icons.campaign_rounded, label: 'Campaigns', plan: 'Premium'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class _LockedFeaturePill extends StatelessWidget {
  const _LockedFeaturePill({
    required this.icon,
    required this.label,
    required this.plan,
  });

  final IconData icon;
  final String label;
  final String plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.primaryPurple),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              plan,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab({required this.venues, required this.onFullAnalyticsPressed});

  final List<VenueModel> venues;
  final VoidCallback onFullAnalyticsPressed;

  @override
  Widget build(BuildContext context) {
    final venueIds = venues.map((venue) => venue.id).toList();
    final hasVenues = venues.isNotEmpty;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        18,
        18,
        18,
        MediaQuery.of(context).padding.bottom + 150,
      ),
      children: [
        _AnalyticsHeroCard(
          venueCount: venues.length,
          onFullAnalyticsPressed: onFullAnalyticsPressed,
        ),
        const SizedBox(height: 16),
        if (!hasVenues)
          const _InfoCard(
            icon: Icons.insights_rounded,
            title: 'No analytics yet',
            text: 'Add a venue first. Once users view, save and interact with your venue, analytics will appear here.',
          )
        else ...[
          _DashboardSectionHeader(
            icon: Icons.query_stats_rounded,
            title: 'Performance snapshot',
            subtitle: 'Light plan shows the essentials. Pro unlocks the full breakdown.',
          ),
          const SizedBox(height: 12),
          OwnerAnalyticsSummaryCard(venueIds: venueIds),
          const SizedBox(height: 16),
          _AnalyticsLockedCard(onFullAnalyticsPressed: onFullAnalyticsPressed),
          const SizedBox(height: 16),
          _DashboardSectionHeader(
            icon: Icons.auto_graph_rounded,
            title: 'What analytics will track',
            subtitle: 'Signals that help venues understand demand and customer intent.',
          ),
          const SizedBox(height: 12),
          const _InsightGrid(),
        ],
      ],
    );
  }
}

class _GrowthTab extends StatelessWidget {
  const _GrowthTab({
    required this.venues,
    required this.onBoostPressed,
    required this.onUpgradePressed,
  });

  final List<VenueModel> venues;
  final VoidCallback onBoostPressed;
  final VoidCallback onUpgradePressed;

  @override
  Widget build(BuildContext context) {
    final hasVenues = venues.isNotEmpty;
    final activeVenues = venues.length;
    final venuesWithDeals = venues.where((venue) => venue.hasDeals).length;
    final venuesWithCrowd = venues.where((venue) => venue.crowdLevel.trim().isNotEmpty).length;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        18,
        18,
        18,
        MediaQuery.of(context).padding.bottom + 150,
      ),
      children: [
        _GrowthHeroCard(
          activeVenues: activeVenues,
          totalVenues: venues.length,
          onBoostPressed: onBoostPressed,
          onUpgradePressed: onUpgradePressed,
        ),
        const SizedBox(height: 16),
        _DashboardSectionHeader(
          icon: Icons.rocket_launch_rounded,
          title: 'Growth tools',
          subtitle: 'Turn discovery into visits with premium promotion features.',
        ),
        const SizedBox(height: 12),
        _GrowthToolCard(
          icon: Icons.trending_up_rounded,
          title: 'Boost a venue',
          subtitle: 'Promote one of your venues in discovery surfaces and high-intent areas.',
          planLabel: 'Premium',
          isPrimary: true,
          onTap: hasVenues ? onBoostPressed : onUpgradePressed,
        ),
        _GrowthToolCard(
          icon: Icons.campaign_rounded,
          title: 'Campaigns and notifications',
          subtitle: 'Send targeted updates for events, launches and venue announcements.',
          planLabel: 'Premium',
          onTap: onUpgradePressed,
        ),
        _GrowthToolCard(
          icon: Icons.workspace_premium_rounded,
          title: 'Upgrade plan',
          subtitle: 'Unlock advanced analytics, boosts, campaign tools and stronger visibility.',
          planLabel: 'Pro+',
          onTap: onUpgradePressed,
        ),
        const SizedBox(height: 16),
        _DashboardSectionHeader(
          icon: Icons.check_circle_rounded,
          title: 'Growth readiness',
          subtitle: 'A quick check before spending money on promotion.',
        ),
        const SizedBox(height: 12),
        _GrowthReadinessCard(
          hasVenues: hasVenues,
          activeVenues: activeVenues,
          venuesWithDeals: venuesWithDeals,
          venuesWithCrowd: venuesWithCrowd,
        ),
      ],
    );
  }
}

class _AnalyticsHeroCard extends StatelessWidget {
  const _AnalyticsHeroCard({
    required this.venueCount,
    required this.onFullAnalyticsPressed,
  });

  final int venueCount;
  final VoidCallback onFullAnalyticsPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.purpleDark.withValues(alpha: 0.94),
            AppColors.purple.withValues(alpha: 0.78),
            const Color(0xFF1E2030).withValues(alpha: 0.74),
          ],
        ),
        border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.36)),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.18),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.query_stats_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Analytics', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                    SizedBox(height: 3),
                    Text('Light overview • Pro unlocks detail', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Text('$venueCount venue${venueCount == 1 ? '' : 's'}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Understand what customers view, save and interact with before they visit your venue.',
            style: TextStyle(color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: FilledButton.icon(
              onPressed: onFullAnalyticsPressed,
              icon: const Icon(Icons.lock_open_rounded, size: 18),
              label: const Text('Open detailed analytics'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsLockedCard extends StatelessWidget {
  const _AnalyticsLockedCard({required this.onFullAnalyticsPressed});

  final VoidCallback onFullAnalyticsPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2030).withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.workspace_premium_rounded, color: AppColors.primaryPurple),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pro analytics locked', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                SizedBox(height: 4),
                Text('Unlock per-venue trends, popular drinks, click-throughs and customer intent.', style: TextStyle(height: 1.35)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: onFullAnalyticsPressed,
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
        ],
      ),
    );
  }
}

class _InsightGrid extends StatelessWidget {
  const _InsightGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            _InsightTile(icon: Icons.visibility_rounded, title: 'Profile views', subtitle: 'Who opens your venue'),
            _InsightTile(icon: Icons.search_rounded, title: 'Search demand', subtitle: 'What users look for'),
            _InsightTile(icon: Icons.favorite_rounded, title: 'Saves', subtitle: 'Potential repeat visitors'),
            _InsightTile(icon: Icons.local_bar_rounded, title: 'Drink interest', subtitle: 'Popular menu items'),
          ].map((tile) => SizedBox(width: width, child: tile)).toList(),
        );
      },
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2030).withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.purpleSoft, size: 21),
          const Spacer(),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
        ],
      ),
    );
  }
}

class _GrowthHeroCard extends StatelessWidget {
  const _GrowthHeroCard({
    required this.activeVenues,
    required this.totalVenues,
    required this.onBoostPressed,
    required this.onUpgradePressed,
  });

  final int activeVenues;
  final int totalVenues;
  final VoidCallback onBoostPressed;
  final VoidCallback onUpgradePressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A0B2E).withValues(alpha: 0.96),
            AppColors.primaryPink.withValues(alpha: 0.55),
            const Color(0xFF1E2030).withValues(alpha: 0.78),
          ],
        ),
        border: Border.all(color: AppColors.primaryPink.withValues(alpha: 0.32)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPink.withValues(alpha: 0.14),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.rocket_launch_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Growth Centre', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text('$activeVenues of $totalVenues venues active', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Promote your best venues, unlock premium visibility and turn app discovery into real customers.', style: TextStyle(color: Colors.white70, height: 1.35)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: onBoostPressed,
                    icon: const Icon(Icons.trending_up_rounded, size: 18),
                    label: const Text('Boost'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: onUpgradePressed,
                    icon: const Icon(Icons.workspace_premium_rounded, size: 18),
                    label: const Text('Upgrade'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white70)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GrowthToolCard extends StatelessWidget {
  const _GrowthToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.planLabel,
    required this.onTap,
    this.isPrimary = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String planLabel;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final accent = isPrimary ? AppColors.primaryPink : AppColors.primaryPurple;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2030).withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: accent),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: accent.withValues(alpha: 0.30)),
              ),
              child: Text(planLabel, style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 4),
            const Icon(Icons.chevron_right_rounded, size: 18),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _GrowthReadinessCard extends StatelessWidget {
  const _GrowthReadinessCard({
    required this.hasVenues,
    required this.activeVenues,
    required this.venuesWithDeals,
    required this.venuesWithCrowd,
  });

  final bool hasVenues;
  final int activeVenues;
  final int venuesWithDeals;
  final int venuesWithCrowd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2030).withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          _ReadinessRow(done: hasVenues, label: 'Venue listing created'),
          _ReadinessRow(done: activeVenues > 0, label: 'At least one venue is active'),
          _ReadinessRow(done: venuesWithDeals > 0, label: 'Deal or offer added'),
          _ReadinessRow(done: venuesWithCrowd > 0, label: 'Crowd level recently updated'),
        ],
      ),
    );
  }
}

class _ReadinessRow extends StatelessWidget {
  const _ReadinessRow({required this.done, required this.label});

  final bool done;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: done ? Colors.greenAccent : Colors.white38, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.primaryAction,
    required this.secondaryAction,
    required this.onPrimary,
    required this.onSecondary,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String primaryAction;
  final String secondaryAction;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.purpleDark,
            AppColors.purple,
            AppColors.surfaceElevated,
          ],
        ),
        border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.65)),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            foregroundColor: Colors.white,
            child: Icon(icon, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: FilledButton.icon(
                          onPressed: onPrimary,
                          icon: const Icon(Icons.add, size: 17),
                          label: Text(
                            primaryAction,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: onSecondary,
                          icon: const Icon(Icons.arrow_forward, size: 17),
                          label: Text(
                            secondaryAction,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.25)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.purpleSoft, size: 20),
              const SizedBox(height: 8),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChecklistItem {
  const _ChecklistItem({required this.done, required this.title, required this.subtitle});
  final bool done;
  final String title;
  final String subtitle;
}

class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard({required this.items});
  final List<_ChecklistItem> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: items
            .map(
              (item) => ListTile(
                leading: Icon(item.done ? Icons.check_circle : Icons.radio_button_unchecked, color: item.done ? Colors.green : null),
                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(item.subtitle),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _VenueStatusCard extends StatelessWidget {
  const _VenueStatusCard({required this.venue});

  final VenueModel venue;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.25)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(venue.name.isEmpty ? '?' : venue.name.characters.first.toUpperCase()),
        ),
        title: Text(venue.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${venue.category.isEmpty ? 'Venue' : venue.category} • Crowd: ${venue.crowdLevel}'),
        trailing: Chip(
        side: const BorderSide(color: Color(0xFF9D28FF), width: 1),label: Text(venue.hasDeals ? 'Deals live' : 'No deals')),
      ),
    );
  }
}

class _EmptyBusinessCard extends StatelessWidget {
  const _EmptyBusinessCard({required this.onAddVenuePressed});

  final VoidCallback onAddVenuePressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(Icons.add_business, size: 58, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 14),
            const Text('Create your first venue', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Your dashboard becomes useful once you add a business listing. Then you can add drinks, deals, events and crowd updates.', textAlign: TextAlign.center, style: TextStyle(height: 1.4)),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(onPressed: onAddVenuePressed, icon: const Icon(Icons.add), label: const Text('Add venue')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(context).padding.bottom + 150),
          child: Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: AppColors.purple.withValues(alpha: 0.14),
                child: Icon(icon, color: AppColors.purpleSoft),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text(subtitle, style: TextStyle(height: 1.35, color: Theme.of(context).textTheme.bodySmall?.color)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(context).padding.bottom + 150),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.purpleSoft),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 5),
                Text(text, style: const TextStyle(height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _AddMenuTile extends StatelessWidget {
  const _AddMenuTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
