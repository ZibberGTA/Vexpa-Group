import 'integration_result.dart';

abstract interface class IntegrationClient<TRequest, TResponse> {
  Future<IntegrationResult<TResponse>> send(TRequest request);
}
