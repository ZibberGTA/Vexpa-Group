import 'package:flutter/material.dart';

import '../../../core/widgets/home_icon_button.dart';
import '../../analytics/widgets/venue_analytics_card.dart';
import '../../monetisation/screens/owner_upgrade_screen.dart';
import '../../monetisation/services/subscription_entitlements.dart';
import '../../monetisation/services/subscription_service.dart';
import '../../home/models/venue_model.dart';

class OwnerAnalyticsDashboardScreen extends StatelessWidget {
  const OwnerAnalyticsDashboardScreen({super.key, required this.venues});

  final List<VenueModel> venues;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Analytics'),
        actions: const [HomeIconButton()],
      ),
      body: FutureBuilder<bool>(
        future: SubscriptionService.isOwnerVenueProActive(),
        builder: (context, subscriptionSnapshot) {
          final isPro = SubscriptionEntitlements.ownerAnalyticsBreakdownAllowed(
            subscriptionActive: subscriptionSnapshot.data == true,
          );

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              _Header(venueCount: venues.length),
              const SizedBox(height: 16),
              OwnerAnalyticsSummaryCard(venueIds: venues.map((v) => v.id).toList()),
              const SizedBox(height: 18),
              if (!isPro) ...[
                _UpgradeAnalyticsCard(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OwnerUpgradeScreen()),
                  ),
                ),
                const SizedBox(height: 18),
              ],
              const Text('Venue breakdown', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (venues.isEmpty)
                const Text('Add a venue to start collecting analytics.')
              else if (!isPro)
                const Text('Upgrade to Owner Pro to unlock per-venue breakdowns, top drinks, top deals, trends and revenue insights.')
              else
                ...venues.map((venue) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: VenueAnalyticsCard(venueId: venue.id),
                    )),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.venueCount});
  final int venueCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: colorScheme.primary.withOpacity(0.10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            child: const Icon(Icons.query_stats),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Business intelligence', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 4),
                Text('Track venue views, favourite taps, drink views, deal engagement, event interest and crowd activity across $venueCount venue${venueCount == 1 ? '' : 's'}.')
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _UpgradeAnalyticsCard extends StatelessWidget {
  const _UpgradeAnalyticsCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock_open, color: colorScheme.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Unlock advanced owner analytics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Owner Pro adds revenue estimates, ROI signals, top-performing drinks/deals, venue boosts and featured visibility.',
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.workspace_premium),
                label: const Text('View Owner Pro'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
