import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/home_icon_button.dart';
import '../../auth/services/auth_service.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _fallbackStream() {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) throw Exception('Not logged in');

    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          actions: [
            TextButton(
              onPressed: NotificationService.markAllRead,
              child: const Text('Read all'),
            ),
            const HomeIconButton(),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.person_outline), text: 'Personal'),
              Tab(icon: Icon(Icons.storefront), text: 'Business'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _NotificationList(
              stream: _fallbackStream(),
              emptyText: 'No personal notifications yet.',
              audienceFilter: 'user',
            ),
            _NotificationList(
              stream: _fallbackStream(),
              emptyText: 'No business notifications yet.',
              audienceFilter: 'business',
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({required this.stream, required this.emptyText, required this.audienceFilter});

  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final String emptyText;
  final String audienceFilter;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final notifications = (snapshot.data?.docs ?? []).where((doc) {
          final audience = (doc.data()['audience'] ?? 'user').toString();
          if (audienceFilter == 'user') return audience != 'business';
          return audience == 'business';
        }).toList();

        if (notifications.isEmpty) {
          return Center(child: Text(emptyText));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final doc = notifications[index];
            final data = doc.data();
            final isRead = data['isRead'] == true;

            return Card(
              child: ListTile(
                leading: Icon(
                  audienceFilter == 'business'
                      ? Icons.business_center_outlined
                      : (isRead ? Icons.notifications_none : Icons.notifications_active),
                ),
                title: Text(
                  data['title'] ?? '',
                  style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold),
                ),
                subtitle: Text(data['body'] ?? ''),
                trailing: isRead
                    ? null
                    : TextButton(
                        onPressed: () => NotificationService.markRead(doc.id),
                        child: const Text('Read'),
                      ),
              ),
            );
          },
        );
      },
    );
  }
}
