import 'dart:async';

import '../observability/vex_logger.dart';
import 'event_subscription.dart';
import 'vex_event.dart';
import 'vex_event_bus.dart';

/// In-process event bus for Version 1 platform events.
///
/// Handlers run sequentially per publish call. Failures in one handler do not
/// prevent other handlers from running.
final class InProcessVexEventBus implements VexEventBus {
  InProcessVexEventBus({VexLogger? logger}) : _logger = logger;

  final VexLogger? _logger;
  final Map<Type, List<_HandlerEntry>> _handlers = {};
  var _closed = false;

  @override
  Future<void> publish(VexEvent event) async {
    if (_closed) return;

    final entries = List<_HandlerEntry>.from(_handlers[event.runtimeType] ?? const []);
    for (final entry in entries) {
      if (_closed) return;
      try {
        await entry.handler(event);
      } on Object catch (error, stackTrace) {
        _logger?.warning(
          'VexEventBus handler failed for ${event.type}',
          context: {
            'eventId': event.id,
            'error': error.toString(),
            'stackTrace': stackTrace.toString(),
          },
        );
      }
    }
  }

  @override
  EventSubscription subscribe<TEvent extends VexEvent>(
    Future<void> Function(TEvent event) handler,
  ) {
    if (_closed) {
      return _ClosedSubscription();
    }

    final entry = _HandlerEntry(
      handler: (event) => handler(event as TEvent),
    );
    _handlers[TEvent] ??= [];
    _handlers[TEvent]!.add(entry);

    return _InProcessSubscription(
      onCancel: () {
        _handlers[TEvent]?.remove(entry);
      },
    );
  }

  /// Cancels all subscriptions and rejects future publishes.
  Future<void> dispose() async {
    _closed = true;
    _handlers.clear();
  }
}

final class _HandlerEntry {
  const _HandlerEntry({required this.handler});

  final Future<void> Function(VexEvent event) handler;
}

final class _InProcessSubscription implements EventSubscription {
  _InProcessSubscription({required this.onCancel});

  final void Function() onCancel;
  var _cancelled = false;

  @override
  Future<void> cancel() async {
    if (_cancelled) return;
    _cancelled = true;
    onCancel();
  }
}

final class _ClosedSubscription implements EventSubscription {
  @override
  Future<void> cancel() async {}
}
