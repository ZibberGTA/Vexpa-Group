import 'package:flutter/foundation.dart';
import 'package:vex_core/vex_core.dart';
import 'package:vex_engines/trail/trail_engine.dart';

import 'firebase_trail_activity_repository.dart';
import 'firebase_trail_progress_repository.dart';
import 'firebase_trail_repository.dart';
import 'firebase_trail_user_context_adapter.dart';
import 'firebase_trail_venue_lookup_adapter.dart';
import 'mobile_trail_event_publisher.dart';
import 'mobile_vexcore.dart';

/// Lazy composition root for VexTrail repositories and application services.
///
/// Not wired into production [TrailService]. Use [MobileTrailOrchestration] or
/// test overrides only.
final class MobileVexCoreTrailStack {
  MobileVexCoreTrailStack._();

  static FirebaseTrailRepository? _trailRepositoryOverride;
  static FirebaseTrailProgressRepository? _progressRepositoryOverride;
  static FirebaseTrailActivityRepository? _activityRepositoryOverride;
  static FirebaseTrailVenueLookupAdapter? _venueLookupOverride;
  static FirebaseTrailUserContextAdapter? _userContextOverride;
  static TrailPersistenceCoordinator? _coordinatorOverride;
  static TrailClock? _clockOverride;

  static FirebaseTrailRepository get trailRepository =>
      _trailRepositoryOverride ??= FirebaseTrailRepository();

  static FirebaseTrailProgressRepository get progressRepository =>
      _progressRepositoryOverride ??= FirebaseTrailProgressRepository();

  static FirebaseTrailActivityRepository get activityRepository =>
      _activityRepositoryOverride ??= FirebaseTrailActivityRepository();

  static FirebaseTrailVenueLookupAdapter get venueLookup =>
      _venueLookupOverride ??= FirebaseTrailVenueLookupAdapter();

  static FirebaseTrailUserContextAdapter get userContext =>
      _userContextOverride ??= FirebaseTrailUserContextAdapter();

  static TrailClock get clock => _clockOverride ?? const SystemTrailClock();

  static TrailPersistenceCoordinator get coordinator =>
      _coordinatorOverride ??= TrailPersistenceCoordinator(
        trailRepository: trailRepository,
        progressRepository: progressRepository,
        activityRepository: activityRepository,
        eventPublisher: MobileTrailEventPublisher(MobileVexCore.eventBus),
      );

  @visibleForTesting
  static void overrideTrailRepository(FirebaseTrailRepository? repository) {
    _trailRepositoryOverride = repository;
    _coordinatorOverride = null;
  }

  @visibleForTesting
  static void overrideProgressRepository(
    FirebaseTrailProgressRepository? repository,
  ) {
    _progressRepositoryOverride = repository;
    _coordinatorOverride = null;
  }

  @visibleForTesting
  static void overrideActivityRepository(
    FirebaseTrailActivityRepository? repository,
  ) {
    _activityRepositoryOverride = repository;
    _coordinatorOverride = null;
  }

  @visibleForTesting
  static void overrideVenueLookup(FirebaseTrailVenueLookupAdapter? adapter) {
    _venueLookupOverride = adapter;
  }

  @visibleForTesting
  static void overrideUserContext(FirebaseTrailUserContextAdapter? adapter) {
    _userContextOverride = adapter;
  }

  @visibleForTesting
  static void overrideCoordinator(TrailPersistenceCoordinator? coordinator) {
    _coordinatorOverride = coordinator;
  }

  @visibleForTesting
  static void overrideClock(TrailClock? clock) {
    _clockOverride = clock;
  }

  @visibleForTesting
  static void resetTestOverrides() {
    _trailRepositoryOverride = null;
    _progressRepositoryOverride = null;
    _activityRepositoryOverride = null;
    _venueLookupOverride = null;
    _userContextOverride = null;
    _coordinatorOverride = null;
    _clockOverride = null;
  }
}
