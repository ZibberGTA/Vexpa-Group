import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_app/core/utils/public_venue_visibility.dart';
import 'package:nightlife_app/features/search/models/search_outcome.dart';

void main() {
  group('PublicVenueVisibility', () {
    test('accepts searchable public active venue', () {
      expect(
        PublicVenueVisibility.isPublicMap({
          'isDeleted': false,
          'searchablePublic': true,
          'isHidden': false,
          'status': 'active',
        }),
        isTrue,
      );
    });

    test('rejects hidden venue', () {
      expect(
        PublicVenueVisibility.isPublicMap({
          'isDeleted': false,
          'searchablePublic': false,
          'isHidden': true,
          'status': 'hidden',
        }),
        isFalse,
      );
    });
  });

  group('SearchOutcome', () {
    test('success with results', () {
      final outcome = SearchOutcome.success([
        {'venueId': 'v1'},
      ]);
      expect(outcome.status, SearchOutcomeStatus.success);
      expect(outcome.results, isNotEmpty);
    });

    test('empty success', () {
      final outcome = SearchOutcome.success([]);
      expect(outcome.status, SearchOutcomeStatus.empty);
    });

    test('failure states are not empty-success', () {
      const outcome = SearchOutcome.failure(SearchOutcomeStatus.loadFailed);
      expect(outcome.isLoadingFailure, isTrue);
      expect(outcome.results, isEmpty);
    });
  });
}
