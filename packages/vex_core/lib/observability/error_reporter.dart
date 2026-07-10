abstract interface class ErrorReporter {
  Future<void> report(
    Object error, {
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  });
}
