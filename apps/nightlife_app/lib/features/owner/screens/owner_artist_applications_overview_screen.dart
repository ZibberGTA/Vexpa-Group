import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/home_icon_button.dart';
import '../../../core/widgets/premium_scaffold.dart';
import '../../auth/services/auth_service.dart';
import '../../home/models/artist_application_model.dart';
import '../../home/models/venue_model.dart';
import '../../home/services/artist_application_service.dart';
import '../../home/services/venue_service.dart';
import 'owner_artist_applications_screen.dart';

class OwnerArtistApplicationsOverviewScreen extends StatelessWidget {
  const OwnerArtistApplicationsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    if (user == null) {
      return const PremiumScaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    return PremiumScaffold(
      appBar: AppBar(
        title: const Text('Artist Applications'),
        actions: const [HomeIconButton()],
      ),
      body: StreamBuilder<List<VenueModel>>(
        stream: VenueService.getVenuesForOwner(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Could not load venues: ${snapshot.error}'));
          }

          final venues = snapshot.data ?? [];

          if (venues.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                _OverviewHeader(),
                SizedBox(height: 14),
                _EmptyApplicationsState(),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: venues.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              if (index == 0) return const _OverviewHeader();
              return _ArtistVenueApplicationsCard(venue: venues[index - 1]);
            },
          );
        },
      ),
    );
  }
}

class _OverviewHeader extends StatelessWidget {
  const _OverviewHeader();

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
            AppColors.purple.withOpacity(0.70),
            const Color(0xFF1E2030).withOpacity(0.66),
          ],
        ),
        border: Border.all(color: AppColors.primaryPurple.withOpacity(0.36)),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withOpacity(0.16),
            blurRadius: 24,
            offset: const Offset(0, 12),
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
            child: const Icon(Icons.person_search_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Artist applications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Review DJs, performers and artists applying across all your venues.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.76),
                    fontSize: 13,
                    height: 1.35,
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

class _ArtistVenueApplicationsCard extends StatelessWidget {
  const _ArtistVenueApplicationsCard({required this.venue});

  final VenueModel venue;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ArtistApplicationModel>>(
      stream: ArtistApplicationService.getApplicationsForVenue(venue.id),
      builder: (context, snapshot) {
        final applications = snapshot.data ?? [];
        final pending = applications.where((app) => app.status.toLowerCase() == 'pending').length;
        final approved = applications.where((app) => app.status.toLowerCase() == 'accepted').length;
        final rejected = applications.where((app) => app.status.toLowerCase() == 'rejected').length;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OwnerArtistApplicationsScreen(venue: venue),
            ),
          ),
          child: Container(
            height: 198,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primaryPurple.withOpacity(0.36)),
              color: const Color(0xFF181925),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.24),
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
                        Colors.black.withOpacity(0.84),
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
                              border: Border.all(color: Colors.white.withOpacity(0.18)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 16),
                                const SizedBox(width: 2),
                                Text(
                                  'View Applications',
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
                      if (snapshot.hasError)
                        _StatusChip(
                          icon: Icons.error_outline_rounded,
                          label: 'Could not load',
                          color: Colors.redAccent,
                        )
                      else if (isLoading)
                        const _StatusChip(
                          icon: Icons.hourglass_empty_rounded,
                          label: 'Loading...',
                          color: Colors.white,
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _StatusChip(
                              icon: Icons.schedule_rounded,
                              label: '$pending pending',
                              color: Colors.orangeAccent,
                            ),
                            _StatusChip(
                              icon: Icons.check_circle_outline_rounded,
                              label: '$approved approved',
                              color: Colors.greenAccent,
                            ),
                            _StatusChip(
                              icon: Icons.cancel_outlined,
                              label: '$rejected rejected',
                              color: Colors.redAccent,
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.62),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.42)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.14),
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

class _EmptyApplicationsState extends StatelessWidget {
  const _EmptyApplicationsState();

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
            'No venues yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 6),
          Text(
            'Once your venues are added, artist applications will appear here by venue.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
