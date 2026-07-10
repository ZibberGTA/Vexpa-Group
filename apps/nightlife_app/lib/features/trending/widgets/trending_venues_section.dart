import 'package:flutter/material.dart';

import '../../analytics/services/analytics_service.dart';
import '../../venues/screens/venue_details_screen.dart';
import '../services/trending_service.dart';

class TrendingVenuesSection extends StatefulWidget {
  final EdgeInsetsGeometry padding;

  const TrendingVenuesSection({
    super.key,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 8),
  });

  @override
  State<TrendingVenuesSection> createState() => _TrendingVenuesSectionState();
}

class _TrendingVenuesSectionState extends State<TrendingVenuesSection> {
  late Future<List<TrendingVenue>> _future;

  @override
  void initState() {
    super.initState();
    _future = TrendingService.getTrendingVenues(
      range: AnalyticsRange.sevenDays,
      limit: 8,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TrendingVenue>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 98,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final items = snapshot.data ?? const <TrendingVenue>[];
        if (items.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: widget.padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.local_fire_department),
                  SizedBox(width: 8),
                  Text(
                    'Trending tonight',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 128,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _TrendingCard(item: item, rank: index + 1);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TrendingCard extends StatelessWidget {
  final TrendingVenue item;
  final int rank;

  const _TrendingCard({required this.item, required this.rank});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 230,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.25)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => VenueDetailsScreen(venueId: item.venue.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: colorScheme.primary.withOpacity(0.12),
                      child: Text('#$rank', style: TextStyle(color: colorScheme.primary, fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    if (item.boostScore > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text('Boosted', style: TextStyle(fontSize: 11)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.venue.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  '${item.score.toStringAsFixed(0)} score • ${item.conversionRate.toStringAsFixed(1)}% save rate',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                ),
                const Spacer(),
                Text(item.venue.crowdLevel.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
