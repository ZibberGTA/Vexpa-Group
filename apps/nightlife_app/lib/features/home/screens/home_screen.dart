import 'package:flutter/material.dart';

import '../../auth/screens/login_screen.dart';
import '../../auth/services/auth_service.dart';
import '../models/venue_model.dart';
import '../services/venue_service.dart';
import '../../trending/widgets/trending_venues_section.dart';
import 'venue_details_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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

  Color _crowdColor(String crowdLevel) {
    switch (crowdLevel.toLowerCase()) {
      case 'quiet':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'busy':
        return Colors.deepOrange;
      case 'packed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DrinkSpot Venues'),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<List<VenueModel>>(
        stream: VenueService.getVenues(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final venues = snapshot.data ?? [];

          if (venues.isEmpty) {
            return const Center(
              child: Text('No venues added yet.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: venues.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return const TrendingVenuesSection(
                  padding: EdgeInsets.only(bottom: 16),
                );
              }

              final venue = venues[index - 1];

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    venue.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(venue.address),
                        const SizedBox(height: 8),
                        Text('Category: ${venue.category}'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _crowdColor(venue.crowdLevel),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            venue.crowdLevel,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VenueDetailsScreen(venue: venue),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}