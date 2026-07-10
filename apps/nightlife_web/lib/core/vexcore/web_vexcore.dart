import 'package:flutter/foundation.dart';
import 'package:vex_core/vex_core.dart';

import 'firebase_authentication_adapter.dart';
import 'firebase_identity_adapter.dart';
import 'firebase_venue_repository.dart';

/// Composition root for the web app's VexCore adapters.
abstract final class WebVexCore {
  WebVexCore._();

  static const _defaultAuthentication = FirebaseAuthenticationAdapter();
  static const _defaultIdentity = FirebaseIdentityAdapter();

  /// Test override for [authentication]. Reset to null after each test.
  @visibleForTesting
  static AuthenticationService? authenticationOverride;

  /// Test override for [identity]. Reset to null after each test.
  @visibleForTesting
  static IdentityService? identityOverride;

  static AuthenticationService get authentication =>
      authenticationOverride ?? _defaultAuthentication;

  static IdentityService get identity => identityOverride ?? _defaultIdentity;

  static final _defaultVenueRepository = FirebaseVenueRepository();

  /// Test override for venue discovery repository. Reset to null after each test.
  @visibleForTesting
  static VenueRepository? venueRepositoryOverride;

  static VenueRepository get venueRepository =>
      venueRepositoryOverride ?? _defaultVenueRepository;

  static VenueDataService get venueDataService =>
      VenueDataService(repository: venueRepository);

  static const permissionEvaluator = VexPermissionEvaluator();
}
