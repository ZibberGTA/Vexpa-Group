import 'package:flutter/foundation.dart';
import 'package:vex_core/vex_core.dart';

import 'firebase_authentication_adapter.dart';
import 'firebase_identity_adapter.dart';
import 'firebase_venue_repository.dart';
import 'firebase_venue_write_repository.dart';

/// Composition root for mobile VexCore platform services.
final class MobileVexCore {
  MobileVexCore._();

  static const _defaultAuthentication = FirebaseAuthenticationAdapter();
  static const _defaultIdentity = FirebaseIdentityAdapter();
  static const permissionEvaluator = VexPermissionEvaluator();
  static const entitlementService = EntitlementService();

  static FirebaseVenueRepository? _venueRepositoryOverride;
  static VenueWriteRepository? _venueWriteRepositoryOverride;
  static AuthenticationService? _authenticationOverride;
  static IdentityService? _identityOverride;
  static VexEventBus? _eventBusOverride;
  static ConfigurationService? _configurationOverride;
  static VexLogger? _loggerOverride;
  static ErrorReporter? _errorReporterOverride;

  static final InProcessVexEventBus _defaultEventBus = InProcessVexEventBus(
    logger: ConsoleVexLogger(prefix: 'MobileVexCore'),
  );

  static final ConsoleVexLogger _defaultLogger =
      ConsoleVexLogger(prefix: 'MobileVexCore');

  static final InMemoryConfigurationService _defaultConfiguration =
      InMemoryConfigurationService(
    environment: kDebugMode
        ? VexEnvironment.development
        : VexEnvironment.production,
  );

  static AuthenticationService get authentication =>
      _authenticationOverride ?? _defaultAuthentication;

  static IdentityService get identity =>
      _identityOverride ?? _defaultIdentity;

  static VexEventBus get eventBus => _eventBusOverride ?? _defaultEventBus;

  static ConfigurationService get configuration =>
      _configurationOverride ?? _defaultConfiguration;

  static VexLogger get logger =>
      _loggerOverride ?? _defaultLogger;

  static ErrorReporter get errorReporter =>
      _errorReporterOverride ?? const NoOpErrorReporter();

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

  @visibleForTesting
  static void overrideAuthentication(AuthenticationService? service) {
    _authenticationOverride = service;
  }

  @visibleForTesting
  static void overrideIdentity(IdentityService? service) {
    _identityOverride = service;
  }

  @visibleForTesting
  static void overrideEventBus(VexEventBus? bus) {
    _eventBusOverride = bus;
  }

  @visibleForTesting
  static void resetTestOverrides() {
    _venueRepositoryOverride = null;
    _venueWriteRepositoryOverride = null;
    _authenticationOverride = null;
    _identityOverride = null;
    _eventBusOverride = null;
    _configurationOverride = null;
    _loggerOverride = null;
    _errorReporterOverride = null;
  }
}
