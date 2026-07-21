import 'package:vex_engines/trail/trail_engine.dart';

import 'mobile_vexcore_trail_stack.dart';

/// Composition root for VexTrail application services.
final class MobileTrailOrchestration {
  MobileTrailOrchestration._();

  static TrailDiscoveryApplicationService? _discoveryOverride;
  static TrailManagementApplicationService? _managementOverride;
  static TrailProgressApplicationService? _progressOverride;
  static TrailCheckInApplicationService? _checkInOverride;
  static TrailGenerationApplicationService? _generationOverride;
  static TrailActivityApplicationService? _activityOverride;

  static TrailDiscoveryApplicationService get discovery =>
      _discoveryOverride ??= TrailDiscoveryApplicationService(
        trailRepository: MobileVexCoreTrailStack.trailRepository,
        clock: MobileVexCoreTrailStack.clock,
      );

  static TrailManagementApplicationService get management =>
      _managementOverride ??= TrailManagementApplicationService(
        trailRepository: MobileVexCoreTrailStack.trailRepository,
        coordinator: MobileVexCoreTrailStack.coordinator,
        clock: MobileVexCoreTrailStack.clock,
      );

  static TrailProgressApplicationService get progress =>
      _progressOverride ??= TrailProgressApplicationService(
        trailRepository: MobileVexCoreTrailStack.trailRepository,
        progressRepository: MobileVexCoreTrailStack.progressRepository,
        coordinator: MobileVexCoreTrailStack.coordinator,
        userContext: MobileVexCoreTrailStack.userContext,
        clock: MobileVexCoreTrailStack.clock,
      );

  static TrailCheckInApplicationService get checkIn =>
      _checkInOverride ??= TrailCheckInApplicationService(
        venueLookup: MobileVexCoreTrailStack.venueLookup,
        progressService: progress,
        clock: MobileVexCoreTrailStack.clock,
      );

  static TrailGenerationApplicationService get generation =>
      _generationOverride ??= TrailGenerationApplicationService(
        trailRepository: MobileVexCoreTrailStack.trailRepository,
        clock: MobileVexCoreTrailStack.clock,
      );

  static TrailActivityApplicationService get activity =>
      _activityOverride ??= TrailActivityApplicationService(
        coordinator: MobileVexCoreTrailStack.coordinator,
        userContext: MobileVexCoreTrailStack.userContext,
      );
}
