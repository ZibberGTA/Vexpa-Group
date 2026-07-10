import 'vex_exception.dart';

sealed class VexResult<T> {
  const VexResult();
}

final class VexSuccess<T> extends VexResult<T> {
  const VexSuccess(this.value);

  final T value;
}

final class VexFailure<T> extends VexResult<T> {
  const VexFailure(this.error);

  final VexException error;
}
