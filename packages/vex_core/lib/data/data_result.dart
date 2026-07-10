import '../shared/vex_exception.dart';

sealed class DataResult<T> {
  const DataResult();
}

final class DataSuccess<T> extends DataResult<T> {
  const DataSuccess(this.value);

  final T value;
}

final class DataFailure<T> extends DataResult<T> {
  const DataFailure(this.error);

  final VexException error;
}
