import '../data/data_result.dart';
import 'venue_event.dart';
import 'venue_event_repository.dart';
import 'venue_event_visibility.dart';

/// Domain service for public venue event reads.
final class VenueEventDataService {
  const VenueEventDataService({required VenueEventRepository repository})
    : _repository = repository;

  final VenueEventRepository _repository;

  Future<DataResult<List<VenueEvent>>> loadPublicEvents(String venueId) async {
    final trimmedId = venueId.trim();
    if (trimmedId.isEmpty) {
      return const DataSuccess([]);
    }

    final result = await _repository.loadPublicEvents(trimmedId);
    return switch (result) {
      DataSuccess(:final value) => DataSuccess(_publicEvents(value)),
      DataFailure(:final error) => DataFailure(error),
    };
  }

  Stream<DataResult<List<VenueEvent>>> watchPublicEvents(String venueId) {
    final trimmedId = venueId.trim();
    if (trimmedId.isEmpty) {
      return Stream.value(const DataSuccess([]));
    }

    return _repository.watchPublicEvents(trimmedId).map((result) {
      return switch (result) {
        DataSuccess(:final value) => DataSuccess(_publicEvents(value)),
        DataFailure(:final error) => DataFailure(error),
      };
    });
  }

  List<VenueEvent> _publicEvents(List<VenueEvent> events, {DateTime? now}) {
    final visible =
        events
            .where((event) => isPublicVisibleVenueEvent(event, now: now))
            .toList()
          ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    return visible;
  }
}
