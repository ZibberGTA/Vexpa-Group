import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/features/venue_claims/data/venue_claim_repository.dart';
import 'package:nightlife_web/features/venue_claims/models/venue_claim.dart';
import 'package:vex_engines/claim/domain/claim_status.dart';

void main() {
  group('VenueClaimRepository claim engine delegation', () {
    test('scoreClaim delegates to Claim Engine scorer', () {
      final repository = VenueClaimRepository();
      final venue = VenueClaimSearchResult.fromFirestore('venue-1', {
        'name': 'Red Lion',
        'website': 'https://redlion.example',
        'phone': '01234567890',
      });

      final score = repository.scoreClaim(
        venue: venue,
        evidence: const VenueClaimEvidence(
          businessEmail: 'owner@redlion.example',
          website: 'https://redlion.example',
          phone: '01234567890',
          companyRegistration: '12345678',
          notes: 'Additional verification notes for the venue location.',
        ),
      );

      expect(score.score, greaterThanOrEqualTo(75));
      expect(score.autoApproved, isTrue);
    });

    test('rejectClaim validates through Claim Engine before callable', () async {
      final repository = VenueClaimRepository();

      await expectLater(
        repository.rejectClaim(
          claimId: 'claim-1',
          reviewerUid: 'admin-1',
          notes: '',
          currentStatus: ClaimStatus.pendingReview,
        ),
        throwsA(
          isA<VenueClaimBackendException>().having(
            (error) => error.message,
            'message',
            'Add review notes before continuing.',
          ),
        ),
      );
    });

    test('approveClaim validates invalid transitions before callable', () async {
      final repository = VenueClaimRepository();

      await expectLater(
        repository.approveClaim(
          claimId: 'claim-1',
          reviewerUid: 'admin-1',
          currentStatus: ClaimStatus.rejected,
        ),
        throwsA(
          isA<VenueClaimBackendException>().having(
            (error) => error.message,
            'message',
            'This claim cannot move to that status yet.',
          ),
        ),
      );
    });
  });
}
