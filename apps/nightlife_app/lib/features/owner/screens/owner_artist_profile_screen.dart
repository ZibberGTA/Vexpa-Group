import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/home_icon_button.dart';

import '../services/owner_artist_application_service.dart';

class OwnerArtistProfileScreen extends StatelessWidget {
  final String artistId;
  final String fallbackArtistName;
  final bool canRate;

  const OwnerArtistProfileScreen({
    super.key,
    required this.artistId,
    required this.fallbackArtistName,
    required this.canRate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artist Profile'),
        actions: const [HomeIconButton()],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: OwnerArtistApplicationService.artistProfileStream(artistId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading artist: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final exists = snapshot.data?.exists ?? false;
          final data = snapshot.data?.data() ?? {};

          if (!exists) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '$fallbackArtistName has not completed their artist profile yet.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final artistName = data['artistName'] ?? fallbackArtistName;
          final artistType = data['artistType'] ?? '';
          final bio = data['bio'] ?? '';
          final location = data['location'] ?? '';
          final contactEmail = data['contactEmail'] ?? '';
          final phone = data['phone'] ?? '';
          final performanceFee = data['performanceFee'] ?? '';
          final thumbsUpCount = data['thumbsUpCount'] ?? 0;

          final genresRaw = data['genres'];
          final genres = genresRaw is List ? genresRaw : [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 30,
                            child: Icon(Icons.music_note, size: 32),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  artistName,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (artistType.toString().isNotEmpty)
                                  Text(artistType),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.thumb_up_alt_outlined),
                          const SizedBox(width: 8),
                          Text('$thumbsUpCount thumbs up'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (canRate)
                        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          stream:
                              OwnerArtistApplicationService.myThumbsUpStream(
                            artistId,
                          ),
                          builder: (context, thumbsSnapshot) {
                            final hasThumbed =
                                thumbsSnapshot.data?.exists ?? false;

                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: Icon(
                                  hasThumbed
                                      ? Icons.thumb_up
                                      : Icons.thumb_up_alt_outlined,
                                ),
                                label: Text(
                                  hasThumbed
                                      ? 'Remove Thumbs Up'
                                      : 'Give Thumbs Up',
                                ),
                                onPressed: () async {
                                  if (hasThumbed) {
                                    await OwnerArtistApplicationService
                                        .removeThumbsUpArtist(artistId);
                                  } else {
                                    await OwnerArtistApplicationService
                                        .thumbsUpArtist(artistId);
                                  }
                                },
                              ),
                            );
                          },
                        )
                      else
                        const Text(
                          'You can give a thumbs up after accepting this artist.',
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (genres.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: genres.map((genre) {
                        return Chip(
        side: const BorderSide(color: Color(0xFF9D28FF), width: 1),label: Text(genre.toString()));
                      }).toList(),
                    ),
                  ),
                ),
              if (bio.toString().isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(bio),
                  ),
                ),
              Card(
                child: Column(
                  children: [
                    if (location.toString().isNotEmpty)
                      ListTile(
                        leading: const Icon(Icons.location_on_outlined),
                        title: const Text('Location'),
                        subtitle: Text(location),
                      ),
                    if (performanceFee.toString().isNotEmpty)
                      ListTile(
                        leading: const Icon(Icons.payments_outlined),
                        title: const Text('Usual Performance Fee'),
                        subtitle: Text('£$performanceFee'),
                      ),
                    if (contactEmail.toString().isNotEmpty)
                      ListTile(
                        leading: const Icon(Icons.email_outlined),
                        title: const Text('Email'),
                        subtitle: Text(contactEmail),
                      ),
                    if (phone.toString().isNotEmpty)
                      ListTile(
                        leading: const Icon(Icons.phone_outlined),
                        title: const Text('Phone'),
                        subtitle: Text(phone),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}