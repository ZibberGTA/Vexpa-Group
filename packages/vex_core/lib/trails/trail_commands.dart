import 'trail_snapshots.dart';

/// Creates a new trail document with empty stops.
final class CreateTrailCommand {
  CreateTrailCommand({
    required this.name,
    required this.description,
    required this.bannerImageUrl,
    required this.area,
    required this.availabilityStart,
    required this.availabilityEnd,
    required this.trailType,
    this.trailId,
  });

  final String? trailId;
  final String name;
  final String description;
  final String bannerImageUrl;
  final String area;
  final DateTime availabilityStart;
  final DateTime availabilityEnd;
  final TrailTypeValue trailType;
}

/// Updates trail metadata fields (does not replace stops).
final class UpdateTrailMetadataCommand {
  UpdateTrailMetadataCommand({
    required this.trailId,
    required this.name,
    required this.description,
    required this.bannerImageUrl,
    required this.area,
    required this.availabilityStart,
    required this.availabilityEnd,
    required this.trailType,
  }) : assert(trailId.trim().isNotEmpty, 'trailId must not be empty');

  final String trailId;
  final String name;
  final String description;
  final String bannerImageUrl;
  final String area;
  final DateTime availabilityStart;
  final DateTime availabilityEnd;
  final TrailTypeValue trailType;
}

/// Replaces embedded stops and related availability/duration fields.
final class UpdateTrailStopsCommand {
  UpdateTrailStopsCommand({
    required this.trailId,
    required this.stops,
    required this.availabilityStart,
    required this.availabilityEnd,
    required this.estimatedDurationMinutes,
    required this.venueCount,
  }) : assert(trailId.trim().isNotEmpty, 'trailId must not be empty');

  final String trailId;
  final List<TrailStopSnapshot> stops;
  final DateTime availabilityStart;
  final DateTime availabilityEnd;
  final int estimatedDurationMinutes;
  final int venueCount;
}

/// Replaces an entire trail document (merge=false), e.g. generated draft write.
final class ReplaceTrailDocumentCommand {
  ReplaceTrailDocumentCommand({required this.trailId, required this.snapshot})
    : assert(trailId.trim().isNotEmpty, 'trailId must not be empty');

  final String trailId;
  final TrailSnapshot snapshot;
}

/// Publishes a trail document.
final class PublishTrailCommand {
  PublishTrailCommand({required this.trailId})
    : assert(trailId.trim().isNotEmpty, 'trailId must not be empty');

  final String trailId;
}

/// Unpublishes a trail document back to draft-like persisted state.
final class UnpublishTrailCommand {
  UnpublishTrailCommand({required this.trailId})
    : assert(trailId.trim().isNotEmpty, 'trailId must not be empty');

  final String trailId;
}

/// Archives a trail document.
final class ArchiveTrailCommand {
  ArchiveTrailCommand({required this.trailId})
    : assert(trailId.trim().isNotEmpty, 'trailId must not be empty');

  final String trailId;
}

/// Duplicates an existing trail into a new document.
final class DuplicateTrailCommand {
  DuplicateTrailCommand({required this.sourceTrailId, this.newTrailId})
    : assert(
        sourceTrailId.trim().isNotEmpty,
        'sourceTrailId must not be empty',
      );

  final String sourceTrailId;
  final String? newTrailId;
}

/// Hard-deletes a trail document.
final class DeleteTrailCommand {
  DeleteTrailCommand({required this.trailId})
    : assert(trailId.trim().isNotEmpty, 'trailId must not be empty');

  final String trailId;
}

/// Sets the user's active trail pointer.
final class SetActiveTrailCommand {
  SetActiveTrailCommand({required this.userId, required this.activeTrailId})
    : assert(userId.trim().isNotEmpty, 'userId must not be empty'),
      assert(
        activeTrailId.trim().isNotEmpty,
        'activeTrailId must not be empty',
      );

  final String userId;
  final String activeTrailId;
}

/// Creates/resets user progress when joining a trail (merge=false).
final class CreateTrailProgressCommand {
  CreateTrailProgressCommand({
    required this.userId,
    required this.trailId,
    required this.trailGeneratedAt,
    required this.stopStates,
    this.mirrorLegacyProgress = false,
  }) : assert(userId.trim().isNotEmpty, 'userId must not be empty'),
       assert(trailId.trim().isNotEmpty, 'trailId must not be empty');

  final String userId;
  final String trailId;
  final DateTime trailGeneratedAt;
  final TrailStopStatesSnapshot stopStates;
  final bool mirrorLegacyProgress;
}

/// Check-in progress update payload.
final class CheckInTrailProgressCommand {
  CheckInTrailProgressCommand({
    required this.userId,
    required this.trailId,
    required this.trailGeneratedAt,
    required this.currentStop,
    required this.checkedInStopOrder,
    required this.stopStates,
    required this.completed,
    required this.lastCheckedInVenueId,
    required this.lastCheckedInStopOrder,
    this.mirrorLegacyProgress = false,
  }) : assert(userId.trim().isNotEmpty, 'userId must not be empty'),
       assert(trailId.trim().isNotEmpty, 'trailId must not be empty');

  final String userId;
  final String trailId;
  final DateTime trailGeneratedAt;
  final int currentStop;
  final int checkedInStopOrder;
  final TrailStopStatesSnapshot stopStates;
  final bool completed;
  final String lastCheckedInVenueId;
  final int lastCheckedInStopOrder;
  final bool mirrorLegacyProgress;
}

/// Continue-after-check-in progress update payload.
final class ContinueTrailProgressCommand {
  ContinueTrailProgressCommand({
    required this.userId,
    required this.trailId,
    required this.trailGeneratedAt,
    required this.currentStop,
    required this.stopStates,
    required this.completed,
    this.mirrorLegacyProgress = false,
  }) : assert(userId.trim().isNotEmpty, 'userId must not be empty'),
       assert(trailId.trim().isNotEmpty, 'trailId must not be empty');

  final String userId;
  final String trailId;
  final DateTime trailGeneratedAt;
  final int currentStop;
  final TrailStopStatesSnapshot stopStates;
  final bool completed;
  final bool mirrorLegacyProgress;
}

/// Skip-stop progress update payload.
final class SkipTrailProgressCommand {
  SkipTrailProgressCommand({
    required this.userId,
    required this.trailId,
    required this.trailGeneratedAt,
    required this.currentStop,
    required this.stopStates,
    required this.completed,
    this.mirrorLegacyProgress = false,
  }) : assert(userId.trim().isNotEmpty, 'userId must not be empty'),
       assert(trailId.trim().isNotEmpty, 'trailId must not be empty');

  final String userId;
  final String trailId;
  final DateTime trailGeneratedAt;
  final int currentStop;
  final TrailStopStatesSnapshot stopStates;
  final bool completed;
  final bool mirrorLegacyProgress;
}

/// Writes the legacy `trail_progress/{uid}` mirror explicitly.
final class MirrorLegacyTrailProgressCommand {
  MirrorLegacyTrailProgressCommand({
    required this.userId,
    required this.progress,
  }) : assert(userId.trim().isNotEmpty, 'userId must not be empty');

  final String userId;
  final TrailProgressSnapshot progress;
}

/// Appends an immutable trail activity record.
final class AppendTrailActivityCommand {
  AppendTrailActivityCommand({
    required this.trailId,
    required this.action,
    this.userId,
    this.isAnonymous = false,
    this.venueId,
    this.stopOrder,
  }) : assert(trailId.trim().isNotEmpty, 'trailId must not be empty'),
       assert(action.trim().isNotEmpty, 'action must not be empty');

  final String trailId;
  final String action;
  final String? userId;
  final bool isAnonymous;
  final String? venueId;
  final int? stopOrder;
}

/// Upload/replace trail artwork — reserved for future Storage integration.
///
/// Current mobile stores banner URLs directly on the trail document.
final class UploadTrailArtworkCommand {
  UploadTrailArtworkCommand({
    required this.trailId,
    required this.bytes,
    required this.contentType,
    this.fileName,
  }) : assert(trailId.trim().isNotEmpty, 'trailId must not be empty'),
       assert(bytes.isNotEmpty, 'bytes must not be empty'),
       assert(contentType.trim().isNotEmpty, 'contentType must not be empty');

  final String trailId;
  final List<int> bytes;
  final String contentType;
  final String? fileName;
}

/// Deletes trail artwork from Storage — reserved for future integration.
final class DeleteTrailArtworkCommand {
  DeleteTrailArtworkCommand({required this.trailId})
    : assert(trailId.trim().isNotEmpty, 'trailId must not be empty');

  final String trailId;
}
