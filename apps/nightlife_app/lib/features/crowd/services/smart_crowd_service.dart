import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/crowd_decay.dart';

class SmartCrowdSnapshot {
  final String level;
  final int score;
  final String reason;

  const SmartCrowdSnapshot({
    required this.level,
    required this.score,
    required this.reason,
  });
}

class SmartCrowdService {
  SmartCrowdService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Stream<SmartCrowdSnapshot> venueCrowdStream({
    required String venueId,
    required String manualLevel,
    dynamic updatedAt,
  }) async* {
    yield await calculateVenueCrowd(
      venueId: venueId,
      manualLevel: manualLevel,
      updatedAt: updatedAt,
    );

    yield* Stream.periodic(const Duration(minutes: 2)).asyncMap((_) {
      return calculateVenueCrowd(
        venueId: venueId,
        manualLevel: manualLevel,
        updatedAt: updatedAt,
      );
    });
  }

  static Future<SmartCrowdSnapshot> calculateVenueCrowd({
    required String venueId,
    required String manualLevel,
    dynamic updatedAt,
  }) async {
    final decayedManual = CrowdDecay.displayLevel(
      level: manualLevel.isEmpty ? 'quiet' : manualLevel,
      updatedAt: updatedAt,
    );

    var score = CrowdDecay.scoreForLevel(decayedManual);
    final reasons = <String>[];

    if (decayedManual != manualLevel.toLowerCase().trim()) {
      reasons.add('manual crowd auto-degraded');
    } else {
      reasons.add('manual crowd');
    }

    final now = DateTime.now();
    final activeEvent = await _hasActiveEvent(venueId, now);
    if (activeEvent && score < 4) {
      score = 4;
      reasons.add('live/upcoming event boost');
    }

    final recentCheckIns = await _recentCount('checkins', venueId, now.subtract(const Duration(hours: 2)));
    if (recentCheckIns >= 30) {
      score = 5;
      reasons.add('$recentCheckIns recent check-ins');
    } else if (recentCheckIns >= 15 && score < 4) {
      score = 4;
      reasons.add('$recentCheckIns recent check-ins');
    } else if (recentCheckIns >= 6 && score < 3) {
      score = 3;
      reasons.add('$recentCheckIns recent check-ins');
    }

    final recentVenueViews = await _recentAnalyticsCount(venueId, 'venue_view', now.subtract(const Duration(hours: 2)));
    if (recentVenueViews >= 50 && score < 4) {
      score = 4;
      reasons.add('high live interest');
    } else if (recentVenueViews >= 20 && score < 3) {
      score = 3;
      reasons.add('steady live interest');
    }

    return SmartCrowdSnapshot(
      level: CrowdDecay.levelForScore(score),
      score: score,
      reason: reasons.take(3).join(' • '),
    );
  }

  static Future<bool> _hasActiveEvent(String venueId, DateTime now) async {
    final start = Timestamp.fromDate(now.subtract(const Duration(hours: 1)));
    final end = Timestamp.fromDate(now.add(const Duration(hours: 2)));
    final snap = await _db
        .collection('events')
        .where('venueId', isEqualTo: venueId)
        .where('isDeleted', isEqualTo: false)
        .where('dateTime', isGreaterThanOrEqualTo: start)
        .where('dateTime', isLessThanOrEqualTo: end)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  static Future<int> _recentCount(String collection, String venueId, DateTime since) async {
    try {
      final snap = await _db
          .collection(collection)
          .where('venueId', isEqualTo: venueId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
          .count()
          .get();
      return snap.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<int> _recentAnalyticsCount(String venueId, String type, DateTime since) async {
    try {
      final snap = await _db
          .collection('analytics')
          .where('venueId', isEqualTo: venueId)
          .where('type', isEqualTo: type)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
          .count()
          .get();
      return snap.count ?? 0;
    } catch (_) {
      return 0;
    }
  }
}
