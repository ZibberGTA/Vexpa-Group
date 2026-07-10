import 'package:flutter/material.dart';

import '../../../core/widgets/home_icon_button.dart';
import '../../analytics/widgets/venue_analytics_card.dart';
import '../../crowd/utils/crowd_decay.dart';
import '../../crowd/services/smart_crowd_service.dart';
import '../../home/models/artist_application_model.dart';
import '../../home/models/deal_model.dart';
import '../../home/models/drink_model.dart';
import '../../home/models/event_model.dart';
import '../../home/models/venue_model.dart';
import '../../home/services/artist_application_service.dart';
import '../../home/services/deal_service.dart';
import '../../home/services/drink_service.dart';
import '../../home/services/event_service.dart';
import 'add_deal_screen.dart';
import 'add_drink_screen.dart';
import 'edit_deal_screen.dart';
import 'edit_drink_screen.dart';
import 'edit_venue_screen.dart';
import 'owner_artist_applications_screen.dart';
import 'update_crowd_screen.dart';
import 'owner_event_calendar_screen.dart';

class OwnerVenueManagementScreen extends StatefulWidget {
  const OwnerVenueManagementScreen({super.key, required this.venue});

  final VenueModel venue;

  @override
  State<OwnerVenueManagementScreen> createState() => _OwnerVenueManagementScreenState();
}

class _OwnerVenueManagementScreenState extends State<OwnerVenueManagementScreen> {
  late final Future<SmartCrowdSnapshot> _crowdFuture;

  @override
  void initState() {
    super.initState();
    DealService.deactivateExpiredDealsForVenue(widget.venue.id);
    _crowdFuture = SmartCrowdService.calculateVenueCrowd(
      venueId: widget.venue.id,
      manualLevel: widget.venue.crowdLevel,
      updatedAt: widget.venue.crowdUpdatedAt ?? widget.venue.updatedAt,
    );
  }

  String get _currentCrowd => CrowdDecay.displayLevel(
        level: widget.venue.crowdLevel.isNotEmpty ? widget.venue.crowdLevel : 'quiet',
        updatedAt: widget.venue.crowdUpdatedAt ?? widget.venue.updatedAt,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.venue.name),
        actions: const [HomeIconButton()],
      ),
      floatingActionButton: _SideCtas(venue: widget.venue),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          FutureBuilder<SmartCrowdSnapshot>(
            future: _crowdFuture,
            builder: (context, snapshot) {
              // Keep the header completely bounded and resilient. If the smart
              // crowd lookup fails or the card is rebuilt while scrolling, fall
              // back to the manual/degraded crowd value instead of rendering a
              // Flutter error box at the top of the management page.
              final crowd = snapshot.hasError ? _currentCrowd : (snapshot.data?.level ?? _currentCrowd);
              final reason = snapshot.hasError ? null : snapshot.data?.reason;
              return _VenueHeader(venue: widget.venue, crowdLevel: crowd, crowdReason: reason);
            },
          ),
          const SizedBox(height: 16),
          _OwnerCounters(venueId: widget.venue.id),
          const SizedBox(height: 16),
          VenueAnalyticsCard(venueId: widget.venue.id),
          const SizedBox(height: 20),
          _ManagementActions(venue: widget.venue, crowdLevel: _currentCrowd),
          const SizedBox(height: 24),
          _ArtistApplicationsCta(venue: widget.venue),
          const SizedBox(height: 24),
          _DrinkCategories(venue: widget.venue),
          const SizedBox(height: 24),
          _DealsSection(venue: widget.venue),
          const SizedBox(height: 24),
          _ManageEventsCta(venue: widget.venue),
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}

class _VenueHeader extends StatelessWidget {
  const _VenueHeader({required this.venue, required this.crowdLevel, this.crowdReason});

  final VenueModel venue;
  final String crowdLevel;
  final String? crowdReason;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (venue.bannerImageUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                venue.bannerImageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Text(venue.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          if (venue.address.isNotEmpty) Text(venue.address),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
        side: const BorderSide(color: Color(0xFF9D28FF), width: 1),label: Text(venue.category.isEmpty ? 'Venue' : venue.category)),
              Chip(
        side: const BorderSide(color: Color(0xFF9D28FF), width: 1),
                avatar: const Icon(Icons.groups, size: 18),
                label: Text('Crowd: ${crowdLevel.toUpperCase()}'),
              ),
              if ((crowdReason ?? '').isNotEmpty)
                Chip(
        side: const BorderSide(color: Color(0xFF9D28FF), width: 1),
                  avatar: const Icon(Icons.auto_graph, size: 18),
                  label: Text(crowdReason!),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OwnerCounters extends StatelessWidget {
  const _OwnerCounters({required this.venueId});
  final String venueId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DrinkModel>>(
      stream: DrinkService.getDrinksForVenue(venueId),
      builder: (context, drinksSnap) {
        return StreamBuilder<List<EventModel>>(
          stream: EventService.getOwnerEventsForVenue(venueId),
          builder: (context, eventsSnap) {
            return StreamBuilder<List<DealModel>>(
              stream: DealService.getDealsForVenue(venueId),
              builder: (context, dealsSnap) {
                final drinks = drinksSnap.data ?? [];
                final events = eventsSnap.data ?? [];
                final deals = dealsSnap.data ?? [];
                return Row(
                  children: [
                    Expanded(child: _CounterPill(icon: Icons.local_bar, label: 'Drinks', value: drinks.length.toString())),
                    const SizedBox(width: 8),
                    Expanded(child: _CounterPill(icon: Icons.event, label: 'Events', value: events.length.toString())),
                    const SizedBox(width: 8),
                    Expanded(child: _CounterPill(icon: Icons.local_offer, label: 'Deals', value: deals.length.toString())),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _CounterPill extends StatelessWidget {
  const _CounterPill({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF9D28FF).withOpacity(0.65)),
      ),
      child: Column(
        children: [
          Icon(icon, color: colorScheme.primary),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _ManagementActions extends StatelessWidget {
  const _ManagementActions({required this.venue, required this.crowdLevel});
  final VenueModel venue;
  final String crowdLevel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.edit),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditVenueScreen(venue: venue))),
          label: const Text('Edit Venue'),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.groups),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UpdateCrowdScreen(venueId: venue.id, venueName: venue.name, currentLevel: crowdLevel))),
          label: const Text('Update Crowd'),
        ),
      ],
    );
  }
}

class _ArtistApplicationsCta extends StatelessWidget {
  const _ArtistApplicationsCta({required this.venue});
  final VenueModel venue;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ArtistApplicationModel>>(
      stream: ArtistApplicationService.getApplicationsForVenue(venue.id),
      builder: (context, snapshot) {
        final pending = (snapshot.data ?? []).where((a) => a.status.toLowerCase() == 'pending').length;
        return Card(
          child: ListTile(
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                const CircleAvatar(child: Icon(Icons.music_note)),
                if (pending > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Center(child: Text(pending > 9 ? '9+' : '$pending', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                    ),
                  ),
              ],
            ),
            title: const Text('Artist Applications', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(pending == 0 ? 'No new applications waiting.' : '$pending new application${pending == 1 ? '' : 's'} waiting for review.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OwnerArtistApplicationsScreen(venue: venue))),
          ),
        );
      },
    );
  }
}

class _DrinkCategories extends StatelessWidget {
  const _DrinkCategories({required this.venue});
  final VenueModel venue;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DrinkModel>>(
      stream: DrinkService.getDrinksForVenue(venue.id),
      builder: (context, snapshot) {
        final drinks = snapshot.data ?? [];
        final grouped = <String, List<DrinkModel>>{};
        for (final drink in drinks) {
          grouped.putIfAbsent(drink.category.isEmpty ? 'Other' : drink.category, () => []).add(drink);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Drinks by Category', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (drinks.isEmpty)
              const Text('No drinks yet. Add your first drink from the action buttons above.')
            else
              ...grouped.entries.map((entry) => Card(
                    child: ExpansionTile(
                      leading: const Icon(Icons.local_bar),
                      title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${entry.value.length} drink${entry.value.length == 1 ? '' : 's'}'),
                      children: entry.value.map((drink) => ListTile(
                            title: Text(drink.name),
                            subtitle: Text(drink.description),
                            trailing: Text(drink.formattedPrice),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditDrinkScreen(drink: drink))),
                          )).toList(),
                    ),
                  )),
          ],
        );
      },
    );
  }
}

class _DealsSection extends StatelessWidget {
  const _DealsSection({required this.venue});
  final VenueModel venue;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DealModel>>(
      stream: DealService.getDealsForVenue(venue.id),
      builder: (context, snapshot) {
        final deals = snapshot.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: Text('Active Deals', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Deal'),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddDealScreen(venue: venue))),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (deals.isEmpty)
              const Text('No active deals. Expired deals are hidden from customers and can be reused by updating their dates/times.')
            else
              ...deals.map((deal) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.local_offer),
                      title: Text(deal.title),
                      subtitle: Text('${deal.description}\n${deal.startTime} - ${deal.endTime}'),
                      isThreeLine: true,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditDealScreen(deal: deal))),
                    ),
                  )),
          ],
        );
      },
    );
  }
}

class _SideCtas extends StatelessWidget {
  const _SideCtas({required this.venue});
  final VenueModel venue;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'add_drink_${venue.id}',
            tooltip: 'Add Drink',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddDrinkScreen(venue: venue))),
            child: const Icon(Icons.local_bar),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.small(
            heroTag: 'add_deal_${venue.id}',
            tooltip: 'Add Deal',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddDealScreen(venue: venue))),
            child: const Icon(Icons.local_offer),
          ),
        ],
      ),
    );
  }
}

class _ManageEventsCta extends StatelessWidget {
  const _ManageEventsCta({required this.venue});
  final VenueModel venue;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<EventModel>>(
      stream: EventService.getOwnerEventsForVenue(venue.id),
      builder: (context, snapshot) {
        final events = snapshot.data ?? [];
        final nextEvent = events.isEmpty ? null : events.first;
        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.calendar_month)),
            title: const Text('Manage Events', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              nextEvent == null
                  ? 'Open your venue calendar and add upcoming bookings.'
                  : '${events.length} upcoming • Next: ${nextEvent.title}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => OwnerEventCalendarScreen(venue: venue)),
            ),
          ),
        );
      },
    );
  }
}
