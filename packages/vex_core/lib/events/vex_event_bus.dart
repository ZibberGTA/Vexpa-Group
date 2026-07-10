import 'event_subscription.dart';
import 'vex_event.dart';

abstract interface class VexEventBus {
  Future<void> publish(VexEvent event);

  EventSubscription subscribe<TEvent extends VexEvent>(
    Future<void> Function(TEvent event) handler,
  );
}
