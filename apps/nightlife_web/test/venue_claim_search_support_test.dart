import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/features/venue_claims/data/venue_claim_search_support.dart';
import 'package:nightlife_web/features/venue_claims/models/venue_claim.dart';

void main() {
  group('VenueClaimSearchSupport', () {
    test('tokenize splits partial search terms', () {
      expect(VenueClaimSearchSupport.tokenize('red lion cm12'), [
        'red',
        'lion',
        'cm12',
      ]);
    });

    test('isClaimableVenue allows unclaimed venues without owners', () {
      expect(
        VenueClaimSearchSupport.isClaimableVenue({
          'name': 'Red Lion Test Venue',
          'claimStatus': 'unclaimed',
          'isClaimed': false,
        }),
        isTrue,
      );
    });

    test('isClaimableVenue rejects claimed venues', () {
      expect(
        VenueClaimSearchSupport.isClaimableVenue({
          'name': 'Taken Venue',
          'ownerId': 'abc123',
          'claimStatus': 'claimed',
        }),
        isFalse,
      );
    });

    test('matchesQuery supports partial name and postcode tokens', () {
      final venue = VenueClaimSearchResult.fromFirestore(
        'test-red-lion-venue',
        {
          'name': 'Red Lion Test Venue',
          'address': {
            'line': '1 High Street',
            'city': 'Basildon',
            'postcode': 'CM12 9AB',
          },
          'city': 'Basildon',
          'postcode': 'CM12 9AB',
          'category': 'Pub',
          'searchKeywords': ['red', 'lion', 'basildon', 'cm12'],
        },
      );

      expect(
        VenueClaimSearchSupport.matchesQuery(venue, 'red', ['red']),
        isTrue,
      );
      expect(
        VenueClaimSearchSupport.matchesQuery(venue, 'red lion', [
          'red',
          'lion',
        ]),
        isTrue,
      );
      expect(VenueClaimSearchSupport.matchesQuery(venue, 'cm', ['cm']), isTrue);
      expect(
        VenueClaimSearchSupport.matchesQuery(venue, 'basildon', ['basildon']),
        isTrue,
      );
    });

    test('buildSearchKeywords includes venue name tokens', () {
      final keywords = VenueClaimSearchSupport.buildSearchKeywords({
        'name': 'Red Lion Test Venue',
        'city': 'Basildon',
        'postcode': 'CM12 9AB',
        'address': {'line': '1 High Street'},
      });

      expect(keywords, contains('red'));
      expect(keywords, contains('lion'));
      expect(keywords, contains('basildon'));
      expect(keywords, contains('cm12'));
    });
  });
}
