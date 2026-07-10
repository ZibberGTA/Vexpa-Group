import 'feature_flag.dart';
import 'vex_environment.dart';

abstract interface class ConfigurationService {
  VexEnvironment get environment;

  Future<FeatureFlag> featureFlag(String key);

  String? value(String key);
}
