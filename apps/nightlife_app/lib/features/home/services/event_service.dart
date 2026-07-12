import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vex_engines/experience/application/experience_event_visibility.dart';

import '../models/event_model.dart';
import 'experience_content_support.dart';
import '../../notifications/services/smart_notification_service.dart';
import '../../owner/data/mobile_event_write_payload.dart';

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
          .where(
            (event) => ExperienceEventVisibility.isPublicVisible(
              isDeleted: event.isDeleted,
              isActive: event.isActive,
              startDateTime: event.startDateTime,
              endDateTime: event.endDateTime,
              now: now,
            ),
          )
          .toList();
      return MobileExperienceContentSupport.ordering.sortEventsByStart(
        events: events,
        startDateTime: (event) => event.startDateTime,
      );
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
          .where(
            (event) => ExperienceEventVisibility.isPublicVisible(
              isDeleted: event.isDeleted,
              isActive: event.isActive,
              startDateTime: event.startDateTime,
              endDateTime: event.endDateTime,
              now: now,
            ),
          )
          .toList();
      return MobileExperienceContentSupport.ordering.sortEventsByStart(
        events: events,
        startDateTime: (event) => event.startDateTime,
      );
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
    final eventRef = await _events.add(
      MobileEventWritePayload.buildCreate(
        venueId: venueId,
        title: title,
        description: description,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        category: category,
        imageUrl: imageUrl,
      ),
    );

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