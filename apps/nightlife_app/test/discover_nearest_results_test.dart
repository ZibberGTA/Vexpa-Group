import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_app/features/discover/models/discover_models.dart';
import 'package:nightlife_app/features/discover/utils/discover_nearest_results.dart';

void main() {
  group('DiscoverNearestResults', () {
    DiscoverVenueResult result({
      required String id,
      required String name,
      double? distanceMeters,
      DateTime? eventStart,
    }) {
      return DiscoverVenueResult(
        venueId: id,
        venueName: name,
        venueData: const {},
        distanceMeters: distanceMeters,
        eventStart: eventStart,
      );
    }

    test('limit caps results at discoverQuickResultLimit', () {
      final results = List.generate(
        14,
        (index) => result(
          id: 'v$index',
          name: 'Venue $index',
          distanceMeters: index * 100,
        ),
      );

      final limited = DiscoverNearestResults.limit(results);
      expect(limited.length, DiscoverFilter.discoverQuickResultLimit);
      expect(limited.first.venueId, 'v0');
      expect(limited.last.venueId, 'v9');
    });

    test('sorts nearest-first with deterministic name tie-break', () {
      final results = [
        result(id: 'b', name: 'Beta', distanceMeters: 500),
        result(id: 'a', name: 'Alpha', distanceMeters: 500),
        result(id: 'c', name: 'Charlie', distanceMeters: 100),
      ]..sort(DiscoverNearestResults.compareByDistanceThenName);

      expect(results.map((r) => r.venueId).toList(), ['c', 'a', 'b']);
    });

    test('events sort by distance then event time then name', () {
      final results = [
        result(
          id: 'v2',
          name: 'Two',
          distanceMeters: 200,
          eventStart: DateTime(2026, 7, 20),
        ),
        result(
          id: 'v1',
          name: 'One',
          distanceMeters: 200,
          eventStart: DateTime(2026, 7, 15),
        ),
        result(
          id: 'v3',
          name: 'Three',
          distanceMeters: 50,
          eventStart: DateTime(2026, 8, 1),
        ),
      ]..sort(DiscoverNearestResults.compareByDistanceThenEventThenName);

      expect(results.map((r) => r.venueId).toList(), ['v3', 'v1', 'v2']);
    });

    test('excludes venues without distance from sorted lists safely', () {
      final results = [
        result(id: 'near', name: 'Near', distanceMeters: 100),
        result(id: 'far', name: 'Far', distanceMeters: null),
      ]..sort(DiscoverNearestResults.compareByDistanceThenName);

      expect(results.first.venueId, 'near');
      expect(results.last.distanceMeters, isNull);
    });
  });
}
