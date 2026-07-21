import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_app/features/discover/models/discover_models.dart';
import 'package:nightlife_app/features/discover/services/discover_filter_service.dart';

void main() {
  group('DiscoverFilterService.publicVenueDocs', () {
    QueryDocumentSnapshot<Map<String, dynamic>> doc({
      required String id,
      required Map<String, dynamic> data,
    }) {
      return _FakeVenueDoc(id: id, data: data);
    }

    test('includes eligible public venues with coordinates', () {
      final eligible = DiscoverFilterService.publicVenueDocs(
        docs: [
          doc(
            id: 'v1',
            data: {
              'name': 'Alpha',
              'location': const GeoPoint(51.5, -0.12),
              'searchablePublic': true,
            },
          ),
          doc(
            id: 'hidden',
            data: {
              'name': 'Hidden',
              'location': const GeoPoint(51.51, -0.13),
              'isHidden': true,
            },
          ),
          doc(id: 'no-location', data: {'name': 'No location'}),
        ],
      );

      expect(eligible.map((entry) => entry.id).toList(), ['v1']);
    });
  });

  group('DiscoverFilter quick-result constants', () {
    test('uses a named 10-result limit', () {
      expect(DiscoverFilter.discoverQuickResultLimit, 10);
    });

    test('uses closest headings and near-you empty states', () {
      expect(DiscoverFilter.deals.resultsHeaderTitle, 'Closest deals');
      expect(DiscoverFilter.events.resultsHeaderTitle, 'Closest events');
      expect(DiscoverFilter.venues.resultsHeaderTitle, 'Closest venues');
      expect(
        DiscoverFilter.deals.emptyMessage,
        'No active deals were found near you.',
      );
      expect(
        DiscoverFilter.events.emptyMessage,
        'No upcoming events were found near you.',
      );
      expect(
        DiscoverFilter.venues.emptyMessage,
        'No venues were found near your location.',
      );
    });
  });
}

class _FakeVenueDoc extends Fake
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _FakeVenueDoc({required this.id, required Map<String, dynamic> data})
    : _data = data;

  @override
  final String id;

  final Map<String, dynamic> _data;

  @override
  Map<String, dynamic> data() => _data;
}
