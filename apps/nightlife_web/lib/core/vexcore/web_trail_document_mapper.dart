import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vex_core/trails/trail_snapshots.dart';

/// Maps Firestore trail documents to VexCore snapshots for the web app.
abstract final class WebTrailDocumentMapper {
  static TrailSnapshot? parseTrailDocument(
    String trailId,
    Map<String, dynamic>? data,
  ) {
    if (data == null) return null;

    final stopsRaw = data['stops'];
    final stops = stopsRaw is List
        ? stopsRaw
              .whereType<Map>()
              .map((item) => parseStop(Map<String, dynamic>.from(item)))
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
      subtitle: (data['subtitle'] ?? data['description'] ?? '').toString(),
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
