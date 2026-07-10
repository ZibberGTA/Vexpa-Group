import 'dart:async';

import 'package:vex_core/vex_core.dart';

final class MockVenueDealRepository implements VenueDealRepository {
  MockVenueDealRepository({
    this.publicDeals = const [],
    this.loadError,
    Stream<DataResult<List<VenueDeal>>>? watchStream,
  }) : _watchStream = watchStream;

  List<VenueDeal> publicDeals;
  VexException? loadError;
  final Stream<DataResult<List<VenueDeal>>>? _watchStream;

  int loadCalls = 0;
  int watchCalls = 0;
  String? lastVenueId;

  @override
  Future<DataResult<List<VenueDeal>>> loadPublicDeals(String venueId) async {
    loadCalls++;
    lastVenueId = venueId;
    if (venueId.trim().isEmpty) {
      return const DataSuccess([]);
    }
    if (loadError != null) {
      return DataFailure(loadError!);
    }
    return DataSuccess(publicDeals);
  }

  @override
  Stream<DataResult<List<VenueDeal>>> watchPublicDeals(String venueId) {
    watchCalls++;
    lastVenueId = venueId;
    if (venueId.trim().isEmpty) {
      return Stream.value(const DataSuccess([]));
    }
    if (_watchStream != null) {
      return _watchStream;
    }
    return Stream.value(DataSuccess(publicDeals));
  }
}

VenueDeal mockVenueDeal({
  required String id,
  required String title,
  String venueId = 'venue-1',
  String description = '',
  DateTime? startDateTime,
  DateTime? endDateTime,
  bool isActive = true,
  bool featured = false,
  bool isDeleted = false,
}) {
  return VenueDeal(
    id: id,
    venueId: venueId,
    title: title,
    description: description,
    dealType: 'other',
    value: '10% off',
    startTime: '',
    endTime: '',
    startDateTime: startDateTime,
    endDateTime: endDateTime,
    isActive: isActive,
    featured: featured,
    isDeleted: isDeleted,
  );
}
