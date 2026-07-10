abstract class VexEvent {
  const VexEvent({required this.id, required this.occurredAt});

  final String id;
  final DateTime occurredAt;

  String get type;
}
