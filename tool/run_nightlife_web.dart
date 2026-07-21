/// Runs the Vexda Flutter web app on the fixed local development port.
///
/// Usage from repository root:
///   dart run tool/run_nightlife_web.dart
///   dart run tool/run_nightlife_web.dart --release
///
/// Ensures gitignored Maps config is restored automatically, then starts Chrome on
/// http://localhost:7357 (the port used in recent local Vexda web sessions).
import 'dart:io';

const _webPort = 7357;

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

  final flutterArgs = <String>[
    'run',
    '-d',
    'chrome',
    '--web-port=$_webPort',
    '--web-hostname=localhost',
    ...args,
  ];
  final run = await Process.start(
    'flutter',
    flutterArgs,
    workingDirectory: webDir.path,
    mode: ProcessStartMode.inheritStdio,
    runInShell: true,
  );
  exit(await run.exitCode);
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
