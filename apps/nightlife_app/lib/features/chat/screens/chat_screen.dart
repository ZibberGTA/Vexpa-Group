import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/home_icon_button.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String title;
  final String receiverId;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.title,
    required this.receiverId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ChatService.markChatRead(widget.chatId);
  }

  Future<void> _send() async {
    final message = messageController.text;
    messageController.clear();

    try {
      await ChatService.sendMessage(
        chatId: widget.chatId,
        message: message,
        receiverId: widget.receiverId,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ChatService.currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: const [HomeIconButton()],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: ChatService.messagesStream(widget.chatId),
              builder: (context, snapshot) {
                final messages = snapshot.data?.docs ?? [];

                if (messages.isEmpty) {
                  return const Center(child: Text('No messages yet.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data();
                    final isMe = data['senderId'] == currentUserId;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(data['message'] ?? ''),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: const InputDecoration(
                        hintText: 'Message...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.send),
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
