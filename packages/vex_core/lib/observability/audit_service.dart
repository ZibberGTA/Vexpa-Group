abstract interface class AuditService {
  Future<void> record({
    required String action,
    required String actorId,
    Map<String, Object?> metadata = const {},
  });
}
