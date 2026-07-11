import 'package:flutter/foundation.dart';
import 'package:vex_core/vex_core.dart';

import 'firebase_venue_repository.dart';

/// Composition root for mobile VexCore venue services.
final class MobileVexCore {
  MobileVexCore._();

  static FirebaseVenueRepository? _venueRepositoryOverride;

  static FirebaseVenueRepository get venueRepository =>
      _venueRepositoryOverride ??= FirebaseVenueRepository();

  static VenueDataService get venueDataService =>
      VenueDataService(repository: venueRepository);

  @visibleForTesting
  static void overrideVenueRepository(FirebaseVenueRepository? repository) {
    _venueRepositoryOverride = repository;
  }
}
