import 'package:flutter/material.dart';

import '../../../core/widgets/home_icon_button.dart';
import '../../auth/services/auth_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  bool _hasUnread(dynamic unreadFor, String? uid) {
    if (uid == null) return false;
    if (unreadFor is List) return unreadFor.contains(uid);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthService.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: const [HomeIconButton()],
      ),
      body: StreamBuilder(
        stream: ChatService.myChatsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data?.docs ?? [];

          if (chats.isEmpty) {
            return const Center(child: Text('No conversations yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final doc = chats[index];
              final data = doc.data();
              final isOwner = currentUserId == data['ownerId'];
              final title = isOwner
                  ? (data['artistName'] ?? 'Artist')
                  : (data['venueName'] ?? 'Venue');
              final receiverId = isOwner ? data['artistId'] : data['ownerId'];
              final lastMessage = data['lastMessage'] ?? '';
              final unread = _hasUnread(data['unreadFor'], currentUserId);

              return Card(
                child: ListTile(
                  leading: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const CircleAvatar(child: Icon(Icons.chat_bubble_outline)),
                      if (unread)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    title,
                    style: TextStyle(
                      fontWeight: unread ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    lastMessage.toString().isEmpty
                        ? 'Start conversation'
                        : lastMessage.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: unread ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          chatId: doc.id,
                          title: title.toString(),
                          receiverId: receiverId?.toString() ?? '',
                        ),
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
