import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vex_engines/analytics/application/analytics_activity_aggregator.dart';
import 'package:vex_engines/analytics/domain/analytics_dashboard_models.dart';
import 'package:vex_engines/venue/application/venue_activity_interpreter.dart';
import 'package:vex_engines/venue/domain/venue_dashboard_models.dart';

import '../../../core/firebase/vexda_firebase.dart';
import '../models/venue_dashboard_activity.dart';
import '../services/venue_dashboard_engine_mapper.dart';

/// Loads recent venue activity from analytics and content collections.
abstract class VenueActivitySource {
  Future<List<VenueDashboardActivity>> loadRecentActivity({
    required String venueId,
    int limit = 5,
  });
}

class VenueActivityService implements VenueActivitySource {
  VenueActivityService({
    FirebaseFirestore? firestore,
    AnalyticsActivityAggregator? activityAggregator,
    AnalyticsRelativeTimeFormatter? relativeTimeFormatter,
    VenueActivityInterpreter? activityInterpreter,
  })  : _firestoreOverride = firestore,
        _activityAggregator = activityAggregator ?? const AnalyticsActivityAggregator(),
        _relativeTimeFormatter =
            relativeTimeFormatter ?? const AnalyticsRelativeTimeFormatter(),
        _activityInterpreter = activityInterpreter ?? const VenueActivityInterpreter();

  final FirebaseFirestore? _firestoreOverride;
  final AnalyticsActivityAggregator _activityAggregator;
  final AnalyticsRelativeTimeFormatter _relativeTimeFormatter;
  final VenueActivityInterpreter _activityInterpreter;

  FirebaseFirestore? get _db {
    if (_firestoreOverride != null) return _firestoreOverride;
    if (!VexdaFirebase.isReady) return null;
    return FirebaseFirestore.instance;
  }

  @override
  Future<List<VenueDashboardActivity>> loadRecentActivity({
    required String venueId,
    int limit = 5,
  }) async {
    final trimmedId = venueId.trim();
    if (trimmedId.isEmpty) return const [];

    final entries = <AnalyticsActivityEntry>[];
    entries.addAll(await _loadAnalyticsActivity(trimmedId));
    entries.addAll(await _loadContentActivity(trimmedId));

    final limited = _activityAggregator.sortAndLimit(entries, limit: limit);
    final interpreted = <VenueActivityItem>[];

    for (final entry in limited) {
      final sourceEntry = _toSourceEntry(entry);
      final item = _activityInterpreter.interpret(sourceEntry);
      if (item != null) interpreted.add(item);
    }

    return VenueDashboardEngineMapper.activityFromEngine(interpreted);
  }

  VenueActivitySourceEntry _toSourceEntry(AnalyticsActivityEntry entry) {
    return VenueActivitySourceEntry(
      occurredAt: entry.occurredAt,
      source: entry.source,
      timestampLabel: _relativeTimeFormatter.format(entry.occurredAt),
      eventType: entry.eventType,
      payload: entry.payload,
      contentTitle: entry.contentTitle,
    );
  }

  Future<List<AnalyticsActivityEntry>> _loadAnalyticsActivity(String venueId) async {
    final db = _db;
    if (db == null) return const [];

    try {
      final snapshot = await db
          .collection('analytics')
          .where('venueId', isEqualTo: venueId)
          .orderBy('createdAt', descending: true)
          .limit(12)
          .get();

      return snapshot.docs
          .map((doc) => _mapAnalyticsDoc(doc))
          .whereType<AnalyticsActivityEntry>()
          .toList();
    } on FirebaseException {
      return const [];
    }
  }

  AnalyticsActivityEntry? _mapAnalyticsDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final type = data['type']?.toString() ?? '';
    final createdAt = data['createdAt'];
    if (createdAt is! Timestamp) return null;

    final payload = data['data'];
    final payloadMap = payload is Map ? Map<String, dynamic>.from(payload) : null;

    final supported = switch (type) {
      'drink_view' ||
      'deal_view' ||
      'event_view' ||
      'favourite_tap' ||
      'crowd_update' => true,
      _ => false,
    };
    if (!supported) return null;

    return AnalyticsActivityEntry(
      occurredAt: createdAt.toDate(),
      source: 'analytics',
      eventType: type,
      payload: {
        if (payloadMap != null) ...payloadMap,
      },
    );
  }

  Future<List<AnalyticsActivityEntry>> _loadContentActivity(String venueId) async {
    final db = _db;
    if (db == null) return const [];

    final entries = <AnalyticsActivityEntry>[];

    try {
      final events = await db
          .collection('events')
          .where('venueId', isEqualTo: venueId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(3)
          .get();

      for (final doc in events.docs) {
        final data = doc.data();
        final createdAt = data['createdAt'];
        if (createdAt is! Timestamp) continue;
        final title = data['title']?.toString().trim();
        if (title == null || title.isEmpty) continue;

        entries.add(
          AnalyticsActivityEntry(
            occurredAt: createdAt.toDate(),
            source: 'content_event',
            contentTitle: title,
          ),
        );
      }
    } on FirebaseException {
      // Content activity is optional when analytics/content reads fail.
    }

    return entries;
  }
}
