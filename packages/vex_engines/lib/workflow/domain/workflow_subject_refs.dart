/// Generic string-keyed subject references supplied by consumer engines.
final class WorkflowSubjectRefs {
  const WorkflowSubjectRefs(this.values);

  final Map<String, String> values;

  String? ref(String key) {
    final value = values[key];
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value.trim();
  }

  bool containsKey(String key) => ref(key) != null;

  WorkflowSubjectRefs merge(Map<String, String> updates) {
    return WorkflowSubjectRefs({...values, ...updates});
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkflowSubjectRefs && _mapEquals(other.values, values);

  @override
  int get hashCode => Object.hashAll(
    values.entries.map((entry) => Object.hash(entry.key, entry.value)).toList(),
  );

  static bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
