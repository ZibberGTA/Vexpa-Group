import 'package:vex_core/vex_core.dart';

class MockVenueWriteRepository implements VenueWriteRepository {
  MockVenueWriteRepository({
    this.createError,
    this.updateError,
  });

  VexException? createError;
  VexException? updateError;

  int createCalls = 0;
  int updateCalls = 0;
  VenueWritePayload? lastCreatePayload;
  VenueWritePayload? lastUpdatePayload;
  String? lastUpdateVenueId;

  @override
  Future<DataResult<String>> createVenue(VenueWritePayload payload) async {
    createCalls++;
    lastCreatePayload = payload;
    if (createError != null) {
      return DataFailure(createError!);
    }
    return const DataSuccess('venue-1');
  }

  @override
  Future<DataResult<void>> updateVenue({
    required String venueId,
    required VenueWritePayload payload,
  }) async {
    updateCalls++;
    lastUpdateVenueId = venueId;
    lastUpdatePayload = payload;
    if (updateError != null) {
      return DataFailure(updateError!);
    }
    return const DataSuccess(null);
  }
}
