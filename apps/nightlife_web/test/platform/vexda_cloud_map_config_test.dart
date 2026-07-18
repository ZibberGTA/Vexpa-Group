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

  test('maps loader falls back to raster API when mapId is missing', () {
    final loader = File('web/vexda_maps_loader.js').readAsStringSync();
    expect(loader, isNot(contains("'missing_map_id'")));
    expect(loader, contains('raster Maps JavaScript API fallback'));
    expect(loader, contains("if (hasMapId)"));
  });

  test('search map widget avoids empty mapId when vector maps are disabled', () {
    final searchMap = File(
      'lib/features/search/widgets/search_google_map.dart',
    ).readAsStringSync();
    expect(searchMap, contains('VexdaCloudMapConfig.usesVectorMaps'));
    expect(searchMap, contains('DarkMapStyle.json'));
  });

  test('admin map widget avoids empty mapId when vector maps are disabled', () {
    final adminMap = File(
      'lib/features/admin/widgets/admin_claim_venue_map.dart',
    ).readAsStringSync();
    expect(adminMap, contains('VexdaCloudMapConfig.usesVectorMaps'));
    expect(adminMap, contains('DarkMapStyle.json'));
  });
}
