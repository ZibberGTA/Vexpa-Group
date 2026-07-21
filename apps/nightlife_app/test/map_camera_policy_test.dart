import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nightlife_app/features/map/map_camera_policy.dart';

void main() {
  const bootstrap = LatLng(51.5074, -0.1278);
  const userView = LatLng(53.4808, -2.2426);
  const resultTarget = LatLng(55.9533, -3.1883);

  group('MapCameraPolicy', () {
    test('initial load uses bootstrap only when map is not created', () {
      final policy = MapCameraPolicy(bootstrapTarget: bootstrap);

      expect(policy.initialCameraPosition.target, bootstrap);
      expect(policy.mapCreated, isFalse);
    });

    test('typing search does not change camera after map is created', () {
      final policy = MapCameraPolicy(bootstrapTarget: bootstrap)
        ..markMapCreated()
        ..recordCamera(userView, 14.5);

      policy.onSearchChanged();

      expect(policy.initialCameraPosition.target, userView);
      expect(policy.initialCameraPosition.zoom, 14.5);
      expect(policy.shouldResetToBootstrapOnSearchRefresh, isFalse);
    });

    test('clearing search does not change camera after map is created', () {
      final policy = MapCameraPolicy(bootstrapTarget: bootstrap)
        ..markMapCreated()
        ..recordCamera(userView, 12);

      policy.onSearchCleared();

      expect(policy.initialCameraPosition.target, userView);
      expect(policy.initialCameraPosition.zoom, 12);
    });

    test('selecting a result may move camera when target differs', () {
      final policy = MapCameraPolicy(bootstrapTarget: bootstrap)
        ..markMapCreated()
        ..recordCamera(userView, 13);

      expect(policy.shouldAnimateToSelection(resultTarget), isTrue);
    });
  });
}
