/// Result of claim validation or orchestration.
sealed class ClaimResult<T> {
  const ClaimResult();
}

final class ClaimSuccess<T> extends ClaimResult<T> {
  const ClaimSuccess(this.value);

  final T value;
}

final class ClaimFailure<T> extends ClaimResult<T> {
  const ClaimFailure(this.code, this.message);

  final String code;
  final String message;
}
