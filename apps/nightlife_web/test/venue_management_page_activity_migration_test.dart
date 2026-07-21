import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Feature 1.8.1 legacy activity migration inventory', () {
    final libRoot = Directory('lib/features/venue_management');

    final allowedLegacyFiles = {
      'models/venue_dashboard_activity.dart',
      'data/venue_activity_service.dart',
      'services/venue_dashboard_engine_mapper.dart',
    };

    test('entity management widgets do not reference legacy activity rows', () {
      final violations = <String>[];

      for (final entity in libRoot
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))) {
        final relative = entity.path
            .replaceFirst('${libRoot.path}${Platform.pathSeparator}', '')
            .replaceAll(r'\', '/');

        if (allowedLegacyFiles.contains(relative)) continue;
        if (!relative.startsWith('widgets/')) continue;

        final content = entity.readAsStringSync();
        if (content.contains('VenueDashboardActivity')) {
          violations.add(relative);
        }
        if (content.contains('legacyActivities')) {
          violations.add('$relative (legacyActivities)');
        }
        if (content.contains('_buildRecentActivity')) {
          violations.add('$relative (_buildRecentActivity)');
        }
        if (content.contains('activities: _buildRecentActivity')) {
          violations.add('$relative (activities override)');
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Legacy activity still referenced in: ${violations.join(', ')}',
      );
    });

    test('venue page config no longer ships mock recent activity', () {
      final configFile = File('lib/features/venue_management/models/venue_page_config.dart');
      final content = configFile.readAsStringSync();

      expect(content.contains('VenueDashboardActivity'), isFalse);
      expect(content.contains('recentActivity'), isFalse);
    });
  });
}
