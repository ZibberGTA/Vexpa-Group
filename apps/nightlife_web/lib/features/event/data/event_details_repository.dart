import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/vexda_firebase.dart';
import '../../venue/data/models/event_model.dart';

class EventDetailsView {
  const EventDetailsView({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.startDateTime,
    required this.endDateTime,
    required this.artist,
    required this.venueId,
    required this.venueName,
    required this.venueAddress,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final String imageUrl;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String artist;
  final String venueId;
  final String venueName;
  final String venueAddress;

  String get formattedDate {
    final day = startDateTime.day.toString().padLeft(2, '0');
    final month = startDateTime.month.toString().padLeft(2, '0');
    final hour = startDateTime.hour.toString().padLeft(2, '0');
    final minute = startDateTime.minute.toString().padLeft(2, '0');
    return '$day/$month · $hour:$minute';
  }
}

/// Loads a single event and its host venue from Firestore.
class EventDetailsRepository {
  EventDetailsRepository({FirebaseFirestore? firestore})
      : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  FirebaseFirestore? _resolveFirestore() {
    if (_firestoreOverride != null) return _firestoreOverride;
    if (!VexdaFirebase.isReady) return null;
    return FirebaseFirestore.instance;
  }

  Future<EventDetailsView?> loadEvent(String eventId) async {
    final firestore = _resolveFirestore();
    if (firestore == null) return null;

    final doc = await firestore.collection('events').doc(eventId.trim()).get();
    if (!doc.exists) return null;

    final event = EventModel.fromDoc(doc);
    if (event.isDeleted) return null;

    var venueName = 'Venue';
    var venueAddress = '';
    if (event.venueId.isNotEmpty) {
      final venueDoc =
          await firestore.collection('venues').doc(event.venueId).get();
      final venueData = venueDoc.data();
      if (venueData != null) {
        venueName = venueData['name']?.toString() ?? venueName;
        venueAddress = venueData['address']?.toString() ?? '';
      }
    }

    return EventDetailsView(
      id: event.id,
      title: event.title,
      description: event.description,
      category: event.category,
      imageUrl: event.imageUrl,
      startDateTime: event.startDateTime,
      endDateTime: event.endDateTime,
      artist: event.artist,
      venueId: event.venueId,
      venueName: venueName,
      venueAddress: venueAddress,
    );
  }

  Future<List<EventDetailsView>> loadRelatedEvents(
    String eventId,
    String venueId,
  ) async {
    final firestore = _resolveFirestore();
    if (firestore == null || venueId.isEmpty) return const [];

    final snapshot = await firestore
        .collection('events')
        .where('venueId', isEqualTo: venueId)
        .where('isDeleted', isEqualTo: false)
        .limit(6)
        .get();

    final now = DateTime.now();
    final events = snapshot.docs
        .map(EventModel.fromDoc)
        .where((event) => event.id != eventId && event.endDateTime.isAfter(now))
        .take(4)
        .map(
          (event) => EventDetailsView(
            id: event.id,
            title: event.title,
            description: event.description,
            category: event.category,
            imageUrl: event.imageUrl,
            startDateTime: event.startDateTime,
            endDateTime: event.endDateTime,
            artist: event.artist,
            venueId: event.venueId,
            venueName: '',
            venueAddress: '',
          ),
        )
        .toList();

    return events;
  }
}
