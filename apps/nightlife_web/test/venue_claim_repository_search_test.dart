import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/features/venue_claims/data/venue_claim_repository.dart';
import 'package:nightlife_web/features/venue_claims/models/venue_claim.dart';
import 'package:vex_engines/claim/application/claim_search_service.dart';
import 'package:vex_engines/claim/domain/claim_status.dart';

void main() {
  group('VenueClaimRepository search delegation', () {
    test('uses Claim Engine search limits instead of local constants', () {
      expect(ClaimSearchLimits.maxResults, 40);
      expect(ClaimSearchLimits.fallbackBatchSize, 150);
      expect(ClaimSearchLimits.fallbackMaxDocs, 900);
    });

    test('repository accepts injected ClaimSearchService', () {
      const customSearch = ClaimSearchService();
      final repository = VenueClaimRepository(searchService: customSearch);
      expect(repository, isNotNull);
    });
  });

  group('VenueClaimRepository review delegation', () {
    test('rejectClaim respects reviewerCanApprove from caller', () async {
      final repository = VenueClaimRepository();

      await expectLater(
        repository.rejectClaim(
          claimId: 'claim-1',
          reviewerUid: 'admin-1',
          notes: 'Needs more proof',
          currentStatus: ClaimStatus.pendingReview,
          reviewerCanApprove: false,
        ),
        throwsA(
          isA<VenueClaimBackendException>().having(
            (error) => error.message,
            'message',
            'You do not have permission to review claims.',
          ),
        ),
      );
    });
  });

  group('VenueClaim presentation delegation', () {
    test('search result labels delegate to Claim Engine', () {
      final result = VenueClaimSearchResult.fromFirestore('venue-1', {
        'name': 'Red Lion',
        'claimStatus': 'pending_review',
      });

      expect(result.claimStatusLabel, 'Pending review');
      expect(result.displayAddress, 'Address not listed');
    });

    test('claim list entry maps for admin summaries', () {
      final claim = VenueClaim.fromFirestore('claim-1', {
        'venueId': 'venue-1',
        'claimantUid': 'user-1',
        'status': 'pending_review',
        'submittedEvidence': {'businessEmail': 'owner@example.com'},
      });

      expect(claim.toClaimListEntry().status, ClaimStatus.pendingReview);
      expect(claim.toClaimListEntry().id, 'claim-1');
    });
  });
}
