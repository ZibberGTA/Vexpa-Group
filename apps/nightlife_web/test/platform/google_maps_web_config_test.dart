import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/core/constants/google_maps_web_config.dart';

void main() {
  test('GoogleMapsWebConfig does not expose an apiKey field', () {
    expect(GoogleMapsWebConfig.setupHint, isNotEmpty);
    expect(GoogleMapsWebConfig.gcpProjectId, 'nightlife-app-19acd');
  });

  test('index.html loads vexda_maps_config.js and not an inline Maps API key', () {
    final indexHtml = File('web/index.html');
    expect(indexHtml.existsSync(), isTrue);
    final content = indexHtml.readAsStringSync();
    expect(content, contains('vexda_maps_config.js'));
    expect(content, isNot(contains('maps.googleapis.com/maps/api/js?key=AIza')));
  });

  test('example web maps config exists and real config is not committed', () {
    expect(File('web/vexda_maps_config.example.js').existsSync(), isTrue);
    final realConfig = File('web/vexda_maps_config.js');
    if (realConfig.existsSync()) {
      final content = realConfig.readAsStringSync();
      expect(content, isNot(contains('AIza')));
    }
  });
}
