import '../domain/trail_result.dart';

/// Application-layer result wrapping domain and infrastructure outcomes.
sealed class TrailApplicationResult<T> {
  const TrailApplicationResult();
}

final class TrailApplicationSuccess<T> extends TrailApplicationResult<T> {
  const TrailApplicationSuccess(this.value, {this.warnings = const []});

  final T value;
  final List<String> warnings;
}

final class TrailApplicationFailure<T> extends TrailApplicationResult<T> {
  const TrailApplicationFailure(this.code, this.message, {this.cause});

  final String code;
  final String message;
  final Object? cause;
}

abstract final class TrailApplicationFailureCodes {
  static const domainFailure = 'domainFailure';
  static const repositoryFailure = 'repositoryFailure';
  static const mappingFailure = 'mappingFailure';
  static const notFound = 'notFound';
  static const permissionFailure = 'permissionFailure';
  static const authenticationRequired = 'authenticationRequired';
  static const partialWriteFailure = 'partialWriteFailure';
  static const venueLookupFailure = 'venueLookupFailure';
  static const legacyMirrorFailure = 'legacyMirrorFailure';
  static const eventPublicationFailure = 'eventPublicationFailure';
  static const locationInputFailure = 'locationInputFailure';
}

TrailApplicationFailure<T> fromTrailFailure<T>(TrailFailure<dynamic> failure) {
  return TrailApplicationFailure(
    TrailApplicationFailureCodes.domainFailure,
    failure.message,
  );
}

TrailApplicationFailure<T> fromRepositoryFailure<T>(
  String message, {
  String? code,
  Object? cause,
}) {
  return TrailApplicationFailure(
    TrailApplicationFailureCodes.repositoryFailure,
    message,
    cause: cause,
  );
}
