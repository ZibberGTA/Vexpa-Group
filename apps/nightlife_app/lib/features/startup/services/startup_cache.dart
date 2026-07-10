import '../models/startup_data.dart';

class StartupCache {
  StartupCache._();

  static StartupData? _data;

  static StartupData? get data => _data;

  static void save(StartupData data) {
    _data = data;
  }

  static void clear() {
    _data = null;
  }
}
