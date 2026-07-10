import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/event_model.dart';
import '../../notifications/services/smart_notification_service.dart';

class EventService {
  static final _events = FirebaseFirestore.instance.collection('events');

  static Stream<List<EventModel>> getEventsForVenue(String venueId) {
    return _events
        .where('venueId', isEqualTo: venueId)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      final events = snapshot.docs
          .map((doc) => EventModel.fromDoc(doc))
          .where((event) => event.endDateTime.isAfter(now))
          .toList();
      events.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
      return events;
    });
  }

  static Stream<List<EventModel>> getOwnerEventsForVenue(String venueId) {
    return _events
        .where('venueId', isEqualTo: venueId)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      final events = snapshot.docs
          .map((doc) => EventModel.fromDoc(doc))
          .where((event) => event.endDateTime.isAfter(now))
          .toList();
      events.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
      return events;
    });
  }

  static Future<void> addEvent({
    required String venueId,
    required String title,
    required String description,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required String category,
    String imageUrl = '',
  }) async {
    final eventRef = await _events.add({
      'venueId': venueId,
      'title': title.trim(),
      'description': description.trim(),
      'dateTime': Timestamp.fromDate(startDateTime),
      'startDateTime': Timestamp.fromDate(startDateTime),
      'endDateTime': Timestamp.fromDate(endDateTime),
      'createdAt': Timestamp.now(),
      'category': category,
      'imageUrl': imageUrl.trim(),
      'isDeleted': false,
      'notificationSent': false,
    });

    try {
      final venueSnapshot = await FirebaseFirestore.instance.collection('venues').doc(venueId).get();
      final venueName = (venueSnapshot.data()?['name'] ?? 'Saved venue').toString();

      await SmartNotificationService.notifyFavouriteUsersNewEvent(
        venueId: venueId,
        venueName: venueName,
        eventTitle: title.trim(),
        eventDateTime: startDateTime,
      );

      await eventRef.update({'notificationSent': true});
    } catch (e) {
      // Event creation must not fail just because notification permissions,
      // indexes, or user notification writes fail. The event remains saved
      // and can still appear in venue management and on the map/event glow.
      await eventRef.update({
        'notificationSent': false,
        'notificationError': e.toString(),
        'notificationAttemptedAt': Timestamp.now(),
      });
    }
  }

  static Future<void> deleteEvent(String eventId) async {
    await _events.doc(eventId).update({
      'isDeleted': true,
      'deletedAt': Timestamp.now(),
    });
  }
}