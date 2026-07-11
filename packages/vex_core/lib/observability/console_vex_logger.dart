import 'vex_logger.dart';

/// Debug-friendly logger that writes structured context to stdout.
final class ConsoleVexLogger implements VexLogger {
  const ConsoleVexLogger({this.prefix = 'VexCore'});

  final String prefix;

  @override
  void debug(String message, {Map<String, Object?> context = const {}}) {
    _write('DEBUG', message, context);
  }

  @override
  void info(String message, {Map<String, Object?> context = const {}}) {
    _write('INFO', message, context);
  }

  @override
  void warning(String message, {Map<String, Object?> context = const {}}) {
    _write('WARN', message, context);
  }

  void _write(String level, String message, Map<String, Object?> context) {
    if (context.isEmpty) {
      // ignore: avoid_print
      print('[$prefix][$level] $message');
      return;
    }

    // ignore: avoid_print
    print('[$prefix][$level] $message context=$context');
  }
}
