import 'package:flutter/foundation.dart';
import 'package:vex_core/vex_core.dart';
import 'package:vex_engines/discovery/application/discovery_unified_search_composer.dart';
import 'package:vex_engines/discovery/application/discovery_venue_search_service.dart';
import 'package:vex_engines/venue/application/venue_profile_update_service.dart';
import 'package:vex_engines/venue/data/venue_profile_write_repository.dart';

import 'firebase_authentication_adapter.dart';
import 'firebase_identity_adapter.dart';
import 'firebase_venue_deal_repository.dart';
import 'firebase_venue_drink_repository.dart';
import 'firebase_venue_event_repository.dart';
import 'firebase_venue_profile_write_repository.dart';
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

  static final _defaultVenueDrinkRepository = FirebaseVenueDrinkRepository();

  /// Test override for venue drink repository. Reset to null after each test.
  @visibleForTesting
  static VenueDrinkRepository? venueDrinkRepositoryOverride;

  static VenueDrinkRepository get venueDrinkRepository =>
      venueDrinkRepositoryOverride ?? _defaultVenueDrinkRepository;

  static VenueDrinkDataService get venueDrinkDataService =>
      VenueDrinkDataService(repository: venueDrinkRepository);

  static final _defaultVenueDealRepository = FirebaseVenueDealRepository();

  /// Test override for venue deal repository. Reset to null after each test.
  @visibleForTesting
  static VenueDealRepository? venueDealRepositoryOverride;

  static VenueDealRepository get venueDealRepository =>
      venueDealRepositoryOverride ?? _defaultVenueDealRepository;

  static VenueDealDataService get venueDealDataService =>
      VenueDealDataService(repository: venueDealRepository);

  static final _defaultVenueEventRepository = FirebaseVenueEventRepository();

  /// Test override for venue event repository. Reset to null after each test.
  @visibleForTesting
  static VenueEventRepository? venueEventRepositoryOverride;

  static VenueEventRepository get venueEventRepository =>
      venueEventRepositoryOverride ?? _defaultVenueEventRepository;

  static VenueEventDataService get venueEventDataService =>
      VenueEventDataService(repository: venueEventRepository);

  static const venueProfileUpdateService = VenueProfileUpdateService();

  static final _defaultVenueProfileWriteRepository =
      FirebaseVenueProfileWriteRepository();

  /// Test override for venue profile write repository. Reset to null after each test.
  @visibleForTesting
  static VenueProfileWriteRepository? venueProfileWriteRepositoryOverride;

  static VenueProfileWriteRepository get venueProfileWriteRepository =>
      venueProfileWriteRepositoryOverride ??
      _defaultVenueProfileWriteRepository;

  static const discoveryVenueSearchService = DiscoveryVenueSearchService();

  static const discoveryUnifiedSearchComposer =
      DiscoveryUnifiedSearchComposer();

  static const permissionEvaluator = VexPermissionEvaluator();
  static const entitlementService = EntitlementService();

  static final InProcessVexEventBus _defaultEventBus = InProcessVexEventBus(
    logger: ConsoleVexLogger(prefix: 'WebVexCore'),
  );

  static final InMemoryConfigurationService _defaultConfiguration =
      InMemoryConfigurationService(
    environment: kDebugMode
        ? VexEnvironment.development
        : VexEnvironment.production,
  );

  /// Test override for event bus. Reset to null after each test.
  @visibleForTesting
  static VexEventBus? eventBusOverride;

  static VexEventBus get eventBus => eventBusOverride ?? _defaultEventBus;

  static ConfigurationService get configuration => _defaultConfiguration;

  static VexLogger get logger => ConsoleVexLogger(prefix: 'WebVexCore');

  static ErrorReporter get errorReporter => const NoOpErrorReporter();
}
