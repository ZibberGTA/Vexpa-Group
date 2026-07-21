import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:vex_core/vex_core.dart';
import 'package:vex_engines/experience/application/experience_content_orchestrator.dart';
import 'package:vex_engines/experience/application/venue_content_ordering_service.dart';
import 'package:vex_engines/experience/application/venue_featured_content_service.dart';
import 'package:vex_engines/experience/application/venue_presentation_support.dart';

import '../../../core/firebase/vexda_firebase.dart';
import '../../../core/vexcore/vex_venue_event_mapper.dart';
import '../../../core/vexcore/web_vexcore.dart';
import '../../venue_management/data/event_write_payload.dart';
import '../../venue_management/data/venue_management_activity_action_inference.dart';
import '../../venue_management/data/venue_management_activity_recording.dart';
import '../../venue_management/data/venue_management_activity_service.dart';
import '../../venue_management/models/bulk_event_patch.dart';
import '../../venue_management/models/venue_management_activity_types.dart';
import 'models/event_model.dart';

/// Loads and writes events for a venue from Firestore.
class VenueEventsRepository {
  VenueEventsRepository({
    FirebaseFirestore? firestore,
    VenueEventDataService? venueEventDataService,
    ExperienceContentOrchestrator? contentOrchestrator,
    VenueManagementActivityService? activityService,
  }) : _firestoreOverride = firestore,
       _venueEventDataService =
           venueEventDataService ?? WebVexCore.venueEventDataService,
       _contentOrchestrator = contentOrchestrator ?? _defaultOrchestrator,
       _activityService =
           activityService ?? WebVexCore.venueManagementActivityService;

  static const _defaultOrchestrator = ExperienceContentOrchestrator();
  static const _ordering = VenueContentOrderingService();
  static const _featured = VenueFeaturedContentService();

  final FirebaseFirestore? _firestoreOverride;
  final VenueEventDataService _venueEventDataService;
  final ExperienceContentOrchestrator _contentOrchestrator;
  final VenueManagementActivityService _activityService;

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
    return _ordering.sortEventsByStart(
      events: _contentOrchestrator.filterPublicVisibleEvents(
        mapped,
        isDeleted: (event) => event.isDeleted,
        isActive: (event) => event.isActive,
        startDateTime: (event) => event.startDateTime,
        endDateTime: (event) => event.endDateTime,
        now: now,
      ),
      startDateTime: (event) => event.startDateTime,
    );
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
          final events = _ordering.sortEventsByStart(
            events: snapshot.docs.map(EventModel.fromDoc).toList(),
            startDateTime: (event) => event.startDateTime,
          );
          return events;
        });
  }

  /// One-time fetch of published events overlapping a dashboard schedule window.
  Future<List<EventModel>> fetchScheduleEvents({
    required String venueId,
    required DateTime windowStart,
    required DateTime windowEndExclusive,
  }) async {
    final trimmedId = venueId.trim();
    if (trimmedId.isEmpty) return const [];

    final firestore = _resolveFirestore();
    if (firestore == null) return const [];

    try {
      final snapshot = await firestore
          .collection('events')
          .where('venueId', isEqualTo: trimmedId)
          .where('isDeleted', isEqualTo: false)
          .where('endDateTime', isGreaterThan: Timestamp.fromDate(windowStart))
          .get();

      final events = snapshot.docs
          .map(EventModel.fromDoc)
          .where(
            (event) =>
                event.isActive &&
                event.startDateTime.isBefore(windowEndExclusive),
          )
          .toList();

      return _ordering.sortEventsByStart(
        events: events,
        startDateTime: (event) => event.startDateTime,
      );
    } on FirebaseException catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[VenueEventsRepository] schedule events failed '
          '(${error.code}): ${error.message}',
        );
        debugPrint('[VenueEventsRepository] stackTrace:\n$stackTrace');
      }
      return const [];
    }
  }

  Future<void> patchEvent({
    required String eventId,
    required String venueId,
    required String eventTitle,
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
      final resolvedTitle = patch.title ?? eventTitle;
      await _recordEventActivity(
        venueId: venueId,
        eventId: eventId,
        eventTitle: resolvedTitle,
        actorUid: updatedBy,
        actionType: VenueManagementActivityActionInference.eventPatchActionType(
          patch,
        ),
        description: patch.isActive != null
            ? (patch.isActive! ? 'Event published' : 'Event unpublished')
            : 'Event updated',
      );
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[VenueEventsRepository] patch event failed (${error.code})',
        );
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
      await _recordEventActivity(
        venueId: venueId,
        eventId: docRef.id,
        eventTitle: title,
        actorUid: createdBy,
        actionType: VenueManagementActivityActionTypes.created,
        description: 'Event created',
      );
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
    final copyTitle = _featured.duplicateCopyTitle(source.title.trim());
    final defaults = _featured.duplicateEventDefaults();

    return addEvent(
      venueId: source.venueId,
      venueName: venueName,
      title: copyTitle,
      description: source.description,
      startDateTime: source.startDateTime,
      endDateTime: source.endDateTime,
      isActive: defaults.isActive,
      featured: defaults.featured,
      createdBy: createdBy,
      category: source.category,
      imageUrl: source.imageUrl,
    );
  }

  Future<void> deleteEvent({
    required String eventId,
    required String deletedBy,
    String? venueId,
    String? eventTitle,
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
      if (venueId != null &&
          venueId.trim().isNotEmpty &&
          eventTitle != null &&
          eventTitle.trim().isNotEmpty) {
        await _recordEventActivity(
          venueId: venueId,
          eventId: eventId,
          eventTitle: eventTitle,
          actorUid: deletedBy,
          actionType: VenueManagementActivityActionTypes.archived,
          description: 'Event archived',
        );
      }
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[VenueEventsRepository] delete event failed (${error.code})',
        );
      }
      rethrow;
    }
  }

  Future<void> bulkDeleteEvents({
    required List<EventModel> events,
    required String deletedBy,
  }) async {
    for (final event in events) {
      await deleteEvent(
        eventId: event.id,
        deletedBy: deletedBy,
        venueId: event.venueId,
        eventTitle: event.title,
      );
    }
  }

  static const _presentation = VenuePresentationSupport();

  static String relativeTimeLabel(DateTime date) =>
      _presentation.managementRelativeTimeLabel(date);

  Future<void> _recordEventActivity({
    required String venueId,
    required String eventId,
    required String eventTitle,
    required String actorUid,
    required String actionType,
    required String description,
  }) {
    return VenueManagementActivityRecording.recordEvent(
      service: _activityService,
      venueId: venueId,
      eventId: eventId,
      eventTitle: eventTitle,
      actorUid: actorUid,
      actionType: actionType,
      description: description,
    );
  }
}
