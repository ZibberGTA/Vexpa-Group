import 'package:flutter/material.dart';

import '../../../core/widgets/home_icon_button.dart';

import '../../home/models/artist_application_model.dart';
import '../../home/models/venue_model.dart';
import '../../home/services/artist_application_service.dart';
import 'artist_application_details_screen.dart';
import 'owner_artist_profile_screen.dart';

class OwnerArtistApplicationsScreen extends StatelessWidget {
  final VenueModel venue;

  const OwnerArtistApplicationsScreen({
    super.key,
    required this.venue,
  });

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  int statusPriority(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return 0;
      case 'pending':
        return 1;
      case 'rejected':
      default:
        return 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Applications - ${venue.name}'),
        actions: const [HomeIconButton()],
      ),
      body: StreamBuilder<List<ArtistApplicationModel>>(
        stream: ArtistApplicationService.getApplicationsForVenue(venue.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  'Error loading applications:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final applications = [...(snapshot.data ?? [])];

          applications.sort((a, b) {
            final statusCompare = statusPriority(a.status).compareTo(
              statusPriority(b.status),
            );

            if (statusCompare != 0) return statusCompare;

            return b.artistThumbsUpCount.compareTo(a.artistThumbsUpCount);
          });

          if (applications.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No artist applications yet.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final application = applications[index];
              final color = statusColor(application.status);
              final canRate = application.status.toLowerCase() == 'accepted';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.12),
                          child: Icon(Icons.music_note, color: color),
                        ),
                        title: Text(
                          application.artistName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${application.performanceType} • ${application.genre}\n'
                          'Status: ${application.status.toUpperCase()}\n'
                          'Thumbs up: ${application.artistThumbsUpCount}',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ArtistApplicationDetailsScreen(
                                application: application,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.person_search),
                              label: const Text('Artist Profile'),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OwnerArtistProfileScreen(
                                      artistId: application.artistId,
                                      fallbackArtistName:
                                          application.artistName,
                                      canRate: canRate,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.description_outlined),
                              label: const Text('Application'),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ArtistApplicationDetailsScreen(
                                      application: application,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
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