import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_app/core/vexcore/mobile_trail_orchestration.dart';
import 'package:vex_engines/trail/trail_engine.dart';

void main() {
  test('MobileTrailOrchestration exposes application services without TrailService', () {
    expect(MobileTrailOrchestration.discovery, isA<TrailDiscoveryApplicationService>());
    expect(MobileTrailOrchestration.management, isA<TrailManagementApplicationService>());
    expect(MobileTrailOrchestration.progress, isA<TrailProgressApplicationService>());
    expect(MobileTrailOrchestration.checkIn, isA<TrailCheckInApplicationService>());
    expect(MobileTrailOrchestration.generation, isA<TrailGenerationApplicationService>());
    expect(MobileTrailOrchestration.activity, isA<TrailActivityApplicationService>());
  });
}
