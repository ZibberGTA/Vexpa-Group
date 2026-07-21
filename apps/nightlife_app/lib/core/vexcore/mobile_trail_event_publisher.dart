import 'package:vex_engines/trail/trail_engine.dart';
import 'package:vex_core/vex_core.dart';

/// Publishes trail events through [MobileVexCore.eventBus].
final class MobileTrailEventPublisher implements TrailEventPublisherPort {
  const MobileTrailEventPublisher(this.eventBus);

  final VexEventBus eventBus;

  @override
  Future<void> publishAll(List<VexEvent> events) async {
    for (final event in events) {
      await eventBus.publish(event);
    }
  }
}
