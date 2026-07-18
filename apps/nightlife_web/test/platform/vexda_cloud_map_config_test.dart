import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/core/constants/vexda_cloud_map_config.dart';

void main() {
  test('VexdaCloudMapConfig exposes shared mapId accessor', () {
    expect(VexdaCloudMapConfig.mapId, isA<String>());
  });

  test('usesVectorMaps is false when mapId is empty', () {
    expect(VexdaCloudMapConfig.usesVectorMaps, isFalse);
  });

  test('cloud map style import file exists for GCP console', () {
    expect(File('docs/cloud_map_style/vexda_web_dark.json').existsSync(), isTrue);
  });

  test('maps loader exposes vexdaMapsReady and resolves google.maps', () {
    final loader = File('web/vexda_maps_loader.js').readAsStringSync();
    expect(loader, contains('window.vexdaMapsReady'));
    expect(loader, contains('importLibrary(\'maps\')'));
    expect(loader, contains('typeof window.google.maps.Map === \'function\''));
  });

  test('search map waits for Google Maps bootstrap before constructing map', () {
    final searchMap = File(
      'lib/features/search/widgets/search_google_map.dart',
    ).readAsStringSync();
    expect(searchMap, contains('GoogleMapsBootstrap.ensureReady'));
    expect(searchMap, contains('if (_mapsApiReady && !showFailure)'));
  });

  test('admin map waits for Google Maps bootstrap before constructing map', () {
    final adminMap = File(
      'lib/features/admin/widgets/admin_claim_venue_map.dart',
    ).readAsStringSync();
    expect(adminMap, contains('GoogleMapsBootstrap.ensureReady'));
    expect(adminMap, contains('if (!_mapsApiReady)'));
  });
}
