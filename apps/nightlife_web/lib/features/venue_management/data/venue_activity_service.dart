import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/firebase/vexda_firebase.dart';
import '../models/venue_dashboard_activity.dart';

/// Loads recent venue activity from analytics and content collections.
abstract class VenueActivitySource {
  Future<List<VenueDashboardActivity>> loadRecentActivity({
    required String venueId,
    int limit = 5,
  });
}

class VenueActivityService implements VenueActivitySource {
  VenueActivityService({FirebaseFirestore? firestore})
      : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

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

    final items = <_ActivityEntry>[];

    items.addAll(await _loadAnalyticsActivity(trimmedId));
    items.addAll(await _loadContentActivity(trimmedId));

    items.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    return items.take(limit).map((entry) => entry.activity).toList();
  }

  Future<List<_ActivityEntry>> _loadAnalyticsActivity(String venueId) async {
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
          .whereType<_ActivityEntry>()
          .toList();
    } on FirebaseException {
      return const [];
    }
  }

  _ActivityEntry? _mapAnalyticsDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final type = data['type']?.toString() ?? '';
    final createdAt = data['createdAt'];
    if (createdAt is! Timestamp) return null;

    final payload = data['data'];
    final payloadMap = payload is Map ? Map<String, dynamic>.from(payload) : null;

    final mapped = switch (type) {
      'drink_view' => (
          'Drink viewed: ${payloadMap?['drinkName'] ?? 'Menu item'}',
          Icons.local_bar_outlined,
        ),
      'deal_view' => (
          'Deal viewed: ${payloadMap?['dealTitle'] ?? 'Promotion'}',
          Icons.local_offer_outlined,
        ),
      'event_view' => (
          'Event viewed: ${payloadMap?['eventTitle'] ?? 'Event'}',
          Icons.event_outlined,
        ),
      'favourite_tap' => ('Venue saved by a customer', Icons.bookmark_outline_rounded),
      'crowd_update' => ('Crowd level updated', Icons.groups_outlined),
      _ => null,
    };

    if (mapped == null) return null;

    return _ActivityEntry(
      occurredAt: createdAt.toDate(),
      activity: VenueDashboardActivity(
        title: mapped.$1,
        timestampLabel: _relativeTimeLabel(createdAt.toDate()),
        icon: mapped.$2,
      ),
    );
  }

  Future<List<_ActivityEntry>> _loadContentActivity(String venueId) async {
    final db = _db;
    if (db == null) return const [];

    final entries = <_ActivityEntry>[];

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
          _ActivityEntry(
            occurredAt: createdAt.toDate(),
            activity: VenueDashboardActivity(
              title: 'Event added: $title',
              timestampLabel: _relativeTimeLabel(createdAt.toDate()),
              icon: Icons.event_outlined,
            ),
          ),
        );
      }
    } on FirebaseException {
      // Content activity is optional when analytics/content reads fail.
    }

    return entries;
  }

  static String _relativeTimeLabel(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _ActivityEntry {
  const _ActivityEntry({
    required this.occurredAt,
    required this.activity,
  });

  final DateTime occurredAt;
  final VenueDashboardActivity activity;
}
