import '../data/data_result.dart';
import 'venue.dart';
import 'venue_repository.dart';

/// Domain service for public venue discovery reads.
final class VenueDataService {
  const VenueDataService({required VenueRepository repository})
    : _repository = repository;

  final VenueRepository _repository;

  Future<DataResult<VenueCatalog>> loadDiscoveryCatalog() async {
    final result = await _repository.loadPublicVenues();
    return switch (result) {
      DataSuccess(:final value) => DataSuccess(_sortedCatalog(value)),
      DataFailure(:final error) => DataFailure(error),
    };
  }

  Stream<DataResult<VenueCatalog>> watchDiscoveryCatalog() {
    return _repository.watchPublicVenues().map((result) {
      return switch (result) {
        DataSuccess(:final value) => DataSuccess(_sortedCatalog(value)),
        DataFailure(:final error) => DataFailure(error),
      };
    });
  }

  Future<DataResult<VenueSearchMatch>> searchDiscoveryVenues({
    required List<String> terms,
  }) async {
    final normalized = terms
        .map((term) => term.trim().toLowerCase())
        .where((term) => term.isNotEmpty)
        .toSet()
        .toList();
    if (normalized.isEmpty) {
      return const DataSuccess(VenueSearchMatch(venueIds: {}));
    }

    final result = await _repository.searchPublicVenuesByTerms(
      terms: normalized,
    );
    return switch (result) {
      DataSuccess(:final value) => DataSuccess(value),
      DataFailure(:final error) => DataFailure(error),
    };
  }

  Future<DataResult<Venue?>> loadPublicVenue(String venueId) async {
    final trimmedId = venueId.trim();
    if (trimmedId.isEmpty) {
      return const DataSuccess(null);
    }

    return _repository.findById(trimmedId);
  }

  Stream<DataResult<Venue?>> watchPublicVenue(String venueId) {
    final trimmedId = venueId.trim();
    if (trimmedId.isEmpty) {
      return Stream.value(const DataSuccess(null));
    }

    return _repository.watchById(trimmedId);
  }

  VenueCatalog _sortedCatalog(List<Venue> venues) {
    final sorted = List<Venue>.from(venues)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return VenueCatalog(venues: sorted);
  }
}
