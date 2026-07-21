/// Builds the Vexda Flutter web app after ensuring platform configuration.
///
/// Usage from repository root:
///   dart run tool/build_nightlife_web.dart --release
///   dart run tool/build_nightlife_web.dart --release --dart-define=PRIVATE_DEVELOPMENT_MODE=true
///
/// Set `VEXDA_WEB_MAPS_API_KEY` and `VEXDA_WEB_MAPS_MAP_ID` before running to generate
/// the gitignored browser Maps config automatically.
import 'dart:io';

Future<void> main(List<String> args) async {
  final repoRoot = _findRepoRoot();
  final webDir = Directory(
    '${repoRoot.path}${Platform.pathSeparator}apps${Platform.pathSeparator}nightlife_web',
  );
  if (!webDir.existsSync()) {
    throw StateError('Missing apps/nightlife_web directory.');
  }

  final ensureConfig = await Process.start(
    Platform.executable,
    ['run', 'tool/ensure_local_platform_config.dart'],
    workingDirectory: repoRoot.path,
    mode: ProcessStartMode.inheritStdio,
  );
  final ensureExit = await ensureConfig.exitCode;
  if (ensureExit != 0) {
    exit(ensureExit);
  }

  final flutterArgs = <String>['build', 'web', ...args];
  final build = await Process.start(
    'flutter',
    flutterArgs,
    workingDirectory: webDir.path,
    mode: ProcessStartMode.inheritStdio,
    runInShell: true,
  );
  exit(await build.exitCode);
}

Directory _findRepoRoot() {
  var dir = Directory.current;
  while (true) {
    final marker = File(
      '${dir.path}${Platform.pathSeparator}apps${Platform.pathSeparator}nightlife_app${Platform.pathSeparator}pubspec.yaml',
    );
    if (marker.existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('Could not find Vexda repository root.');
    }
    dir = parent;
  }
}
