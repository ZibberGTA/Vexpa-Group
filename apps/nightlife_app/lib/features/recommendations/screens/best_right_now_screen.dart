import 'package:flutter/material.dart';

import '../../venues/screens/venue_details_screen.dart';
import '../services/venue_recommendation_service.dart';

class BestRightNowScreen extends StatelessWidget {
  const BestRightNowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Best Right Now')),
      body: StreamBuilder<List<VenueRecommendation>>(
        stream: VenueRecommendationService.recommendedNow(limit: 25),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Could not load recommendations: ${snapshot.error}'));
          }

          final items = snapshot.data ?? const <VenueRecommendation>[];
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No strong venue signals right now. Check back once venues add deals, events or crowd updates.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: items.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return const _BestNowHeader();
              }

              final item = items[index - 1];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: CircleAvatar(
                    child: Text(index.toString()),
                  ),
                  title: Text(
                    item.venue.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(item.reason.isEmpty ? 'Good activity signal' : item.reason),
                  trailing: Chip(
        side: const BorderSide(color: Color(0xFF9D28FF), width: 1),
                    label: Text('${item.score}'),
                    avatar: const Icon(Icons.auto_awesome, size: 18),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VenueDetailsScreen(venueId: item.venue.id),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _BestNowHeader extends StatelessWidget {
  const _BestNowHeader();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: colorScheme.primary.withOpacity(0.10),
      ),
      child: const Row(
        children: [
          Icon(Icons.auto_awesome, size: 34),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Best places right now', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Ranked by live crowd, active deals, upcoming events and venue activity.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
