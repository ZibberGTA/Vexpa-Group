import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/vexda_firebase.dart';
import '../../venue_management/data/event_write_payload.dart';
import '../../venue_management/models/bulk_event_patch.dart';
import 'models/event_model.dart';
import 'public_venue_content_filters.dart';

/// Loads and writes events for a venue from Firestore.
class VenueEventsRepository {
  VenueEventsRepository({FirebaseFirestore? firestore})
      : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  FirebaseFirestore? _resolveFirestore() {
    if (_firestoreOverride != null) return _firestoreOverride;
    if (!VexdaFirebase.isReady) return null;
    return FirebaseFirestore.instance;
  }

  Stream<List<EventModel>> watchEvents(String venueId) async* {
    final firestore = _resolveFirestore();
    if (firestore == null) {
      yield const [];
      return;
    }

    yield* firestore
        .collection('events')
        .where('venueId', isEqualTo: venueId)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      final events = snapshot.docs
          .map(EventModel.fromDoc)
          .where((event) => isPublicVisibleEvent(event, now: now))
          .toList();
      events.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
      return events;
    });
  }

  Stream<List<EventModel>> watchManagementEvents(String venueId) async* {
    final firestore = _resolveFirestore();
    if (firestore == null) {
      yield const [];
      return;
    }

    yield* firestore
        .collection('events')
        .where('venueId', isEqualTo: venueId)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final events = snapshot.docs.map(EventModel.fromDoc).toList()
        ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
      return events;
    });
  }

  Future<void> patchEvent({
    required String eventId,
    required BulkEventPatch patch,
    required String updatedBy,
  }) async {
    if (patch.isEmpty) return;

    final firestore = _resolveFirestore();
    if (firestore == null) {
      throw StateError('Firestore is not available.');
    }

    final payload = EventWritePayload.buildPatch(
      updatedBy: updatedBy,
      title: patch.title,
      startDateTime: patch.startDateTime,
      endDateTime: patch.endDateTime,
      isActive: patch.isActive,
      featured: patch.featured,
    );

    try {
      await firestore.collection('events').doc(eventId).update(payload);
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint('[VenueEventsRepository] patch event failed (${error.code})');
      }
      rethrow;
    }
  }

  Future<String> addEvent({
    required String venueId,
    required String venueName,
    required String title,
    required String description,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required bool isActive,
    required bool featured,
    required String createdBy,
    String category = 'General',
    String imageUrl = '',
  }) async {
    final firestore = _resolveFirestore();
    if (firestore == null) {
      throw StateError('Firestore is not available.');
    }

    final docRef = firestore.collection('events').doc();
    final payload = EventWritePayload.build(
      venueId: venueId,
      venueName: venueName,
      title: title,
      description: description,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      isActive: isActive,
      featured: featured,
      createdBy: createdBy,
      category: category,
      imageUrl: imageUrl,
    );

    try {
      await docRef.set(payload);
      return docRef.id;
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint('[VenueEventsRepository] add event failed (${error.code})');
      }
      rethrow;
    }
  }

  Future<String> duplicateEvent({
    required EventModel source,
    required String venueName,
    required String createdBy,
  }) async {
    final trimmedTitle = source.title.trim();
    final copyTitle =
        trimmedTitle.endsWith(' Copy') ? trimmedTitle : '$trimmedTitle Copy';

    return addEvent(
      venueId: source.venueId,
      venueName: venueName,
      title: copyTitle,
      description: source.description,
      startDateTime: source.startDateTime,
      endDateTime: source.endDateTime,
      isActive: false,
      featured: false,
      createdBy: createdBy,
      category: source.category,
      imageUrl: source.imageUrl,
    );
  }

  Future<void> deleteEvent({
    required String eventId,
    required String deletedBy,
  }) async {
    final firestore = _resolveFirestore();
    if (firestore == null) {
      throw StateError('Firestore is not available.');
    }

    final payload = <String, dynamic>{
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'deletedBy': deletedBy,
    };

    try {
      await firestore.collection('events').doc(eventId).update(payload);
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint('[VenueEventsRepository] delete event failed (${error.code})');
      }
      rethrow;
    }
  }

  Future<void> bulkDeleteEvents({
    required List<String> eventIds,
    required String deletedBy,
  }) async {
    for (final eventId in eventIds) {
      await deleteEvent(eventId: eventId, deletedBy: deletedBy);
    }
  }

  static String relativeTimeLabel(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
