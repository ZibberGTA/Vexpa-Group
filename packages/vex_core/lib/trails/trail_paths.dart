/// Firestore and Storage path helpers for Trail infrastructure.
///
/// Canonical paths reflect current mobile production usage. Legacy paths are
/// retained for compatibility adapters only — do not migrate data here.
abstract final class TrailPaths {
  /// Top-level trails collection.
  static const String trailsCollection = 'trails';

  /// Fixed document id used for the legacy generated "Tonight's Trail" draft.
  static const String activeTrailDocumentId = 'activeTrail';

  /// User-scoped active trail pointer document id.
  static const String activeTrailStateDocumentId = 'active';

  /// Canonical progress document id under a user trail.
  static const String currentProgressDocumentId = 'current';

  /// Top-level legacy progress mirror collection.
  static const String legacyProgressCollection = 'trail_progress';

  /// Append-only trail activity collection.
  static const String trailActivityCollection = 'trail_activity';

  /// Returns `trails/{trailId}`.
  static String trailDocument(String trailId) =>
      '$trailsCollection/${trailId.trim()}';

  /// Returns `users/{userId}/trail_state/active`.
  static String userActiveTrailStateDocument(String userId) =>
      'users/${userId.trim()}/trail_state/$activeTrailStateDocumentId';

  /// Returns `users/{userId}/trails/{trailId}/progress/current`.
  static String userTrailProgressDocument(String userId, String trailId) =>
      'users/${userId.trim()}/trails/${trailId.trim()}/progress/$currentProgressDocumentId';

  /// Returns `trail_progress/{userId}` (legacy mirror).
  static String legacyUserTrailProgressDocument(String userId) =>
      '$legacyProgressCollection/${userId.trim()}';

  /// Returns `trail_activity/{activityId}`.
  static String trailActivityDocument(String activityId) =>
      '$trailActivityCollection/${activityId.trim()}';

  /// Recommended future Storage prefix if artwork uploads are added.
  ///
  /// Current mobile admin stores banner URLs only — no Storage writes today.
  static String trailArtworkStoragePrefix(String trailId) =>
      'trails/${trailId.trim()}/artwork';
}
