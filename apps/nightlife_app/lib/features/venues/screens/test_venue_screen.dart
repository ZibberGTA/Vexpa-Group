import 'package:flutter/material.dart';

import '../services/venue_details_service.dart';

class TestVenueScreen extends StatelessWidget {
  final String venueId;

  const TestVenueScreen({
    super.key,
    required this.venueId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Venue Test'),
      ),
      body: StreamBuilder(
        stream: VenueDetailsService.venueStream(venueId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final venue = snapshot.data;

          if (venue == null) {
            return const Center(child: Text('Venue not found'));
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  venue.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(venue.description),
                const SizedBox(height: 8),
                Text('Type: ${venue.venueType}'),
                Text('Crowd: ${venue.currentCrowdLevel}'),
                Text('Score: ${venue.currentCrowdScore}'),
              ],
            ),
          );
        },
      ),
    );
  }
}