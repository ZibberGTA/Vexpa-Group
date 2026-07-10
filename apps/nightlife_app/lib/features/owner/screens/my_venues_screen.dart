import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/home_icon_button.dart';
import '../../../core/widgets/premium_scaffold.dart';
import '../../auth/services/auth_service.dart';
import '../../home/models/venue_model.dart';
import '../../crowd/utils/crowd_decay.dart';
import '../../home/services/deal_service.dart';
import '../../home/services/drink_service.dart';
import '../../home/services/event_service.dart';
import '../../home/services/venue_service.dart';
import 'owner_venue_management_screen.dart';

class MyVenuesScreen extends StatelessWidget {
  const MyVenuesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return PremiumScaffold(
      appBar: AppBar(
        title: const Text('My Venues'),
        actions: const [HomeIconButton()],
      ),
      body: StreamBuilder<List<VenueModel>>(
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
            return ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                _UpgradeCard(),
                SizedBox(height: 18),
                _EmptyVenueState(),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: venues.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              if (index == 0) return const _UpgradeCard();
              return _VenueSummaryCard(venue: venues[index - 1]);
            },
          );
        },
      ),
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.purpleDark.withOpacity(0.92),
            AppColors.purple.withOpacity(0.74),
            const Color(0xFF1E2030).withOpacity(0.72),
          ],
        ),
        border: Border.all(
          color: AppColors.primaryPurple.withOpacity(0.40),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withOpacity(0.18),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.rocket_launch_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Grow your venues',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Upgrade to add more venues, attract more customers and unlock advanced growth tools.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.76),
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _MiniFeaturePill(icon: Icons.add_business_rounded, label: 'More venues'),
                    _MiniFeaturePill(icon: Icons.campaign_rounded, label: 'Boosts'),
                    _MiniFeaturePill(icon: Icons.analytics_rounded, label: 'Analytics'),
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

class _VenueSummaryCard extends StatelessWidget {
  const _VenueSummaryCard({required this.venue});
  final VenueModel venue;

  @override
  Widget build(BuildContext context) {
    final crowdLevel = CrowdDecay.displayLevel(
      level: venue.crowdLevel,
      updatedAt: venue.crowdUpdatedAt ?? venue.updatedAt,
    );

    return StreamBuilder(
      stream: DrinkService.getDrinksForVenue(venue.id),
      builder: (context, drinksSnap) {
        return StreamBuilder(
          stream: EventService.getEventsForVenue(venue.id),
          builder: (context, eventsSnap) {
            return StreamBuilder(
              stream: DealService.getDealsForVenue(venue.id),
              builder: (context, dealsSnap) {
                final drinks = drinksSnap.data?.length ?? 0;
                final events = eventsSnap.data?.length ?? 0;
                final deals = dealsSnap.data?.length ?? 0;

                return InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OwnerVenueManagementScreen(venue: venue),
                    ),
                  ),
                  child: Container(
                    height: 220,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.primaryPurple.withOpacity(0.36),
                      ),
                      color: const Color(0xFF181925),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.26),
                          blurRadius: 22,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (venue.bannerImageUrl.isNotEmpty)
                          Image.network(
                            venue.bannerImageUrl,
                            fit: BoxFit.cover,
                            cacheWidth: 900,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.18),
                                Colors.black.withOpacity(0.80),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _LogoBubble(venue: venue),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.52),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.18),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 16),
                                        const SizedBox(width: 2),
                                        Text(
                                          'Manage',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.94),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                venue.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                venue.category.isEmpty ? 'Venue listing' : venue.category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.78),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _InfoChip(icon: Icons.local_bar_rounded, label: '$drinks drinks'),
                                  _InfoChip(icon: Icons.event_rounded, label: '$events events'),
                                  _InfoChip(icon: Icons.local_offer_rounded, label: '$deals deals'),
                                  _InfoChip(icon: Icons.groups_rounded, label: 'Crowd $crowdLevel'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _LogoBubble extends StatelessWidget {
  const _LogoBubble({required this.venue});

  final VenueModel venue;

  @override
  Widget build(BuildContext context) {
    if (venue.logoUrl.isNotEmpty) {
      return Container(
        width: 44,
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.48),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.16)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            venue.logoUrl,
            fit: BoxFit.cover,
            cacheWidth: 160,
            errorBuilder: (_, __, ___) => _InitialBubble(name: venue.name),
          ),
        ),
      );
    }

    return _InitialBubble(name: venue.name);
  }
}

class _InitialBubble extends StatelessWidget {
  const _InitialBubble({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.48),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Text(
        name.isEmpty ? '?' : name[0].toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.62),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.primaryPurple.withOpacity(0.42),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.16),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withOpacity(0.92)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniFeaturePill extends StatelessWidget {
  const _MiniFeaturePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.90), size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.88),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyVenueState extends StatelessWidget {
  const _EmptyVenueState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF1E2030).withOpacity(0.60),
        border: Border.all(color: AppColors.primaryPurple.withOpacity(0.25)),
      ),
      child: const Column(
        children: [
          Icon(Icons.storefront_rounded, size: 42),
          SizedBox(height: 12),
          Text(
            'You have no venues yet.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 6),
          Text(
            'Once your venue is added, it will appear here for management.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
