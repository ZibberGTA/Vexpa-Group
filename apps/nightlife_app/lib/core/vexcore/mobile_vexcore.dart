import 'package:flutter/foundation.dart';
import 'package:vex_core/vex_core.dart';

import 'firebase_venue_repository.dart';
import 'firebase_venue_write_repository.dart';

/// Composition root for mobile VexCore venue services.
final class MobileVexCore {
  MobileVexCore._();

  static FirebaseVenueRepository? _venueRepositoryOverride;
  static VenueWriteRepository? _venueWriteRepositoryOverride;

  static FirebaseVenueRepository get venueRepository =>
      _venueRepositoryOverride ??= FirebaseVenueRepository();

  static VenueWriteRepository get venueWriteRepository =>
      _venueWriteRepositoryOverride ??= FirebaseVenueWriteRepository();

  static VenueDataService get venueDataService =>
      VenueDataService(repository: venueRepository);

  @visibleForTesting
  static void overrideVenueRepository(FirebaseVenueRepository? repository) {
    _venueRepositoryOverride = repository;
  }

  @visibleForTesting
  static void overrideVenueWriteRepository(VenueWriteRepository? repository) {
    _venueWriteRepositoryOverride = repository;
  }
}
