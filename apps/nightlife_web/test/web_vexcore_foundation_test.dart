import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/core/vexcore/web_vexcore.dart';
import 'package:vex_core/vex_core.dart';

void main() {
  tearDown(() {
    WebVexCore.authenticationOverride = null;
    WebVexCore.identityOverride = null;
    WebVexCore.eventBusOverride = null;
  });

  test('WebVexCore exposes shared singleton platform services', () {
    final authA = WebVexCore.authentication;
    final authB = WebVexCore.authentication;
    final identityA = WebVexCore.identity;
    final identityB = WebVexCore.identity;
    final busA = WebVexCore.eventBus;
    final busB = WebVexCore.eventBus;

    expect(identical(authA, authB), isTrue);
    expect(identical(identityA, identityB), isTrue);
    expect(identical(busA, busB), isTrue);
  });

  test('event bus publishes venue profile updates without Firebase', () async {
    final bus = InProcessVexEventBus();
    WebVexCore.eventBusOverride = bus;

    VenueProfileUpdatedEvent? received;
    bus.subscribe<VenueProfileUpdatedEvent>((event) async {
      received = event;
    });

    await WebVexCore.eventBus.publish(
      VenueProfileUpdatedEvent(
        venueId: 'venue-1',
        updatedByUid: 'owner-1',
      ),
    );

    expect(received?.venueId, 'venue-1');
  });
}
