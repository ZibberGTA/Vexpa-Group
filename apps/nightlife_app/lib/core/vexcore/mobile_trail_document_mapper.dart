import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vex_core/trails/trail_paths.dart';
import 'package:vex_core/trails/trail_snapshots.dart';

/// Maps Firestore trail documents to VexCore snapshots and write payloads.
final class MobileTrailDocumentMapper {
  MobileTrailDocumentMapper._();

  static TrailSnapshot? parseTrailDocument(
    String trailId,
    Map<String, dynamic>? data,
  ) {
    if (data == null) return null;

    final stopsRaw = data['stops'];
    final stops = stopsRaw is List
        ? stopsRaw
              .whereType<Map>()
              .map(
                (item) => parseStop(Map<String, dynamic>.from(item)),
              )
              .whereType<TrailStopSnapshot>()
              .toList()
        : <TrailStopSnapshot>[];
    stops.sort((a, b) => a.order.compareTo(b.order));

    final now = DateTime.now();
    final availabilityStart =
        readTimestamp(data['availabilityStart']) ??
        readTimestamp(data['startTime']) ??
        now;
    final availabilityEnd =
        readTimestamp(data['availabilityEnd']) ??
        readTimestamp(data['endTime']) ??
        DateTime(now.year, now.month, now.day, 23, 59, 59);
    final estimatedDurationMinutes = (data['estimatedDurationMinutes'] as num?)
        ?.toInt();

    return TrailSnapshot(
      trailId: trailId,
      name: (data['name'] ?? data['title'] ?? "Tonight's Trail").toString(),
      title: (data['title'] ?? data['name'] ?? "Tonight's Trail").toString(),
      description:
          (data['description'] ??
                  data['subtitle'] ??
                  'Generated from live DrinkSpot activity')
              .toString(),
      subtitle:
          (data['subtitle'] ?? data['description'] ?? '').toString(),
      bannerImageUrl: (data['bannerImageUrl'] ?? '').toString(),
      status: TrailPersistenceCodec.parseStatus(data['status']?.toString()),
      published: data['published'] == true,
      area: (data['area'] ?? '').toString(),
      availabilityStart: availabilityStart,
      availabilityEnd: availabilityEnd,
      startTime: readTimestamp(data['startTime']) ?? availabilityStart,
      endTime: readTimestamp(data['endTime']) ?? availabilityEnd,
      estimatedDurationMinutes:
          estimatedDurationMinutes ??
          availabilityEnd.difference(availabilityStart).inMinutes,
      estimatedWalkingDistance:
          (data['estimatedWalkingDistance'] as num?)?.toInt() ?? 0,
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0,
      venueCount: (data['venueCount'] as num?)?.toInt() ?? stops.length,
      trailType: TrailPersistenceCodec.parseType(data['trailType']?.toString()),
      generatedAt: readTimestamp(data['generatedAt']) ?? now,
      stops: stops,
      createdAt: readTimestamp(data['createdAt']),
      updatedAt: readTimestamp(data['updatedAt']),
      publishedAt: readTimestamp(data['publishedAt']),
      unpublishedAt: readTimestamp(data['unpublishedAt']),
      archivedAt: readTimestamp(data['archivedAt']),
      disabledAt: readTimestamp(data['disabledAt']),
      searchTerms: readStringList(data['searchTerms']),
      participationSettings: parseParticipationSettings(data),
    );
  }

  static TrailParticipationSettingsSnapshot parseParticipationSettings(
    Map<String, dynamic> data,
  ) {
    final nested = data['participationSettings'];
    final source = nested is Map ? Map<String, dynamic>.from(nested) : data;

    return TrailParticipationSettingsSnapshot(
      acceptsVenueApplications:
          source['acceptsVenueApplications'] == true ||
          data['acceptsVenueApplications'] == true,
      participationApplicationOpensAt: readTimestamp(
        source['participationApplicationOpensAt'] ??
            data['participationApplicationOpensAt'],
      ),
      participationApplicationClosesAt: readTimestamp(
        source['participationApplicationClosesAt'] ??
            data['participationApplicationClosesAt'],
      ),
      maximumStops: (source['maximumStops'] ?? data['maximumStops'] as num?)
          ?.toInt(),
      venueSelectableStopPosition:
          source['venueSelectableStopPosition'] != false &&
          data['venueSelectableStopPosition'] != false,
      participationInstructions:
          (source['participationInstructions'] ??
                  data['participationInstructions'] ??
                  '')
              .toString(),
    );
  }

  static TrailStopSnapshot? parseStop(Map<String, dynamic> map) {
    return TrailStopSnapshot(
      venueId: (map['venueId'] ?? '').toString(),
      venueName: (map['venueName'] ?? '').toString(),
      address: (map['address'] ?? '').toString(),
      bannerImageUrl: (map['bannerImageUrl'] ?? '').toString(),
      logoUrl: (map['logoUrl'] ?? '').toString(),
      order: (map['order'] as num?)?.toInt() ?? 0,
      score: (map['score'] as num?)?.toInt() ?? 0,
      arriveAt: readTimestamp(map['arriveAt']) ?? DateTime.now(),
      leaveAt: readTimestamp(map['leaveAt']) ?? DateTime.now(),
      discountLabel: (map['discountLabel'] ?? '').toString(),
    );
  }

  static TrailProgressSnapshot? parseProgressDocument(
    Map<String, dynamic>? data,
  ) {
    if (data == null) return null;

    final rawCheckedInStops = data['checkedInStops'];
    final checkedInStops = rawCheckedInStops is List
        ? rawCheckedInStops
              .map((item) => (item as num?)?.toInt())
              .whereType<int>()
              .toSet()
        : <int>{};

    final stopStates = <int, TrailStopProgressStateSnapshot>{};
    final rawStopStates = data['stopStates'];
    if (rawStopStates is Map) {
      rawStopStates.forEach((key, value) {
        final order = int.tryParse(key.toString());
        if (order == null) return;
        stopStates[order] = TrailPersistenceCodec.parseStopProgressState(
          value?.toString(),
        );
      });
    }

    return TrailProgressSnapshot(
      trailId: (data['trailId'] ?? '').toString(),
      started: data['started'] == true,
      completed: data['completed'] == true,
      currentStop: (data['currentStop'] as num?)?.toInt() ?? 0,
      checkedInStops: checkedInStops,
      stopStates: stopStates,
      trailGeneratedAt: readTimestamp(data['trailGeneratedAt']),
      startedAt: readTimestamp(data['startedAt']),
      updatedAt: readTimestamp(data['updatedAt']),
      completedAt: readTimestamp(data['completedAt']),
      lastCheckedInVenueId: data['lastCheckedInVenueId']?.toString(),
      lastCheckedInStopOrder: (data['lastCheckedInStopOrder'] as num?)?.toInt(),
    );
  }

  static TrailActiveStateSnapshot? parseActiveState(Map<String, dynamic>? data) {
    if (data == null) return null;
    return TrailActiveStateSnapshot(
      activeTrailId: (data['activeTrailId'] ?? TrailPaths.activeTrailDocumentId)
          .toString(),
      updatedAt: readTimestamp(data['updatedAt']),
    );
  }

  static TrailActivitySnapshot? parseActivityDocument(
    String activityId,
    Map<String, dynamic>? data,
  ) {
    if (data == null) return null;
    return TrailActivitySnapshot(
      activityId: activityId,
      trailId: (data['trailId'] ?? '').toString(),
      userId: data['userId']?.toString(),
      isAnonymous: data['isAnonymous'] == true,
      action: (data['action'] ?? '').toString(),
      createdAt: readTimestamp(data['createdAt']) ?? DateTime.now(),
      venueId: data['venueId']?.toString(),
      stopOrder: (data['stopOrder'] as num?)?.toInt(),
    );
  }

  static Map<String, Object?> stopStatesToFirestore(
    Map<int, TrailStopProgressStateSnapshot> stopStates,
  ) {
    return {
      for (final entry in stopStates.entries)
        entry.key.toString(): _stopStateValue(entry.value),
    };
  }

  static Map<String, Object?> stopStatesFromDomainKeys(
    Map<int, String> stopStateKeys,
  ) {
    return {
      for (final entry in stopStateKeys.entries) entry.key.toString(): entry.value,
    };
  }

  static List<Map<String, Object?>> stopsToFirestore(
    List<TrailStopSnapshot> stops,
  ) {
    return stops
        .map(
          (stop) => {
            'venueId': stop.venueId,
            'venueName': stop.venueName,
            'address': stop.address,
            'bannerImageUrl': stop.bannerImageUrl,
            'logoUrl': stop.logoUrl,
            'order': stop.order,
            'score': stop.score,
            'arriveAt': Timestamp.fromDate(stop.arriveAt),
            'leaveAt': Timestamp.fromDate(stop.leaveAt),
            'discountLabel': stop.discountLabel.trim(),
          },
        )
        .toList();
  }

  static Map<String, Object?> progressSnapshotToFirestore(
    TrailProgressSnapshot progress, {
    bool includeCheckedInArrayUnion = false,
    int? checkedInStopOrderToUnion,
  }) {
    final map = <String, Object?>{
      'trailId': progress.trailId,
      'trailGeneratedAt': progress.trailGeneratedAt == null
          ? null
          : Timestamp.fromDate(progress.trailGeneratedAt!),
      'started': progress.started,
      'completed': progress.completed,
      'currentStop': progress.currentStop,
      'stopStates': stopStatesToFirestore(progress.stopStates),
      if (progress.startedAt != null)
        'startedAt': Timestamp.fromDate(progress.startedAt!),
      if (progress.updatedAt != null)
        'updatedAt': Timestamp.fromDate(progress.updatedAt!),
      if (progress.completedAt != null)
        'completedAt': Timestamp.fromDate(progress.completedAt!),
      if (progress.lastCheckedInVenueId != null)
        'lastCheckedInVenueId': progress.lastCheckedInVenueId,
      if (progress.lastCheckedInStopOrder != null)
        'lastCheckedInStopOrder': progress.lastCheckedInStopOrder,
    };

    if (includeCheckedInArrayUnion && checkedInStopOrderToUnion != null) {
      map['checkedInStops'] = FieldValue.arrayUnion([checkedInStopOrderToUnion]);
    } else {
      map['checkedInStops'] = progress.checkedInStops.toList();
    }

    return map;
  }

  static String _stopStateValue(TrailStopProgressStateSnapshot snapshot) {
    return switch (snapshot) {
      KnownTrailStopProgressStateSnapshot(:final value) => value.firestoreValue,
      UnknownTrailStopProgressStateSnapshot(:final rawValue) => rawValue,
    };
  }

  static DateTime? readTimestamp(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static List<String> readStringList(Object? value) {
    if (value is! Iterable) return const [];
    return value.map((item) => item.toString()).toList();
  }
}
