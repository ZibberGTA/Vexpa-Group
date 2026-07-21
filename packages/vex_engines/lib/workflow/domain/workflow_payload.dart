/// Consumer-owned payload transported by VexWorkflow without domain parsing.
final class WorkflowPayload {
  const WorkflowPayload({required this.values, required this.schemaVersion});

  final Map<String, Object?> values;
  final int schemaVersion;

  WorkflowPayload copyWith({Map<String, Object?>? values, int? schemaVersion}) {
    return WorkflowPayload(
      values: values ?? this.values,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkflowPayload &&
          other.schemaVersion == schemaVersion &&
          _mapEquals(other.values, values);

  @override
  int get hashCode =>
      Object.hash(schemaVersion, Object.hashAll(values.entries));

  static bool _mapEquals(Map<String, Object?> a, Map<String, Object?> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
