/// Result of trail validation or orchestration.
sealed class TrailResult<T> {
  const TrailResult();
}

final class TrailSuccess<T> extends TrailResult<T> {
  const TrailSuccess(this.value);

  final T value;
}

final class TrailFailure<T> extends TrailResult<T> {
  const TrailFailure(this.code, this.message);

  final String code;
  final String message;
}

/// Machine-readable trail failure codes.
abstract final class TrailFailureCodes {
  static const invalidTrail = 'invalidTrail';
  static const invalidStatus = 'invalidStatus';
  static const invalidTransition = 'invalidTransition';
  static const notPublished = 'notPublished';
  static const notAvailable = 'notAvailable';
  static const unavailableWindow = 'unavailableWindow';
  static const invalidAvailability = 'invalidAvailability';
  static const publicationNotReady = 'publicationNotReady';
  static const noStops = 'noStops';
  static const invalidStopOrder = 'invalidStopOrder';
  static const duplicateStopOrder = 'duplicateStopOrder';
  static const stopNotFound = 'stopNotFound';
  static const wrongStop = 'wrongStop';
  static const alreadyCheckedIn = 'alreadyCheckedIn';
  static const alreadySkipped = 'alreadySkipped';
  static const tooFarAway = 'tooFarAway';
  static const locationUnavailable = 'locationUnavailable';
  static const venueLocationMissing = 'venueLocationMissing';
  static const invalidPresenceRadius = 'invalidPresenceRadius';
  static const invalidProgress = 'invalidProgress';
  static const trailAlreadyCompleted = 'trailAlreadyCompleted';
  static const activeTrailConflict = 'activeTrailConflict';
  static const staleProgress = 'staleProgress';
  static const noCandidateVenues = 'noCandidateVenues';
  static const generationFailed = 'generationFailed';
  static const mappingFailed = 'mappingFailed';
  static const checkInBlocked = 'checkInBlocked';
  static const continueNotAllowed = 'continueNotAllowed';
  static const skipNotAllowed = 'skipNotAllowed';
}
