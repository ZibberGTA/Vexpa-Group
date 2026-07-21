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
  _ensureWebMapsConfig(repoRoot);
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

void _ensureWebMapsConfig(Directory repoRoot) {
  const targetRelative = 'apps/nightlife_web/web/vexda_maps_config.js';
  const exampleRelative = 'apps/nightlife_web/web/vexda_maps_config.example.js';
  const envKey = 'VEXDA_WEB_MAPS_API_KEY';

  final target = File('${repoRoot.path}${Platform.pathSeparator}$targetRelative');
  final example = File('${repoRoot.path}${Platform.pathSeparator}$exampleRelative');
  if (!example.existsSync()) {
    throw StateError('Missing template: $exampleRelative');
  }

  final envValue = Platform.environment[envKey]?.trim() ?? '';
  if (envValue.isNotEmpty) {
    final content = _replaceWebMapsKeyInJs(example.readAsStringSync(), envValue);
    target.parent.createSync(recursive: true);
    target.writeAsStringSync(content);
    stdout.writeln('Wrote $targetRelative from $envKey.');
    return;
  }

  final canonicalKey = _canonicalWebMapsApiKey(repoRoot);

  if (target.existsSync()) {
    final existingKey = _readJsConfigApiKey(target.readAsStringSync());
    if (_isUsableMapsKey(existingKey) &&
        _isSameMapsKey(existingKey, canonicalKey)) {
      stdout.writeln('Kept existing $targetRelative');
      return;
    }

    if (_isUsableMapsKey(canonicalKey)) {
      final content =
          _replaceWebMapsKeyInJs(example.readAsStringSync(), canonicalKey!);
      target.writeAsStringSync(content);
      stdout.writeln(
        'Restored $targetRelative to the last working web Maps browser key.',
      );
      return;
    }

    if (_isUsableMapsKey(existingKey)) {
      stdout.writeln('Kept existing $targetRelative');
      return;
    }

    stdout.writeln('Kept existing $targetRelative');
    return;
  }

  target.parent.createSync(recursive: true);
  if (_isUsableMapsKey(canonicalKey)) {
    final content =
        _replaceWebMapsKeyInJs(example.readAsStringSync(), canonicalKey!);
    target.writeAsStringSync(content);
    stdout.writeln(
      'Created $targetRelative from the last working web Maps browser key.',
    );
    return;
  }

  target.writeAsStringSync(example.readAsStringSync());
  stdout.writeln('Created $targetRelative from template.');
}

String? _readJsConfigApiKey(String jsContent) {
  final match = RegExp(r"apiKey:\s*'((?:\\'|[^'])*)'").firstMatch(jsContent);
  if (match == null) {
    return null;
  }
  return match.group(1)?.replaceAll(r"\'", "'");
}

bool _isUsableMapsKey(String? key) {
  if (key == null) {
    return false;
  }
  final trimmed = key.trim();
  return trimmed.isNotEmpty && !trimmed.contains('REPLACE');
}

bool _isSameMapsKey(String? a, String? b) {
  if (a == null || b == null) {
    return false;
  }
  return a.trim() == b.trim();
}

String? _canonicalWebMapsApiKey(Directory repoRoot) {
  return _webMapsApiKeyFromGitIndexHtml(repoRoot);
}

String? _recoverWebMapsApiKey(Directory repoRoot) {
  return _canonicalWebMapsApiKey(repoRoot);
}

String? _webMapsApiKeyFromGitIndexHtml(Directory repoRoot) {
  final result = Process.runSync(
    'git',
    ['show', 'b394ec1^:apps/nightlife_web/web/index.html'],
    workingDirectory: repoRoot.path,
  );
  if (result.exitCode != 0) {
    return null;
  }
  final html = _processStdout(result.stdout);
  if (html.isEmpty) {
    return null;
  }
  return _parseMapsApiKeyFromHtml(html);
}

String _processStdout(Object? stdout) {
  if (stdout == null) {
    return '';
  }
  if (stdout is String) {
    return stdout;
  }
  if (stdout is List<int>) {
    return systemEncoding.decode(stdout);
  }
  return stdout.toString();
}

String? _parseMapsApiKeyFromHtml(String html) {
  final match = RegExp(
    r'maps\.googleapis\.com/maps/api/js\?key=([^&"]+)',
  ).firstMatch(html);
  if (match == null) {
    return null;
  }
  return Uri.decodeComponent(match.group(1)!);
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
