import 'feature_flag.dart';
import 'configuration_service.dart';
import 'vex_environment.dart';

/// Static in-memory configuration for Version 1 clients and tests.
final class InMemoryConfigurationService implements ConfigurationService {
  InMemoryConfigurationService({
    this.environment = VexEnvironment.development,
    Map<String, bool>? featureFlags,
    Map<String, String>? values,
  })  : _featureFlags = Map<String, bool>.from(featureFlags ?? const {}),
        _values = Map<String, String>.from(values ?? const {});

  @override
  final VexEnvironment environment;

  final Map<String, bool> _featureFlags;
  final Map<String, String> _values;

  void setFeatureFlag(String key, bool enabled) {
    _featureFlags[key] = enabled;
  }

  void setValue(String key, String value) {
    _values[key] = value;
  }

  @override
  Future<FeatureFlag> featureFlag(String key) async {
    return FeatureFlag(key: key, isEnabled: _featureFlags[key] ?? false);
  }

  @override
  String? value(String key) => _values[key];
}
