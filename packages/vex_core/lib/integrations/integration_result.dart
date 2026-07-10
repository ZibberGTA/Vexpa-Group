import '../shared/vex_exception.dart';

sealed class IntegrationResult<T> {
  const IntegrationResult();
}

final class IntegrationSuccess<T> extends IntegrationResult<T> {
  const IntegrationSuccess(this.value);

  final T value;
}

final class IntegrationFailure<T> extends IntegrationResult<T> {
  const IntegrationFailure(this.error);

  final VexException error;
}
