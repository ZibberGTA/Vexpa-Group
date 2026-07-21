import 'package:vex_core/events/vex_event.dart';

/// Publishes trail domain events after successful persistence.
abstract interface class TrailEventPublisherPort {
  Future<void> publishAll(List<VexEvent> events);
}

/// In-process publisher for tests.
final class InMemoryTrailEventPublisher implements TrailEventPublisherPort {
  final published = <VexEvent>[];

  @override
  Future<void> publishAll(List<VexEvent> events) async {
    published.addAll(events);
  }
}
