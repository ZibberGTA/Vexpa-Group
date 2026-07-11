import 'package:test/test.dart';
import 'package:vex_core/vex_core.dart';

void main() {
  group('InProcessVexEventBus', () {
    test('publish delivers events to subscribers', () async {
      final bus = InProcessVexEventBus();
      final received = <VenueProfileUpdatedEvent>[];

      final subscription = bus.subscribe<VenueProfileUpdatedEvent>((event) async {
        received.add(event);
      });

      await bus.publish(
        VenueProfileUpdatedEvent(
          venueId: 'venue-1',
          updatedByUid: 'owner-1',
        ),
      );

      expect(received, hasLength(1));
      expect(received.first.venueId, 'venue-1');
      await subscription.cancel();
    });

    test('handler failures do not block other handlers', () async {
      final bus = InProcessVexEventBus();
      var secondCalled = false;

      bus.subscribe<VenueProfileUpdatedEvent>((_) async {
        throw StateError('handler failed');
      });
      bus.subscribe<VenueProfileUpdatedEvent>((_) async {
        secondCalled = true;
      });

      await bus.publish(
        VenueProfileUpdatedEvent(
          venueId: 'venue-1',
          updatedByUid: 'owner-1',
        ),
      );

      expect(secondCalled, isTrue);
    });

    test('cancelled subscriptions stop receiving events', () async {
      final bus = InProcessVexEventBus();
      var callCount = 0;

      final subscription = bus.subscribe<VenueProfileUpdatedEvent>((_) async {
        callCount++;
      });

      await bus.publish(
        VenueProfileUpdatedEvent(
          venueId: 'venue-1',
          updatedByUid: 'owner-1',
        ),
      );
      await subscription.cancel();
      await bus.publish(
        VenueProfileUpdatedEvent(
          venueId: 'venue-2',
          updatedByUid: 'owner-1',
        ),
      );

      expect(callCount, 1);
    });
  });
}
