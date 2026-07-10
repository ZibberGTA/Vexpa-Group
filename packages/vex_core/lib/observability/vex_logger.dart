abstract interface class VexLogger {
  void debug(String message, {Map<String, Object?> context = const {}});

  void info(String message, {Map<String, Object?> context = const {}});

  void warning(String message, {Map<String, Object?> context = const {}});
}
