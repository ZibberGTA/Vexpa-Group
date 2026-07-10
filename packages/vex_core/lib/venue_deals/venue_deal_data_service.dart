import '../data/data_result.dart';
import 'venue_deal.dart';
import 'venue_deal_repository.dart';
import 'venue_deal_visibility.dart';

/// Domain service for public venue deal reads.
final class VenueDealDataService {
  const VenueDealDataService({required VenueDealRepository repository})
    : _repository = repository;

  final VenueDealRepository _repository;

  Future<DataResult<List<VenueDeal>>> loadPublicDeals(String venueId) async {
    final trimmedId = venueId.trim();
    if (trimmedId.isEmpty) {
      return const DataSuccess([]);
    }

    final result = await _repository.loadPublicDeals(trimmedId);
    return switch (result) {
      DataSuccess(:final value) => DataSuccess(_publicDeals(value)),
      DataFailure(:final error) => DataFailure(error),
    };
  }

  Stream<DataResult<List<VenueDeal>>> watchPublicDeals(String venueId) {
    final trimmedId = venueId.trim();
    if (trimmedId.isEmpty) {
      return Stream.value(const DataSuccess([]));
    }

    return _repository.watchPublicDeals(trimmedId).map((result) {
      return switch (result) {
        DataSuccess(:final value) => DataSuccess(_publicDeals(value)),
        DataFailure(:final error) => DataFailure(error),
      };
    });
  }

  List<VenueDeal> _publicDeals(List<VenueDeal> deals, {DateTime? now}) {
    final visible =
        deals.where((deal) => isPublicVisibleVenueDeal(deal, now: now)).toList()
          ..sort((a, b) {
            final aUpcoming = isPublicUpcomingVenueDeal(a, now: now);
            final bUpcoming = isPublicUpcomingVenueDeal(b, now: now);
            if (aUpcoming != bUpcoming) return aUpcoming ? 1 : -1;
            return (a.startDateTime ?? DateTime(2100)).compareTo(
              b.startDateTime ?? DateTime(2100),
            );
          });
    return visible;
  }
}
