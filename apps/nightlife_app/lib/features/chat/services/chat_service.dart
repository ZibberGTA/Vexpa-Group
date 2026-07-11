import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../home/models/artist_application_model.dart';
import '../../monetisation/services/subscription_service.dart';
import '../../monetisation/services/subscription_entitlements.dart';

class ChatService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get currentUserId => _auth.currentUser?.uid;

  static String chatIdForArtistVenue({
    required String artistId,
    required String venueId,
  }) {
    return 'artist_${artistId}_venue_$venueId';
  }

  static Future<bool> hasAcceptedApplicationBetweenArtistAndVenue({
    required String artistId,
    required String venueId,
  }) async {
    final snapshot = await _db
        .collection('artist_applications')
        .where('artistId', isEqualTo: artistId)
        .where('venueId', isEqualTo: venueId)
        .where('status', isEqualTo: 'accepted')
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  static Future<void> _assertChatAllowed({
    required String artistId,
    required String venueId,
  }) async {
    final uid = currentUserId;
    if (uid == null) {
      throw Exception('Not logged in');
    }

    final hasAccepted = await hasAcceptedApplicationBetweenArtistAndVenue(
      artistId: artistId,
      venueId: venueId,
    );

    if (!hasAccepted) {
      throw Exception(
        'Chat is only available after an artist application has been accepted.',
      );
    }

    if (uid == artistId) {
      final artistActive = await SubscriptionService.isArtistSubscriptionActive();
      if (!SubscriptionEntitlements.artistChatAllowed(
        subscriptionActive: artistActive,
      )) {
        throw Exception('Artist subscription is required to use chat.');
      }
      return;
    }

    final venueActive = await SubscriptionService.isVenueBookingFeatureEnabled(
      venueId,
    );

    if (!SubscriptionEntitlements.venueMessagingAllowed(
      subscriptionActive: venueActive,
    )) {
      throw Exception('Venue Pro is required to message accepted artists.');
    }
  }

  static Future<String> createOrGetChatForApplication(
    ArtistApplicationModel application,
  ) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not logged in');

    if (application.status.toLowerCase() != 'accepted') {
      throw Exception(
        'You can message this artist after accepting their application.',
      );
    }

    await _assertChatAllowed(
      artistId: application.artistId,
      venueId: application.venueId,
    );

    final chatId = chatIdForArtistVenue(
      artistId: application.artistId,
      venueId: application.venueId,
    );
    final chatRef = _db.collection('chats').doc(chatId);

    await chatRef.set({
      'chatId': chatId,
      'artistId': application.artistId,
      'artistName': application.artistName,
      'ownerId': uid == application.artistId
          ? application.venueOwnerId
          : uid,
      'venueId': application.venueId,
      'venueName': application.venueName,
      'participants': FieldValue.arrayUnion([
        application.artistId,
        if (application.venueOwnerId.isNotEmpty) application.venueOwnerId,
        uid,
      ]),
      'lastApplicationId': application.id,
      'applicationIds': FieldValue.arrayUnion([application.id]),
      'chatStatus': 'accepted_only',
      'lastMessage': '',
      'lastSenderId': '',
      'unreadFor': <String>[],
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return chatId;
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> myChatsStream() {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not logged in');

    return _db
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream(
    String chatId,
  ) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots();
  }

  static Future<void> markChatRead(String chatId) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _db.collection('chats').doc(chatId).set({
      'unreadFor': FieldValue.arrayRemove([uid]),
    }, SetOptions(merge: true));
  }

  static Future<void> sendMessage({
    required String chatId,
    required String message,
    required String receiverId,
  }) async {
    final senderId = currentUserId;
    if (senderId == null) return;

    final trimmed = message.trim();
    if (trimmed.isEmpty) return;

    final chatRef = _db.collection('chats').doc(chatId);
    final chatDoc = await chatRef.get();
    final chatData = chatDoc.data() ?? {};

    final artistId = chatData['artistId']?.toString() ?? '';
    final venueId = chatData['venueId']?.toString() ?? '';

    if (artistId.isEmpty || venueId.isEmpty) {
      throw Exception('Chat is missing artist or venue information.');
    }

    await _assertChatAllowed(
      artistId: artistId,
      venueId: venueId,
    );

    await chatRef.collection('messages').add({
      'senderId': senderId,
      'message': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await chatRef.set({
      'lastMessage': trimmed,
      'lastSenderId': senderId,
      'unreadFor': FieldValue.arrayUnion([receiverId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _db.collection('notifications').add({
      'userId': receiverId,
      'title': 'New message',
      'body': trimmed,
      'type': 'chat',
      'relatedId': chatId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
