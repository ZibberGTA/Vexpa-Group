import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/home_icon_button.dart';

class TopArtistsScreen extends StatelessWidget {
  const TopArtistsScreen({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _stream() {
    return FirebaseFirestore.instance
        .collection('artist_profiles')
        .where('status', isEqualTo: 'active')
        .orderBy('thumbsUpCount', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Artists'),
        actions: const [HomeIconButton()],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _stream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading artists:\n${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final artists = snapshot.data?.docs ?? [];

          if (artists.isEmpty) {
            return const Center(child: Text('No artists yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: artists.length,
            itemBuilder: (context, index) {
              final data = artists[index].data();
              final artistName = data['artistName'] ?? 'Artist';
              final artistType = data['artistType'] ?? '';
              final location = data['location'] ?? '';
              final thumbsUpCount = data['thumbsUpCount'] ?? 0;
              final featured = data['featuredArtist'] == true;
              final isTopThree = index < 3;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: isTopThree
                        ? const Icon(Icons.emoji_events)
                        : Text('${index + 1}'),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          artistName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (featured)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(Icons.workspace_premium, size: 20),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    [
                      if (artistType.toString().isNotEmpty) artistType,
                      if (location.toString().isNotEmpty) location,
                      '$thumbsUpCount thumbs up',
                      if (featured) 'Featured',
                    ].join(' • '),
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
