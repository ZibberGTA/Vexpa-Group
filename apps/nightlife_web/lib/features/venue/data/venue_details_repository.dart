import 'package:flutter/foundation.dart';
import 'package:vex_core/vex_core.dart';

import '../../../core/vexcore/vex_venue_mapper.dart';
import '../../../core/vexcore/web_vexcore.dart';
import '../models/venue_details_view.dart';
import 'venue_details_mapper.dart';

/// Loads a public venue profile through VexCore for the details page.
class VenueDetailsRepository {
  VenueDetailsRepository({VenueDataService? venueDataService})
    : _venueDataService = venueDataService ?? WebVexCore.venueDataService;

  final VenueDataService _venueDataService;

  Future<VenueDetailsView?> loadVenue(String venueId) async {
    final trimmedId = venueId.trim();
    if (trimmedId.isEmpty) return null;

    try {
      final result = await _venueDataService.loadPublicVenue(trimmedId);
      return switch (result) {
        DataSuccess(:final value) => _mapVenue(value),
        DataFailure(:final error) => throw error,
      };
    } on Object catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[VenueDetailsRepository] Failed to load venue: $error');
        debugPrint('$stackTrace');
      }
      rethrow;
    }
  }

  /// Live venue stream for public profile — logo/banner update without reload.
  Stream<VenueDetailsView?> watchVenue(String venueId) {
    final trimmedId = venueId.trim();
    if (trimmedId.isEmpty) return Stream.value(null);

    return _venueDataService.watchPublicVenue(trimmedId).map((result) {
      return switch (result) {
        DataSuccess(:final value) => _mapVenue(value),
        DataFailure(:final error) => throw error,
      };
    });
  }

  VenueDetailsView? _mapVenue(Venue? venue) {
    if (venue == null) return null;
    final model = venueModelFromVexVenue(venue);
    return VenueDetailsMapper.fromVenueModel(model);
  }
}
