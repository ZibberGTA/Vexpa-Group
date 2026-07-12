/// Ensures untracked local platform configuration files exist (empty templates).
///
/// Run from repo root after clone:
///   dart run tool/ensure_local_platform_config.dart
///
/// Optionally pass real keys via environment variables to generate local files:
///   VEXDA_ROUTES_API_KEY, VEXDA_WEB_MAPS_API_KEY, VEXDA_ANDROID_MAPS_API_KEY,
///   VEXDA_IOS_MAPS_API_KEY
import 'dart:io';

void main() {
  final repoRoot = _findRepoRoot();
  _ensureFile(
    repoRoot: repoRoot,
    targetRelative: 'apps/nightlife_app/lib/core/config/app_secrets.local.dart',
    exampleRelative: 'apps/nightlife_app/lib/core/config/app_secrets.local.dart.example',
    envKey: 'VEXDA_ROUTES_API_KEY',
    templateReplacer: _replaceRoutesKeyInDart,
  );
  _ensureFile(
    repoRoot: repoRoot,
    targetRelative: 'apps/nightlife_web/web/vexda_maps_config.js',
    exampleRelative: 'apps/nightlife_web/web/vexda_maps_config.example.js',
    envKey: 'VEXDA_WEB_MAPS_API_KEY',
    templateReplacer: _replaceWebMapsKeyInJs,
  );
  _ensureAndroidLocalProperties(repoRoot);
  _ensureFile(
    repoRoot: repoRoot,
    targetRelative: 'apps/nightlife_app/ios/Flutter/Secrets.xcconfig',
    exampleRelative: 'apps/nightlife_app/ios/Flutter/Secrets.xcconfig.example',
    envKey: 'VEXDA_IOS_MAPS_API_KEY',
    templateReplacer: _replaceIosMapsKeyInXcconfig,
  );
  stdout.writeln('Local platform configuration files are ready.');
  stdout.writeln('See docs/platform/API_KEYS_SETUP.md for key placement.');
}

Directory _findRepoRoot() {
  var dir = Directory.current;
  while (true) {
    final appMarker = File(
      '${dir.path}${Platform.pathSeparator}apps${Platform.pathSeparator}nightlife_app${Platform.pathSeparator}pubspec.yaml',
    );
    if (appMarker.existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('Could not find Vexda repository root.');
    }
    dir = parent;
  }
}

void _ensureFile({
  required Directory repoRoot,
  required String targetRelative,
  required String exampleRelative,
  required String envKey,
  required String Function(String template, String key) templateReplacer,
}) {
  final target = File('${repoRoot.path}${Platform.pathSeparator}$targetRelative');
  final example = File('${repoRoot.path}${Platform.pathSeparator}$exampleRelative');
  if (!example.existsSync()) {
    throw StateError('Missing template: $exampleRelative');
  }

  final envValue = Platform.environment[envKey]?.trim() ?? '';
  if (envValue.isNotEmpty) {
    final content = templateReplacer(example.readAsStringSync(), envValue);
    target.parent.createSync(recursive: true);
    target.writeAsStringSync(content);
    stdout.writeln('Wrote $targetRelative from $envKey.');
    return;
  }

  if (target.existsSync()) {
    stdout.writeln('Kept existing $targetRelative');
    return;
  }

  target.parent.createSync(recursive: true);
  target.writeAsStringSync(example.readAsStringSync());
  stdout.writeln('Created $targetRelative from template.');
}

void _ensureAndroidLocalProperties(Directory repoRoot) {
  const relative = 'apps/nightlife_app/android/local.properties';
  final target = File('${repoRoot.path}${Platform.pathSeparator}$relative');
  final envValue = Platform.environment['VEXDA_ANDROID_MAPS_API_KEY']?.trim() ?? '';

  if (envValue.isNotEmpty) {
    final lines = <String>[];
    if (target.existsSync()) {
      lines.addAll(target.readAsLinesSync());
    }
    _upsertProperty(lines, 'VEXDA_ANDROID_MAPS_API_KEY', envValue);
    target.parent.createSync(recursive: true);
    target.writeAsStringSync('${lines.join('\n')}\n');
    stdout.writeln('Updated $relative from VEXDA_ANDROID_MAPS_API_KEY.');
    return;
  }

  if (target.existsSync()) {
    stdout.writeln('Kept existing $relative');
    return;
  }

  stdout.writeln(
    'Note: $relative is created by Flutter on first Android run. '
    'Add VEXDA_ANDROID_MAPS_API_KEY there for Maps.',
  );
}

void _upsertProperty(List<String> lines, String key, String value) {
  final prefix = '$key=';
  var found = false;
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].startsWith(prefix) || lines[i] == key) {
      lines[i] = '$key=$value';
      found = true;
      break;
    }
  }
  if (!found) {
    lines.add('$key=$value');
  }
}

String _replaceRoutesKeyInDart(String template, String key) {
  return template.replaceFirst(
    "const String kLocalRoutesApiKey = '';",
    "const String kLocalRoutesApiKey = '${_escapeDartSingleQuoted(key)}';",
  );
}

String _replaceWebMapsKeyInJs(String template, String key) {
  return template.replaceFirst(
    "apiKey: ''",
    "apiKey: '${_escapeJsSingleQuoted(key)}'",
  );
}

String _replaceIosMapsKeyInXcconfig(String template, String key) {
  return template.replaceFirst(
    'MAPS_API_KEY=',
    'MAPS_API_KEY=$key',
  );
}

String _escapeDartSingleQuoted(String value) =>
    value.replaceAll(r'\', r'\\').replaceAll("'", r"\'");

String _escapeJsSingleQuoted(String value) =>
    value.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
