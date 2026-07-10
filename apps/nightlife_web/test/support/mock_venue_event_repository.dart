import 'dart:async';

import 'package:vex_core/vex_core.dart';

final class MockVenueEventRepository implements VenueEventRepository {
  MockVenueEventRepository({
    this.publicEvents = const [],
    this.loadError,
    Stream<DataResult<List<VenueEvent>>>? watchStream,
  }) : _watchStream = watchStream;

  List<VenueEvent> publicEvents;
  VexException? loadError;
  final Stream<DataResult<List<VenueEvent>>>? _watchStream;

  int loadCalls = 0;
  int watchCalls = 0;
  String? lastVenueId;

  @override
  Future<DataResult<List<VenueEvent>>> loadPublicEvents(String venueId) async {
    loadCalls++;
    lastVenueId = venueId;
    if (venueId.trim().isEmpty) {
      return const DataSuccess([]);
    }
    if (loadError != null) {
      return DataFailure(loadError!);
    }
    return DataSuccess(publicEvents);
  }

  @override
  Stream<DataResult<List<VenueEvent>>> watchPublicEvents(String venueId) {
    watchCalls++;
    lastVenueId = venueId;
    if (venueId.trim().isEmpty) {
      return Stream.value(const DataSuccess([]));
    }
    if (_watchStream != null) {
      return _watchStream;
    }
    return Stream.value(DataSuccess(publicEvents));
  }
}

VenueEvent mockVenueEvent({
  required String id,
  required String title,
  String venueId = 'venue-1',
  String description = '',
  DateTime? startDateTime,
  DateTime? endDateTime,
  String category = 'General',
  String imageUrl = '',
  String artist = '',
  bool isActive = true,
  bool featured = false,
  bool isDeleted = false,
}) {
  final start = startDateTime ?? DateTime.now();
  final end = endDateTime ?? start.add(const Duration(hours: 4));
  return VenueEvent(
    id: id,
    venueId: venueId,
    title: title,
    description: description,
    startDateTime: start,
    endDateTime: end,
    category: category,
    imageUrl: imageUrl,
    artist: artist,
    isActive: isActive,
    featured: featured,
    isDeleted: isDeleted,
  );
}
