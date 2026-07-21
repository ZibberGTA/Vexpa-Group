import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_app/core/vexcore/mobile_trail_document_mapper.dart';
import 'package:vex_core/trails/trails.dart';

void main() {
  group('MobileTrailDocumentMapper', () {
    test('preserves name/title aliases and publication fields', () {
      final now = DateTime(2026, 7, 18, 19);
      final snapshot = MobileTrailDocumentMapper.parseTrailDocument('trail-1', {
        'name': 'Name',
        'title': 'Title',
        'description': 'Desc',
        'subtitle': 'Sub',
        'status': 'published',
        'published': true,
        'availabilityStart': Timestamp.fromDate(now),
        'availabilityEnd': Timestamp.fromDate(now.add(const Duration(hours: 4))),
        'stops': [
          {
            'venueId': 'v1',
            'venueName': 'Venue',
            'order': 1,
            'arriveAt': Timestamp.fromDate(now),
            'leaveAt': Timestamp.fromDate(now.add(const Duration(hours: 1))),
          },
        ],
      });

      expect(snapshot, isNotNull);
      expect(snapshot!.name, 'Name');
      expect(snapshot.title, 'Title');
      expect(snapshot.published, isTrue);
      expect(snapshot.stops.first.order, 1);
    });

    test('maps progress currentStop index and stop-state keys', () {
      final snapshot = MobileTrailDocumentMapper.parseProgressDocument({
        'trailId': 'activeTrail',
        'started': true,
        'completed': false,
        'currentStop': 1,
        'checkedInStops': [1],
        'stopStates': {'1': 'checkedIn', '2': 'current'},
        'trailGeneratedAt': Timestamp.fromDate(DateTime(2026, 7, 18, 12)),
      });

      expect(snapshot, isNotNull);
      expect(snapshot!.currentStop, 1);
      expect(snapshot.checkedInStops, {1});
      expect(snapshot.stopStates[1], isA<KnownTrailStopProgressStateSnapshot>());
    });

    test('maps activity action strings exactly', () {
      final snapshot = MobileTrailDocumentMapper.parseActivityDocument('a1', {
        'trailId': 'trail-1',
        'userId': 'user-1',
        'isAnonymous': false,
        'action': 'directions_requested',
        'venueId': 'v1',
        'stopOrder': 2,
        'createdAt': Timestamp.fromDate(DateTime(2026, 7, 18, 20)),
      });

      expect(snapshot?.action, TrailActivityAction.directionsRequested);
    });
  });
}
