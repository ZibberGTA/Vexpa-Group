import 'package:cloud_firestore/cloud_firestore.dart';

enum TrailStatus { draft, published, disabled, archived }

enum TrailType { curated, generated }

extension TrailStatusX on TrailStatus {
  String get key {
    switch (this) {
      case TrailStatus.draft:
        return 'draft';
      case TrailStatus.published:
        return 'published';
      case TrailStatus.disabled:
        return 'disabled';
      case TrailStatus.archived:
        return 'archived';
    }
  }

  String get label {
    switch (this) {
      case TrailStatus.draft:
        return 'Draft';
      case TrailStatus.published:
        return 'Published';
      case TrailStatus.disabled:
        return 'Disabled';
      case TrailStatus.archived:
        return 'Archived';
    }
  }

  static TrailStatus fromValue(dynamic value) {
    switch (value?.toString().toLowerCase()) {
      case 'published':
        return TrailStatus.published;
      case 'disabled':
        return TrailStatus.disabled;
      case 'archived':
        return TrailStatus.archived;
      case 'draft':
      default:
        return TrailStatus.draft;
    }
  }
}

extension TrailTypeX on TrailType {
  String get key {
    switch (this) {
      case TrailType.curated:
        return 'curated';
      case TrailType.generated:
        return 'generated';
    }
  }

  String get label {
    switch (this) {
      case TrailType.curated:
        return 'Curated';
      case TrailType.generated:
        return 'Generated';
    }
  }

  static TrailType fromValue(dynamic value) {
    switch (value?.toString().toLowerCase()) {
      case 'generated':
        return TrailType.generated;
      case 'curated':
      default:
        return TrailType.curated;
    }
  }
}

class TrailStopModel {
  final String venueId;
  final String venueName;
  final String address;
  final String bannerImageUrl;
  final String logoUrl;
  final int order;
  final int score;
  final DateTime arriveAt;
  final DateTime leaveAt;
  final String discountLabel;

  const TrailStopModel({
    required this.venueId,
    required this.venueName,
    required this.address,
    required this.bannerImageUrl,
    required this.logoUrl,
    required this.order,
    required this.score,
    required this.arriveAt,
    required this.leaveAt,
    this.discountLabel = '',
  });

  factory TrailStopModel.fromMap(Map<String, dynamic> map) {
    return TrailStopModel(
      venueId: (map['venueId'] ?? '').toString(),
      venueName: (map['venueName'] ?? '').toString(),
      address: (map['address'] ?? '').toString(),
      bannerImageUrl: (map['bannerImageUrl'] ?? '').toString(),
      logoUrl: (map['logoUrl'] ?? '').toString(),
      order: (map['order'] as num?)?.toInt() ?? 0,
      score: (map['score'] as num?)?.toInt() ?? 0,
      arriveAt: (map['arriveAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      leaveAt: (map['leaveAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      discountLabel: (map['discountLabel'] ?? '').toString(),
    );
  }

  TrailStopModel copyWith({
    String? venueId,
    String? venueName,
    String? address,
    String? bannerImageUrl,
    String? logoUrl,
    int? order,
    int? score,
    DateTime? arriveAt,
    DateTime? leaveAt,
    String? discountLabel,
  }) {
    return TrailStopModel(
      venueId: venueId ?? this.venueId,
      venueName: venueName ?? this.venueName,
      address: address ?? this.address,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      order: order ?? this.order,
      score: score ?? this.score,
      arriveAt: arriveAt ?? this.arriveAt,
      leaveAt: leaveAt ?? this.leaveAt,
      discountLabel: discountLabel ?? this.discountLabel,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'venueId': venueId,
      'venueName': venueName,
      'address': address,
      'bannerImageUrl': bannerImageUrl,
      'logoUrl': logoUrl,
      'order': order,
      'score': score,
      'arriveAt': Timestamp.fromDate(arriveAt),
      'leaveAt': Timestamp.fromDate(leaveAt),
      'discountLabel': discountLabel.trim(),
    };
  }
}

class DrinkSpotTrailModel {
  final String id;
  final String name;
  final String description;
  final String bannerImageUrl;
  final TrailStatus status;
  final String area;
  final DateTime availabilityStart;
  final DateTime availabilityEnd;
  final Duration estimatedDuration;
  final int estimatedWalkingDistance;
  final double averageRating;
  final int venueCount;
  final TrailType trailType;
  final bool published;
  final DateTime generatedAt;
  final List<TrailStopModel> stops;

  DrinkSpotTrailModel({
    required this.id,
    required this.status,
    required this.generatedAt,
    required this.stops,
    String? name,
    String? title,
    String? description,
    String? subtitle,
    this.bannerImageUrl = '',
    this.area = '',
    DateTime? availabilityStart,
    DateTime? startTime,
    DateTime? availabilityEnd,
    DateTime? endTime,
    Duration? estimatedDuration,
    int? estimatedWalkingDistance,
    double? averageRating,
    int? venueCount,
    this.trailType = TrailType.curated,
    bool? published,
  }) : name = name ?? title ?? "Tonight's Trail",
       description =
           description ?? subtitle ?? 'Generated from live DrinkSpot activity',
       availabilityStart = availabilityStart ?? startTime ?? generatedAt,
       availabilityEnd = availabilityEnd ?? endTime ?? generatedAt,
       estimatedDuration =
           estimatedDuration ??
           ((availabilityEnd ?? endTime) != null &&
                   (availabilityStart ?? startTime) != null
               ? (availabilityEnd ?? endTime)!.difference(
                   (availabilityStart ?? startTime)!,
                 )
               : Duration.zero),
       estimatedWalkingDistance = estimatedWalkingDistance ?? 0,
       averageRating = averageRating ?? 0,
       venueCount = venueCount ?? stops.length,
       published = published ?? status == TrailStatus.published;

  factory DrinkSpotTrailModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final stopsRaw = data['stops'];
    final stops = stopsRaw is List
        ? stopsRaw
              .whereType<Map>()
              .map(
                (item) =>
                    TrailStopModel.fromMap(Map<String, dynamic>.from(item)),
              )
              .toList()
        : <TrailStopModel>[];
    stops.sort((a, b) => a.order.compareTo(b.order));
    final now = DateTime.now();
    final availabilityStart =
        (data['availabilityStart'] as Timestamp?)?.toDate() ??
        (data['startTime'] as Timestamp?)?.toDate() ??
        now;
    final availabilityEnd =
        (data['availabilityEnd'] as Timestamp?)?.toDate() ??
        (data['endTime'] as Timestamp?)?.toDate() ??
        DateTime(now.year, now.month, now.day, 23, 59, 59);
    final estimatedDurationMinutes = (data['estimatedDurationMinutes'] as num?)
        ?.toInt();

    return DrinkSpotTrailModel(
      id: doc.id,
      name: (data['name'] ?? data['title'] ?? "Tonight's Trail").toString(),
      description:
          (data['description'] ??
                  data['subtitle'] ??
                  'Generated from live DrinkSpot activity')
              .toString(),
      bannerImageUrl: (data['bannerImageUrl'] ?? '').toString(),
      status: TrailStatusX.fromValue(data['status']),
      area: (data['area'] ?? '').toString(),
      availabilityStart: availabilityStart,
      availabilityEnd: availabilityEnd,
      estimatedDuration: estimatedDurationMinutes == null
          ? availabilityEnd.difference(availabilityStart)
          : Duration(minutes: estimatedDurationMinutes),
      estimatedWalkingDistance:
          (data['estimatedWalkingDistance'] as num?)?.toInt() ?? 0,
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0,
      venueCount: (data['venueCount'] as num?)?.toInt() ?? stops.length,
      trailType: TrailTypeX.fromValue(data['trailType']),
      published: data['published'] == true,
      generatedAt:
          (data['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      stops: stops,
    );
  }

  String get title => name;

  String get subtitle => description;

  DateTime get startTime => availabilityStart;

  DateTime get endTime => availabilityEnd;

  bool get isActive => isVisible;

  bool get isVisible => visibilityRejectionReason() == null;

  /// Returns null when the trail should be shown publicly, otherwise why not.
  String? visibilityRejectionReason({DateTime? at}) {
    final publishedLike = status == TrailStatus.published || published;
    if (!publishedLike) {
      return 'not published (status=${status.key}, published=$published)';
    }

    final hasStops = stops.isNotEmpty || venueCount > 0;
    if (!hasStops) {
      return 'no stops (stops=${stops.length}, venueCount=$venueCount)';
    }

    if (availabilityEnd.isBefore(availabilityStart)) {
      return 'availabilityEnd before availabilityStart '
          '($availabilityStart -> $availabilityEnd)';
    }

    final now = at ?? DateTime.now();
    if (now.isBefore(availabilityStart)) {
      if (_isSameLocalDay(now, availabilityStart)) {
        return null;
      }
      return 'before availabilityStart on a different day '
          '(now=$now, start=$availabilityStart)';
    }

    if (now.isAfter(availabilityEnd)) {
      return 'availabilityEnd in the past (now=$now, end=$availabilityEnd)';
    }

    return null;
  }

  bool _isSameLocalDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'bannerImageUrl': bannerImageUrl.trim(),
      'status': status.key,
      'area': area.trim(),
      'availabilityStart': Timestamp.fromDate(availabilityStart),
      'availabilityEnd': Timestamp.fromDate(availabilityEnd),
      'estimatedDurationMinutes': estimatedDuration.inMinutes,
      'estimatedWalkingDistance': estimatedWalkingDistance,
      'averageRating': averageRating,
      'venueCount': venueCount,
      'trailType': trailType.key,
      'published': published,
      'generatedAt': Timestamp.fromDate(generatedAt),
      'title': title,
      'subtitle': subtitle,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'stops': stops.map((stop) => stop.toMap()).toList(),
    };
  }
}

enum TrailStopProgressState {
  upcoming,
  current,
  checkedIn,
  skipped,
  missed,
  completed,
}

extension TrailStopProgressStateX on TrailStopProgressState {
  String get key {
    switch (this) {
      case TrailStopProgressState.upcoming:
        return 'upcoming';
      case TrailStopProgressState.current:
        return 'current';
      case TrailStopProgressState.checkedIn:
        return 'checkedIn';
      case TrailStopProgressState.skipped:
        return 'skipped';
      case TrailStopProgressState.missed:
        return 'missed';
      case TrailStopProgressState.completed:
        return 'completed';
    }
  }

  String get label {
    switch (this) {
      case TrailStopProgressState.upcoming:
        return 'Upcoming';
      case TrailStopProgressState.current:
        return 'Current';
      case TrailStopProgressState.checkedIn:
        return 'Checked In';
      case TrailStopProgressState.skipped:
        return 'Skipped';
      case TrailStopProgressState.missed:
        return 'Missed';
      case TrailStopProgressState.completed:
        return 'Completed';
    }
  }

  bool get isTerminal {
    return this == TrailStopProgressState.checkedIn ||
        this == TrailStopProgressState.skipped ||
        this == TrailStopProgressState.missed ||
        this == TrailStopProgressState.completed;
  }

  static TrailStopProgressState fromKey(String value) {
    switch (value) {
      case 'checkedIn':
        return TrailStopProgressState.checkedIn;
      case 'skipped':
        return TrailStopProgressState.skipped;
      case 'missed':
        return TrailStopProgressState.missed;
      case 'completed':
        return TrailStopProgressState.completed;
      case 'current':
        return TrailStopProgressState.current;
      case 'upcoming':
      default:
        return TrailStopProgressState.upcoming;
    }
  }
}

class TrailProgressModel {
  final String trailId;
  final bool started;
  final bool completed;
  final int currentStop;
  final Set<int> checkedInStops;
  final Map<int, TrailStopProgressState> stopStates;
  final DateTime? trailGeneratedAt;

  const TrailProgressModel({
    required this.trailId,
    required this.started,
    required this.completed,
    required this.currentStop,
    required this.checkedInStops,
    this.stopStates = const <int, TrailStopProgressState>{},
    this.trailGeneratedAt,
  });

  factory TrailProgressModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final rawCheckedInStops = data['checkedInStops'];
    final checkedInStops = rawCheckedInStops is List
        ? rawCheckedInStops
              .map((item) => (item as num?)?.toInt())
              .whereType<int>()
              .toSet()
        : <int>{};
    final rawStopStates = data['stopStates'];
    final stopStates = <int, TrailStopProgressState>{};
    if (rawStopStates is Map) {
      rawStopStates.forEach((key, value) {
        final order = int.tryParse(key.toString());
        if (order == null) return;
        stopStates[order] = TrailStopProgressStateX.fromKey(value.toString());
      });
    }
    for (final order in checkedInStops) {
      stopStates.putIfAbsent(order, () => TrailStopProgressState.checkedIn);
    }

    return TrailProgressModel(
      trailId: (data['trailId'] ?? '').toString(),
      started: data['started'] == true,
      completed: data['completed'] == true,
      currentStop: (data['currentStop'] as num?)?.toInt() ?? 0,
      checkedInStops: checkedInStops,
      stopStates: stopStates,
      trailGeneratedAt: (data['trailGeneratedAt'] as Timestamp?)?.toDate(),
    );
  }

  bool belongsTo(DrinkSpotTrailModel trail) {
    if (trailId != trail.id) return false;
    if (trailGeneratedAt == null) return true;
    return trailGeneratedAt!.millisecondsSinceEpoch ==
        trail.generatedAt.millisecondsSinceEpoch;
  }

  TrailStopProgressState stateForStop({
    required TrailStopModel stop,
    required int index,
    required bool trailCompleted,
  }) {
    final explicitState = stopStates[stop.order];
    if (explicitState != null) return explicitState;
    if (checkedInStops.contains(stop.order)) {
      return TrailStopProgressState.checkedIn;
    }
    if (trailCompleted || index < currentStop) {
      return TrailStopProgressState.completed;
    }
    if (started && index == currentStop) return TrailStopProgressState.current;
    return TrailStopProgressState.upcoming;
  }
}
