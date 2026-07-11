import '../data/data_result.dart';

/// Firebase-independent geo coordinates for venue writes.
final class VenueWriteCoordinates {
  const VenueWriteCoordinates({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

/// Prepared venue write payload for create and update operations.
final class VenueWritePayload {
  const VenueWritePayload({
    required this.fields,
    this.coordinates,
    this.serverTimestampFields = const [],
  });

  final Map<String, Object?> fields;
  final VenueWriteCoordinates? coordinates;
  final List<String> serverTimestampFields;
}

/// Write access for owner venue create and update flows.
abstract interface class VenueWriteRepository {
  Future<DataResult<String>> createVenue(VenueWritePayload payload);

  Future<DataResult<void>> updateVenue({
    required String venueId,
    required VenueWritePayload payload,
  });
}
