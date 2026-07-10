import 'package:cloud_firestore/cloud_firestore.dart';

import 'notification_service.dart';

class SmartNotificationService {
  SmartNotificationService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> notifyFavouriteUsersNewDeal({
    required String venueId,
    required String venueName,
    required String dealTitle,
    DateTime? startDateTime,
    DateTime? endDateTime,
  }) async {
    final now = DateTime.now();

    // Never notify for crowd updates, expired deals, or deals that are not usable yet.
    if (endDateTime != null && !endDateTime.isAfter(now)) return;
    if (startDateTime != null && startDateTime.isAfter(now.add(const Duration(hours: 24)))) {
      return;
    }

    final existingLog = await _db
        .collection('smart_notification_logs')
        .where('venueId', isEqualTo: venueId)
        .where('trigger', isEqualTo: 'saved_venue_deal')
        .where('title', isEqualTo: dealTitle)
        .limit(1)
        .get();

    if (existingLog.docs.isNotEmpty) return;

    final favourites = await _db
        .collection('favourites')
        .where('venueId', isEqualTo: venueId)
        .limit(200)
        .get();

    final notified = <String>{};
    for (final doc in favourites.docs) {
      final userId = (doc.data()['userId'] ?? '').toString();
      if (userId.isEmpty || notified.contains(userId)) continue;
      notified.add(userId);

      await NotificationService.createNotification(
        userId: userId,
        title: 'New deal at $venueName',
        body: dealTitle,
        type: 'saved_venue_deal_alert',
        relatedId: venueId,
      );
    }

    await _db.collection('smart_notification_logs').add({
      'venueId': venueId,
      'venueName': venueName,
      'title': dealTitle,
      'trigger': 'saved_venue_deal',
      'usersNotified': notified.length,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }


  static Future<void> notifyFavouriteUsersNewEvent({
    required String venueId,
    required String venueName,
    required String eventTitle,
    required DateTime eventDateTime,
  }) async {
    if (eventDateTime.isBefore(DateTime.now())) return;

    final existingLog = await _db
        .collection('smart_notification_logs')
        .where('venueId', isEqualTo: venueId)
        .where('trigger', isEqualTo: 'saved_venue_event')
        .where('title', isEqualTo: eventTitle)
        .limit(1)
        .get();

    if (existingLog.docs.isNotEmpty) return;

    final favourites = await _db
        .collection('favourites')
        .where('venueId', isEqualTo: venueId)
        .limit(200)
        .get();

    final notified = <String>{};
    for (final doc in favourites.docs) {
      final userId = (doc.data()['userId'] ?? '').toString();
      if (userId.isEmpty || notified.contains(userId)) continue;
      notified.add(userId);

      await NotificationService.createNotification(
        userId: userId,
        title: 'New event at $venueName',
        body: eventTitle,
        type: 'saved_venue_event_alert',
        relatedId: venueId,
      );
    }

    await _db.collection('smart_notification_logs').add({
      'venueId': venueId,
      'venueName': venueName,
      'trigger': 'saved_venue_event',
      'title': eventTitle,
      'usersNotified': notified.length,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
