import 'error_reporter.dart';

/// Safe default error reporter for tests and local development.
final class NoOpErrorReporter implements ErrorReporter {
  const NoOpErrorReporter();

  @override
  Future<void> report(
    Object error, {
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) async {}
}
