import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:vex_core/vex_core.dart';
import 'package:vex_engines/experience/application/experience_content_orchestrator.dart';

import '../../../core/firebase/vexda_firebase.dart';
import '../../../core/vexcore/vex_venue_event_mapper.dart';
import '../../../core/vexcore/web_vexcore.dart';
import '../../venue_management/data/event_write_payload.dart';
import '../../venue_management/models/bulk_event_patch.dart';
import 'models/event_model.dart';

/// Loads and writes events for a venue from Firestore.
class VenueEventsRepository {
  VenueEventsRepository({
    FirebaseFirestore? firestore,
    VenueEventDataService? venueEventDataService,
    ExperienceContentOrchestrator? contentOrchestrator,
  }) : _firestoreOverride = firestore,
       _venueEventDataService =
           venueEventDataService ?? WebVexCore.venueEventDataService,
       _contentOrchestrator = contentOrchestrator ?? _defaultOrchestrator;

  static const _defaultOrchestrator = ExperienceContentOrchestrator();

  final FirebaseFirestore? _firestoreOverride;
  final VenueEventDataService _venueEventDataService;
  final ExperienceContentOrchestrator _contentOrchestrator;

  FirebaseFirestore? _resolveFirestore() {
    if (_firestoreOverride != null) return _firestoreOverride;
    if (!VexdaFirebase.isReady) return null;
    return FirebaseFirestore.instance;
  }

  Stream<List<EventModel>> watchEvents(String venueId) {
    final trimmedId = venueId.trim();
    if (trimmedId.isEmpty) {
      return Stream.value(const []);
    }

    return _venueEventDataService.watchPublicEvents(trimmedId).map((result) {
      return switch (result) {
        DataSuccess(:final value) => _visibleEvents(value),
        DataFailure(:final error) => throw error,
      };
    });
  }

  List<EventModel> _visibleEvents(List<VenueEvent> events, {DateTime? now}) {
    final mapped = events.map(eventModelFromVexVenueEvent).toList();
    return _contentOrchestrator.filterPublicVisibleEvents(
      mapped,
      isDeleted: (event) => event.isDeleted,
      isActive: (event) => event.isActive,
      startDateTime: (event) => event.startDateTime,
      endDateTime: (event) => event.endDateTime,
      now: now,
    )..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
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
