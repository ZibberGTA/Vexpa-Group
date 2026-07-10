import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/home_icon_button.dart';
import '../../bookings/screens/booking_dashboard_screen.dart';
import '../../chat/screens/chat_screen.dart';
import '../../chat/screens/chat_list_screen.dart';
import '../../chat/services/chat_service.dart';
import '../../home/models/artist_application_model.dart';
import '../../home/services/artist_application_service.dart';
import '../../monetisation/screens/artist_subscription_required_screen.dart';
import '../../monetisation/services/subscription_service.dart';
import '../services/artist_service.dart';
import 'artist_apply_screen.dart';
import 'artist_profile_screen.dart';


class _ArtistProFeaturesCard extends StatelessWidget {
  const _ArtistProFeaturesCard();

  @override
  Widget build(BuildContext context) {
    const features = [
      'Apply to perform at venues',
      'Appear in venue artist searches',
      'Receive booking requests',
      'Monthly booking calendar',
      'Gig notifications and venue messaging',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Artist Pro subscription',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text('£4.99 / month unlocks:'),
          const SizedBox(height: 8),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(feature)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ArtistDashboardScreen extends StatelessWidget {
  const ArtistDashboardScreen({super.key});

  Color _statusColor(String status) {
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

  Widget _applicationCard(BuildContext context, ArtistApplicationModel application) {
    final color = _statusColor(application.status);
    final accepted = application.status.toLowerCase() == 'accepted';
    final pending = application.status.toLowerCase() == 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                child: Icon(Icons.music_note, color: color),
              ),
              title: Text(application.venueName),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status: ${application.status.toUpperCase()}'),
                  if (application.performanceType.isNotEmpty)
                    Text('Type: ${application.performanceType}'),
                  if (application.priceExpectation.isNotEmpty)
                    Text('Fee: £${application.priceExpectation}'),
                ],
              ),
              isThreeLine: true,
              trailing: pending
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        ArtistApplicationService.deleteApplication(application.id);
                      },
                    )
                  : null,
            ),
            if (accepted) ...[
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Message Venue'),
                  onPressed: () async {
                    try {
                      final chatId = await ChatService.createOrGetChatForApplication(
                        application,
                      );

                      if (!context.mounted) return;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            chatId: chatId,
                            title: application.venueName,
                            receiverId: application.venueOwnerId,
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e.toString().replaceFirst('Exception: ', ''),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Artist Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ArtistProfileScreen(),
                ),
              );
            },
          ),
          const HomeIconButton(),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: ArtistService.artistProfileStream(),
        builder: (context, profileSnapshot) {
          final profileExists = profileSnapshot.data?.exists ?? false;
          final profile = profileSnapshot.data?.data();
          final thumbsUpCount = profile?['thumbsUpCount'] ?? 0;

          return FutureBuilder<bool>(
            future: SubscriptionService.isArtistSubscriptionActive(),
            builder: (context, subscriptionSnapshot) {
              final subscriptionActive = subscriptionSnapshot.data ?? false;

              return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: profileExists
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile?['artistName'] ?? 'Artist',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(profile?['artistType'] ?? ''),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.thumb_up_alt_outlined),
                                const SizedBox(width: 8),
                                Text('$thumbsUpCount thumbs up'),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(profile?['bio'] ?? ''),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Edit Profile'),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const ArtistProfileScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.event_available),
                                    label: const Text('Bookings'),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const BookingDashboardScreen(
                                            ownerView: false,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.chat_bubble_outline),
                                label: const Text('Messages'),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ChatListScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (subscriptionActive)
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  icon: const Icon(Icons.music_note),
                                  label: const Text('Apply to perform'),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const ArtistApplyScreen(),
                                      ),
                                    );
                                  },
                                ),
                              )
                            else
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Subscription required to apply',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Create your profile, activate Artist Pro, then the Apply to Perform button will appear.',
                                    ),
                                    const SizedBox(height: 10),
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.workspace_premium_outlined),
                                      label: const Text('View Artist Pro'),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const ArtistSubscriptionRequiredScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Create your artist profile',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Venues need to see who you are before accepting performance applications.',
                            ),
                            const SizedBox(height: 12),
                            const _ArtistProFeaturesCard(),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              child: const Text('Create Profile'),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ArtistProfileScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Sent Applications',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              if (uid == null)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('You must be logged in to view applications.'),
                  ),
                )
              else
                StreamBuilder<List<ArtistApplicationModel>>(
                  stream: ArtistApplicationService.getApplicationsForArtist(uid),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('Error loading applications: ${snapshot.error}'),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final applications = snapshot.data ?? [];

                    if (applications.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('You have not sent any applications yet.'),
                        ),
                      );
                    }

                    return Column(
                      children: applications.map((app) => _applicationCard(context, app)).toList(),
                    );
                  },
                ),
              const SizedBox(height: 80),
            ],
          );
            },
          );
        },
      ),
    );
  }
}
