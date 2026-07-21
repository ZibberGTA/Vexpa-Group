/// Immutable Trail infrastructure snapshots and persistence value parsing.
library;

/// Known persisted trail status values in Firestore `status`.
enum TrailStatusValue {
  draft('draft'),
  published('published'),
  disabled('disabled'),
  archived('archived');

  const TrailStatusValue(this.firestoreValue);

  final String firestoreValue;
}

/// Known persisted trail type values in Firestore `trailType`.
enum TrailTypeValue {
  curated('curated'),
  generated('generated');

  const TrailTypeValue(this.firestoreValue);

  final String firestoreValue;
}

/// Known persisted stop progress state values in Firestore `stopStates`.
enum TrailStopProgressStateValue {
  upcoming('upcoming'),
  current('current'),
  checkedIn('checkedIn'),
  skipped('skipped'),
  missed('missed'),
  completed('completed');

  const TrailStopProgressStateValue(this.firestoreValue);

  final String firestoreValue;
}

/// Known persisted trail activity action values written by mobile.
abstract final class TrailActivityAction {
  static const started = 'started';
  static const arrived = 'arrived';
  static const continueNext = 'continue_next';
  static const completed = 'completed';
  static const skippedStop = 'skipped_stop';
  static const completedAfterSkip = 'completed_after_skip';
  static const directionsRequested = 'directions_requested';
}

/// Parsed trail status — unknown raw values are preserved, not coerced.
sealed class TrailStatusSnapshot {
  const TrailStatusSnapshot();

  const factory TrailStatusSnapshot.known(TrailStatusValue value) =
      KnownTrailStatusSnapshot;

  const factory TrailStatusSnapshot.unknown(String rawValue) =
      UnknownTrailStatusSnapshot;

  const factory TrailStatusSnapshot.missing() = MissingTrailStatusSnapshot;
}

final class KnownTrailStatusSnapshot extends TrailStatusSnapshot {
  const KnownTrailStatusSnapshot(this.value);

  final TrailStatusValue value;
}

final class UnknownTrailStatusSnapshot extends TrailStatusSnapshot {
  const UnknownTrailStatusSnapshot(this.rawValue);

  final String rawValue;
}

final class MissingTrailStatusSnapshot extends TrailStatusSnapshot {
  const MissingTrailStatusSnapshot();
}

/// Parsed trail type — unknown raw values are preserved, not coerced.
sealed class TrailTypeSnapshot {
  const TrailTypeSnapshot();

  const factory TrailTypeSnapshot.known(TrailTypeValue value) =
      KnownTrailTypeSnapshot;

  const factory TrailTypeSnapshot.unknown(String rawValue) =
      UnknownTrailTypeSnapshot;

  const factory TrailTypeSnapshot.missing() = MissingTrailTypeSnapshot;
}

final class KnownTrailTypeSnapshot extends TrailTypeSnapshot {
  const KnownTrailTypeSnapshot(this.value);

  final TrailTypeValue value;
}

final class UnknownTrailTypeSnapshot extends TrailTypeSnapshot {
  const UnknownTrailTypeSnapshot(this.rawValue);

  final String rawValue;
}

final class MissingTrailTypeSnapshot extends TrailTypeSnapshot {
  const MissingTrailTypeSnapshot();
}

/// Parsed stop progress state — unknown raw values are preserved.
sealed class TrailStopProgressStateSnapshot {
  const TrailStopProgressStateSnapshot();

  const factory TrailStopProgressStateSnapshot.known(
    TrailStopProgressStateValue value,
  ) = KnownTrailStopProgressStateSnapshot;

  const factory TrailStopProgressStateSnapshot.unknown(String rawValue) =
      UnknownTrailStopProgressStateSnapshot;
}

final class KnownTrailStopProgressStateSnapshot
    extends TrailStopProgressStateSnapshot {
  const KnownTrailStopProgressStateSnapshot(this.value);

  final TrailStopProgressStateValue value;
}

final class UnknownTrailStopProgressStateSnapshot
    extends TrailStopProgressStateSnapshot {
  const UnknownTrailStopProgressStateSnapshot(this.rawValue);

  final String rawValue;
}

/// Infrastructure codec for persisted trail enum-like strings.
abstract final class TrailPersistenceCodec {
  static TrailStatusSnapshot parseStatus(String? raw) {
    final normalized = raw?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return const TrailStatusSnapshot.missing();
    }
    for (final value in TrailStatusValue.values) {
      if (value.firestoreValue == normalized) {
        return TrailStatusSnapshot.known(value);
      }
    }
    return TrailStatusSnapshot.unknown(raw!.trim());
  }

  static TrailTypeSnapshot parseType(String? raw) {
    final normalized = raw?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return const TrailTypeSnapshot.missing();
    }
    for (final value in TrailTypeValue.values) {
      if (value.firestoreValue == normalized) {
        return TrailTypeSnapshot.known(value);
      }
    }
    return TrailTypeSnapshot.unknown(raw!.trim());
  }

  static TrailStopProgressStateSnapshot parseStopProgressState(String? raw) {
    final normalized = raw?.trim();
    if (normalized == null || normalized.isEmpty) {
      return const TrailStopProgressStateSnapshot.unknown('');
    }
    for (final value in TrailStopProgressStateValue.values) {
      if (value.firestoreValue == normalized) {
        return TrailStopProgressStateSnapshot.known(value);
      }
    }
    return TrailStopProgressStateSnapshot.unknown(normalized);
  }
}

/// Embedded trail stop snapshot (current schema stores stops in the trail doc).
final class TrailStopSnapshot {
  const TrailStopSnapshot({
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
}

/// Venue participation application settings stored on trail documents.
///
/// Existing trails default to [acceptsVenueApplications] false.
final class TrailParticipationSettingsSnapshot {
  const TrailParticipationSettingsSnapshot({
    this.acceptsVenueApplications = false,
    this.participationApplicationOpensAt,
    this.participationApplicationClosesAt,
    this.maximumStops,
    this.venueSelectableStopPosition = true,
    this.participationInstructions = '',
  });

  final bool acceptsVenueApplications;
  final DateTime? participationApplicationOpensAt;
  final DateTime? participationApplicationClosesAt;
  final int? maximumStops;
  final bool venueSelectableStopPosition;
  final String participationInstructions;
}

/// Immutable trail document snapshot returned by repositories.
final class TrailSnapshot {
  const TrailSnapshot({
    required this.trailId,
    required this.name,
    required this.title,
    required this.description,
    required this.subtitle,
    required this.bannerImageUrl,
    required this.status,
    required this.published,
    required this.area,
    required this.availabilityStart,
    required this.availabilityEnd,
    required this.startTime,
    required this.endTime,
    required this.estimatedDurationMinutes,
    required this.estimatedWalkingDistance,
    required this.averageRating,
    required this.venueCount,
    required this.trailType,
    required this.generatedAt,
    required this.stops,
    this.createdAt,
    this.updatedAt,
    this.publishedAt,
    this.unpublishedAt,
    this.archivedAt,
    this.disabledAt,
    this.searchTerms = const [],
    this.participationSettings = const TrailParticipationSettingsSnapshot(),
  });

  final String trailId;
  final String name;
  final String title;
  final String description;
  final String subtitle;
  final String bannerImageUrl;
  final TrailStatusSnapshot status;
  final bool published;
  final String area;
  final DateTime availabilityStart;
  final DateTime availabilityEnd;
  final DateTime startTime;
  final DateTime endTime;
  final int estimatedDurationMinutes;
  final int estimatedWalkingDistance;
  final double averageRating;
  final int venueCount;
  final TrailTypeSnapshot trailType;
  final DateTime generatedAt;
  final List<TrailStopSnapshot> stops;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? publishedAt;
  final DateTime? unpublishedAt;
  final DateTime? archivedAt;
  final DateTime? disabledAt;
  final List<String> searchTerms;
  final TrailParticipationSettingsSnapshot participationSettings;
}

/// User active trail pointer at `users/{uid}/trail_state/active`.
final class TrailActiveStateSnapshot {
  const TrailActiveStateSnapshot({required this.activeTrailId, this.updatedAt});

  final String activeTrailId;
  final DateTime? updatedAt;
}

/// Stop progress state map keyed by stop order.
typedef TrailStopStatesSnapshot = Map<int, TrailStopProgressStateSnapshot>;

/// User trail progress snapshot at canonical and legacy paths.
final class TrailProgressSnapshot {
  const TrailProgressSnapshot({
    required this.trailId,
    required this.started,
    required this.completed,
    required this.currentStop,
    required this.checkedInStops,
    required this.stopStates,
    this.trailGeneratedAt,
    this.startedAt,
    this.updatedAt,
    this.completedAt,
    this.lastCheckedInVenueId,
    this.lastCheckedInStopOrder,
  });

  final String trailId;
  final bool started;
  final bool completed;
  final int currentStop;
  final Set<int> checkedInStops;
  final TrailStopStatesSnapshot stopStates;
  final DateTime? trailGeneratedAt;
  final DateTime? startedAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final String? lastCheckedInVenueId;
  final int? lastCheckedInStopOrder;
}

/// Append-only trail activity snapshot.
final class TrailActivitySnapshot {
  const TrailActivitySnapshot({
    required this.activityId,
    required this.trailId,
    required this.userId,
    required this.isAnonymous,
    required this.action,
    required this.createdAt,
    this.venueId,
    this.stopOrder,
  });

  final String activityId;
  final String trailId;
  final String? userId;
  final bool isAnonymous;
  final String action;
  final DateTime createdAt;
  final String? venueId;
  final int? stopOrder;
}

/// External artwork reference for trail banners (URL-only in current mobile).
final class TrailArtworkReference {
  const TrailArtworkReference({required this.url});

  final String url;
}
