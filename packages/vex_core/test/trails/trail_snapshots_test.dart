import 'package:test/test.dart';
import 'package:vex_core/trails/trail_snapshots.dart';

/// Test-only fixture mirroring mobile `DrinkSpotTrailModel.fromDoc` field mapping.
TrailSnapshot mapTrailFixture(Map<String, dynamic> data, {required String id}) {
  final stopsRaw = data['stops'];
  final stops = stopsRaw is List
      ? stopsRaw
            .whereType<Map>()
            .map((item) => mapStopFixture(Map<String, dynamic>.from(item)))
            .toList()
      : <TrailStopSnapshot>[];
  stops.sort((a, b) => a.order.compareTo(b.order));

  final availabilityStart =
      readDateTime(data['availabilityStart']) ??
      readDateTime(data['startTime']) ??
      DateTime(2026, 1, 1, 19);
  final availabilityEnd =
      readDateTime(data['availabilityEnd']) ??
      readDateTime(data['endTime']) ??
      DateTime(2026, 1, 1, 23, 59, 59);

  return TrailSnapshot(
    trailId: id,
    name: (data['name'] ?? data['title'] ?? "Tonight's Trail").toString(),
    title: (data['title'] ?? data['name'] ?? "Tonight's Trail").toString(),
    description:
        (data['description'] ??
                data['subtitle'] ??
                'Generated from live DrinkSpot activity')
            .toString(),
    subtitle: (data['subtitle'] ?? data['description'] ?? '').toString(),
    bannerImageUrl: (data['bannerImageUrl'] ?? '').toString(),
    status: TrailPersistenceCodec.parseStatus(data['status']?.toString()),
    published: data['published'] == true,
    area: (data['area'] ?? '').toString(),
    availabilityStart: availabilityStart,
    availabilityEnd: availabilityEnd,
    startTime: readDateTime(data['startTime']) ?? availabilityStart,
    endTime: readDateTime(data['endTime']) ?? availabilityEnd,
    estimatedDurationMinutes:
        (data['estimatedDurationMinutes'] as num?)?.toInt() ??
        availabilityEnd.difference(availabilityStart).inMinutes,
    estimatedWalkingDistance:
        (data['estimatedWalkingDistance'] as num?)?.toInt() ?? 0,
    averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0,
    venueCount: (data['venueCount'] as num?)?.toInt() ?? stops.length,
    trailType: TrailPersistenceCodec.parseType(data['trailType']?.toString()),
    generatedAt: readDateTime(data['generatedAt']) ?? DateTime(2026, 1, 1),
    stops: stops,
    createdAt: readDateTime(data['createdAt']),
    updatedAt: readDateTime(data['updatedAt']),
    publishedAt: readDateTime(data['publishedAt']),
    unpublishedAt: readDateTime(data['unpublishedAt']),
    archivedAt: readDateTime(data['archivedAt']),
    disabledAt: readDateTime(data['disabledAt']),
    searchTerms: readStringList(data['searchTerms']),
  );
}

TrailStopSnapshot mapStopFixture(Map<String, dynamic> map) {
  return TrailStopSnapshot(
    venueId: (map['venueId'] ?? '').toString(),
    venueName: (map['venueName'] ?? '').toString(),
    address: (map['address'] ?? '').toString(),
    bannerImageUrl: (map['bannerImageUrl'] ?? '').toString(),
    logoUrl: (map['logoUrl'] ?? '').toString(),
    order: (map['order'] as num?)?.toInt() ?? 0,
    score: (map['score'] as num?)?.toInt() ?? 0,
    arriveAt: readDateTime(map['arriveAt']) ?? DateTime(2026, 1, 1, 20),
    leaveAt: readDateTime(map['leaveAt']) ?? DateTime(2026, 1, 1, 21),
    discountLabel: (map['discountLabel'] ?? '').toString(),
  );
}

TrailProgressSnapshot mapProgressFixture(Map<String, dynamic> data) {
  final rawCheckedInStops = data['checkedInStops'];
  final checkedInStops = rawCheckedInStops is List
      ? rawCheckedInStops
            .map((item) => (item as num?)?.toInt())
            .whereType<int>()
            .toSet()
      : <int>{};

  final stopStates = <int, TrailStopProgressStateSnapshot>{};
  final rawStopStates = data['stopStates'];
  if (rawStopStates is Map) {
    rawStopStates.forEach((key, value) {
      final order = int.tryParse(key.toString());
      if (order == null) return;
      stopStates[order] = TrailPersistenceCodec.parseStopProgressState(
        value?.toString(),
      );
    });
  }

  return TrailProgressSnapshot(
    trailId: (data['trailId'] ?? '').toString(),
    started: data['started'] == true,
    completed: data['completed'] == true,
    currentStop: (data['currentStop'] as num?)?.toInt() ?? 0,
    checkedInStops: checkedInStops,
    stopStates: stopStates,
    trailGeneratedAt: readDateTime(data['trailGeneratedAt']),
    startedAt: readDateTime(data['startedAt']),
    updatedAt: readDateTime(data['updatedAt']),
    completedAt: readDateTime(data['completedAt']),
    lastCheckedInVenueId: data['lastCheckedInVenueId']?.toString(),
    lastCheckedInStopOrder: (data['lastCheckedInStopOrder'] as num?)?.toInt(),
  );
}

DateTime? readDateTime(Object? value) {
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return null;
}

List<String> readStringList(Object? value) {
  if (value is! Iterable) return const [];
  return value.map((item) => item.toString()).toList();
}

void main() {
  group('TrailPersistenceCodec', () {
    test('parses known trail status values', () {
      expect(
        TrailPersistenceCodec.parseStatus('published'),
        isA<KnownTrailStatusSnapshot>().having(
          (s) => s.value,
          'value',
          TrailStatusValue.published,
        ),
      );
    });

    test('preserves unknown trail status without coercion', () {
      final parsed = TrailPersistenceCodec.parseStatus('experimental');
      expect(parsed, isA<UnknownTrailStatusSnapshot>());
      expect((parsed as UnknownTrailStatusSnapshot).rawValue, 'experimental');
    });

    test('reports missing trail status', () {
      expect(
        TrailPersistenceCodec.parseStatus(null),
        isA<MissingTrailStatusSnapshot>(),
      );
    });

    test('parses known trail type values', () {
      expect(
        TrailPersistenceCodec.parseType('generated'),
        isA<KnownTrailTypeSnapshot>().having(
          (s) => s.value,
          'value',
          TrailTypeValue.generated,
        ),
      );
    });

    test('preserves unknown trail type', () {
      final parsed = TrailPersistenceCodec.parseType('custom');
      expect(parsed, isA<UnknownTrailTypeSnapshot>());
    });

    test('parses stop progress states including camelCase checkedIn', () {
      expect(
        TrailPersistenceCodec.parseStopProgressState('checkedIn'),
        isA<KnownTrailStopProgressStateSnapshot>().having(
          (s) => s.value,
          'value',
          TrailStopProgressStateValue.checkedIn,
        ),
      );
    });

    test('preserves unknown stop progress state', () {
      final parsed = TrailPersistenceCodec.parseStopProgressState('paused');
      expect(parsed, isA<UnknownTrailStopProgressStateSnapshot>());
    });
  });

  group('Trail snapshot construction from mobile-shaped fixtures', () {
    test('maps trail document with alias fields and embedded stops', () {
      final arriveAt = DateTime(2026, 7, 18, 20);
      final leaveAt = DateTime(2026, 7, 18, 21, 30);
      final generatedAt = DateTime(2026, 7, 18, 18);

      final snapshot = mapTrailFixture({
        'name': 'Pub Crawl',
        'title': 'Pub Crawl',
        'description': 'A fun route',
        'subtitle': 'A fun route',
        'bannerImageUrl': 'https://example.com/banner.jpg',
        'status': 'published',
        'published': true,
        'area': 'City Centre',
        'availabilityStart': generatedAt.millisecondsSinceEpoch,
        'availabilityEnd': leaveAt.millisecondsSinceEpoch,
        'startTime': generatedAt.millisecondsSinceEpoch,
        'endTime': leaveAt.millisecondsSinceEpoch,
        'estimatedDurationMinutes': 90,
        'estimatedWalkingDistance': 1200,
        'averageRating': 4.5,
        'venueCount': 1,
        'trailType': 'curated',
        'generatedAt': generatedAt.millisecondsSinceEpoch,
        'searchTerms': ['pub', 'crawl'],
        'stops': [
          {
            'venueId': 'v1',
            'venueName': 'The Fox',
            'address': '1 High St',
            'bannerImageUrl': 'https://example.com/fox.jpg',
            'logoUrl': 'https://example.com/fox-logo.jpg',
            'order': 1,
            'score': 42,
            'arriveAt': arriveAt.millisecondsSinceEpoch,
            'leaveAt': leaveAt.millisecondsSinceEpoch,
            'discountLabel': '2-for-1',
          },
        ],
      }, id: 'trail-1');

      expect(snapshot.trailId, 'trail-1');
      expect(snapshot.name, 'Pub Crawl');
      expect(snapshot.title, 'Pub Crawl');
      expect(snapshot.published, isTrue);
      expect(snapshot.status, isA<KnownTrailStatusSnapshot>());
      expect(snapshot.stops, hasLength(1));
      expect(snapshot.stops.first.venueId, 'v1');
      expect(snapshot.stops.first.discountLabel, '2-for-1');
      expect(snapshot.searchTerms, ['pub', 'crawl']);
      expect(snapshot.generatedAt, generatedAt);
    });

    test(
      'falls back to title/subtitle/endTime aliases like mobile fromDoc',
      () {
        final start = DateTime(2026, 3, 1, 19);
        final end = DateTime(2026, 3, 1, 23);

        final snapshot = mapTrailFixture({
          'title': 'Alias Title',
          'subtitle': 'Alias Subtitle',
          'endTime': end.millisecondsSinceEpoch,
          'startTime': start.millisecondsSinceEpoch,
          'status': 'draft',
          'published': false,
          'trailType': 'curated',
        }, id: 'alias-trail');

        expect(snapshot.name, 'Alias Title');
        expect(snapshot.description, 'Alias Subtitle');
        expect(snapshot.availabilityStart, start);
        expect(snapshot.availabilityEnd, end);
      },
    );

    test('handles optional lifecycle timestamps', () {
      final publishedAt = DateTime(2026, 5, 1, 12);
      final snapshot = mapTrailFixture({
        'name': 'Lifecycle',
        'status': 'archived',
        'published': false,
        'publishedAt': publishedAt.millisecondsSinceEpoch,
        'archivedAt': publishedAt.millisecondsSinceEpoch,
        'disabledAt': publishedAt.millisecondsSinceEpoch,
      }, id: 'lifecycle');

      expect(snapshot.publishedAt, publishedAt);
      expect(snapshot.archivedAt, publishedAt);
      expect(snapshot.disabledAt, publishedAt);
    });
  });

  group('Trail progress snapshot construction', () {
    test('maps progress fields and stopStates keys as order integers', () {
      final generatedAt = DateTime(2026, 6, 1, 18, 30);
      final startedAt = DateTime(2026, 6, 1, 19);

      final snapshot = mapProgressFixture({
        'trailId': 'activeTrail',
        'trailGeneratedAt': generatedAt.millisecondsSinceEpoch,
        'started': true,
        'completed': false,
        'currentStop': 1,
        'checkedInStops': [1],
        'stopStates': {'1': 'checkedIn', '2': 'current'},
        'startedAt': startedAt.millisecondsSinceEpoch,
        'lastCheckedInVenueId': 'v1',
        'lastCheckedInStopOrder': 1,
      });

      expect(snapshot.trailId, 'activeTrail');
      expect(snapshot.checkedInStops, {1});
      expect(
        snapshot.stopStates[1],
        isA<KnownTrailStopProgressStateSnapshot>(),
      );
      expect(
        snapshot.stopStates[2],
        isA<KnownTrailStopProgressStateSnapshot>(),
      );
      expect(snapshot.trailGeneratedAt, generatedAt);
      expect(snapshot.lastCheckedInVenueId, 'v1');
    });
  });

  group('Trail activity snapshot construction', () {
    test('stores append-only activity fields', () {
      final createdAt = DateTime(2026, 6, 1, 20, 15);
      final snapshot = TrailActivitySnapshot(
        activityId: 'act-1',
        trailId: 'trail-1',
        userId: 'user-1',
        isAnonymous: false,
        action: TrailActivityAction.arrived,
        createdAt: DateTime(2026, 6, 1, 20, 15),
        venueId: 'v1',
        stopOrder: 2,
      );

      expect(snapshot.action, TrailActivityAction.arrived);
      expect(snapshot.createdAt, createdAt);
      expect(snapshot.stopOrder, 2);
    });
  });

  group('DateTime round-trip through fixture input', () {
    test('preserves millisecond precision', () {
      final original = DateTime(2026, 7, 18, 20, 30, 45, 123);
      final snapshot = mapTrailFixture({
        'name': 'Time',
        'generatedAt': original.millisecondsSinceEpoch,
      }, id: 'time-trail');

      expect(snapshot.generatedAt, original);
    });
  });

  group('Immutable collections', () {
    test(
      'TrailSnapshot holds unmodifiable stop list when constructed const',
      () {
        final stop = TrailStopSnapshot(
          venueId: 'v1',
          venueName: 'Venue',
          address: 'Addr',
          bannerImageUrl: '',
          logoUrl: '',
          order: 1,
          score: 0,
          arriveAt: DateTime(2026, 1, 1, 20),
          leaveAt: DateTime(2026, 1, 1, 21),
        );
        final snapshot = TrailSnapshot(
          trailId: 't1',
          name: 'Trail',
          title: 'Trail',
          description: 'Desc',
          subtitle: 'Desc',
          bannerImageUrl: '',
          status: KnownTrailStatusSnapshot(TrailStatusValue.draft),
          published: false,
          area: '',
          availabilityStart: DateTime(2026, 1, 1, 19),
          availabilityEnd: DateTime(2026, 1, 1, 23),
          startTime: DateTime(2026, 1, 1, 19),
          endTime: DateTime(2026, 1, 1, 23),
          estimatedDurationMinutes: 240,
          estimatedWalkingDistance: 0,
          averageRating: 0,
          venueCount: 1,
          trailType: KnownTrailTypeSnapshot(TrailTypeValue.curated),
          generatedAt: DateTime(2026, 1, 1, 18),
          stops: [stop],
        );

        expect(snapshot.stops, hasLength(1));
        expect(snapshot.stops.first.venueId, 'v1');
      },
    );
  });
}
