/// Result of growth validation or orchestration.
sealed class GrowthResult<T> {
  const GrowthResult();
}

final class GrowthSuccess<T> extends GrowthResult<T> {
  const GrowthSuccess(this.value);

  final T value;
}

final class GrowthFailure<T> extends GrowthResult<T> {
  const GrowthFailure(this.code, this.message);

  final String code;
  final String message;
}
