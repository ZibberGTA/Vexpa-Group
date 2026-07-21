/// Machine-readable eligibility blocking reasons for participation applications.
abstract final class TrailParticipationBlockingReason {
  static const trailNotFound = 'trail-not-found';
  static const trailNotPublished = 'trail-not-published';
  static const trailArchivedOrDisabled = 'trail-archived-or-disabled';
  static const applicationsNotAccepted = 'applications-not-accepted';
  static const trailTypeNotSupported = 'trail-type-not-supported';
  static const applicationWindowClosed = 'application-window-closed';
  static const applicationWindowNotOpen = 'application-window-not-open';
  static const venueAlreadyStop = 'venue-already-stop';
  static const duplicateOpenApplication = 'duplicate-open-application';
  static const approvedApplicationExists = 'approved-application-exists';
  static const invalidRequestedPosition = 'invalid-requested-position';
  static const trailCapacityReached = 'trail-capacity-reached';
  static const venueNotManageable = 'venue-not-manageable';
}
