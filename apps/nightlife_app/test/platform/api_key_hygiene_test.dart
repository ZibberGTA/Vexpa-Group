import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final RegExp _googleApiKeyPattern = RegExp(r'AIzaSy[A-Za-z0-9_-]{10,}');

void main() {
  test('committed sources contain no non-Firebase Google API keys', () {
    final repoRoot = _findRepoRoot();
    final violations = <String>[];

    const allowedRelativePaths = {
      'apps/nightlife_app/lib/firebase_options.dart',
      'apps/nightlife_app/android/app/google-services.json',
      'apps/nightlife_web/lib/firebase_options.dart',
    };

    final skipDirNames = {
      '.dart_tool',
      '.git',
      'build',
      'node_modules',
      '.gradle',
      'coverage',
    };

    for (final entity in repoRoot.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final relative = _relativePath(repoRoot, entity).replaceAll('\\', '/');
      if (_shouldSkipPath(relative, skipDirNames)) continue;
      if (!_shouldScanFile(relative)) continue;
      if (allowedRelativePaths.contains(relative)) continue;

      final content = entity.readAsStringSync();
      if (_googleApiKeyPattern.hasMatch(content)) {
        violations.add(relative);
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Non-Firebase Google API keys found:\n${violations.join('\n')}',
    );
  });
}

Directory _findRepoRoot() {
  var dir = Directory.current;
  while (true) {
    final marker = File(
      '${dir.path}${Platform.pathSeparator}apps${Platform.pathSeparator}nightlife_app${Platform.pathSeparator}pubspec.yaml',
    );
    if (marker.existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('Could not find repository root from ${Directory.current.path}');
    }
    dir = parent;
  }
}

String _relativePath(Directory root, File file) {
  final rootPath = root.absolute.path;
  final filePath = file.absolute.path;
  if (!filePath.startsWith(rootPath)) return filePath;
  return filePath.substring(rootPath.length + 1);
}

bool _shouldSkipPath(String relative, Set<String> skipDirNames) {
  final parts = relative.split('/');
  return parts.any(skipDirNames.contains);
}

bool _shouldScanFile(String relative) {
  const extensions = {
    '.dart',
    '.html',
    '.js',
    '.json',
    '.xml',
    '.gradle',
    '.kts',
    '.md',
    '.yaml',
    '.yml',
    '.plist',
    '.xcconfig',
    '.properties',
  };
  final lower = relative.toLowerCase();
  if (lower.contains('app_secrets.local.dart')) return false;
  if (lower.contains('vexda_maps_config.js') && !lower.contains('.example.')) {
    return false;
  }
  if (lower.endsWith('secrets.xcconfig') && !lower.contains('.example')) {
    return false;
  }
  if (lower.endsWith('local.properties')) return false;
  return extensions.any(lower.endsWith);
}
