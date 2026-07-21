import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ensures consumer UI layers do not call FirebaseFirestore directly.
void main() {
  final repoRoot = Directory.current.path.endsWith('nightlife_app')
      ? Directory.current.parent.parent
      : Directory.current;

  final consumerRelativePaths = <String>[
    'apps/nightlife_app/lib/features/map/screens',
    'apps/nightlife_app/lib/features/search/screens',
    'apps/nightlife_app/lib/features/favourites/screens',
    'apps/nightlife_app/lib/features/navigation',
    'apps/nightlife_app/lib/features/account/screens',
    'apps/nightlife_app/lib/features/notifications/screens',
    'apps/nightlife_app/lib/features/venues/screens/venue_details_screen.dart',
  ];

  const documentedExemptions = <String>{
    'apps/nightlife_app/lib/features/venues/screens/venue_details_screen.dart',
  };

  test('consumer screens/widgets avoid direct FirebaseFirestore usage', () {
    final violations = <String>[];

    for (final relativeRoot in consumerRelativePaths) {
      final root = Directory('${repoRoot.path}/$relativeRoot');
      if (!root.existsSync()) {
        if (relativeRoot.endsWith('.dart')) {
          final file = File('${repoRoot.path}/$relativeRoot');
          _scanFile(file, relativeRoot, documentedExemptions, violations);
        }
        continue;
      }

      for (final entity in root.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final normalized = entity.path.replaceAll('\\', '/');
        _scanFile(entity, normalized, documentedExemptions, violations);
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Move Firestore I/O into services/adapters:\n${violations.join('\n')}',
    );
  });
}

void _scanFile(
  File file,
  String normalizedPath,
  Set<String> documentedExemptions,
  List<String> violations,
) {
  if (documentedExemptions.any(normalizedPath.endsWith)) return;

  final content = file.readAsStringSync();
  if (content.contains('FirebaseFirestore.instance') ||
      content.contains('FirebaseFirestore ')) {
    violations.add(normalizedPath);
  }
}
