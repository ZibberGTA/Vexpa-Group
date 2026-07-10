import 'package:test/test.dart';
import 'package:vex_engines/claim/application/claim_audit_preparation.dart';
import 'package:vex_engines/claim/application/claim_confidence_scorer.dart';
import 'package:vex_engines/claim/application/claim_evidence_validator.dart';
import 'package:vex_engines/claim/application/claim_review_service.dart';
import 'package:vex_engines/claim/application/claim_submission_service.dart';
import 'package:vex_engines/claim/domain/claim_evidence.dart';
import 'package:vex_engines/claim/domain/claim_result.dart';
import 'package:vex_engines/claim/domain/claim_search_candidate.dart';
import 'package:vex_engines/claim/domain/claim_status.dart';
import 'package:vex_engines/claim/shared/claim_search_support.dart';

final class _SearchVenue implements ClaimSearchCandidate {
  const _SearchVenue({
    this.website = 'https://redlion.example',
    this.phone = '01234567890',
  });

  @override
  final String venueId = 'venue-1';

  @override
  final String name = 'Red Lion';

  @override
  final String address = '1 High Street';

  @override
  final String city = 'Basildon';

  @override
  final String postcode = 'CM12 9AB';

  @override
  final String category = 'Pub';

  @override
  final String website;

  @override
  final String phone;

  @override
  final Map<String, dynamic> rawData = const {
    'description': 'Neighbourhood pub',
  };
}

void main() {
  const submissionService = ClaimSubmissionService();
  const reviewService = ClaimReviewService();
  const evidenceValidator = ClaimEvidenceValidator();
  const scorer = ClaimConfidenceScorer();

  group('ClaimSubmissionService', () {
    test('prepares valid claim submission payload', () {
      const evidence = ClaimEvidence(
        businessEmail: 'owner@redlion.example',
        website: 'https://redlion.example',
        phone: '01234567890',
        companyRegistration: '12345678',
        notes: 'I manage bookings and payroll for this venue daily.',
      );

      final result = submissionService.prepareSubmission(
        venueId: 'venue-1',
        claimantUid: 'user-1',
        venue: _SearchVenue(),
        evidence: evidence,
        claimantActive: true,
        existingStatusesForVenue: const [],
      );

      expect(result, isA<ClaimSuccess<ClaimSubmissionPayload>>());
      final payload = (result as ClaimSuccess<ClaimSubmissionPayload>).value;
      expect(payload.venueId, 'venue-1');
      expect(payload.submittedEvidence['businessEmail'], 'owner@redlion.example');
      expect(payload.draftVenueData['name'], 'Red Lion');
      expect(payload.confidenceScore, greaterThan(0));
    });

    test('rejects missing venue ID', () {
      final result = submissionService.prepareSubmission(
        venueId: ' ',
        claimantUid: 'user-1',
        venue: _SearchVenue(),
        evidence: const ClaimEvidence(businessEmail: 'owner@example.com'),
        claimantActive: true,
        existingStatusesForVenue: const [],
      );

      expect(result, isA<ClaimFailure>());
      expect((result as ClaimFailure).code, 'venue-id-required');
    });

    test('rejects missing claimant ID', () {
      final result = submissionService.prepareSubmission(
        venueId: 'venue-1',
        claimantUid: '',
        venue: _SearchVenue(),
        evidence: const ClaimEvidence(businessEmail: 'owner@example.com'),
        claimantActive: true,
        existingStatusesForVenue: const [],
      );

      expect((result as ClaimFailure).code, 'claimant-id-required');
    });

    test('rejects inactive claimant', () {
      final result = submissionService.prepareSubmission(
        venueId: 'venue-1',
        claimantUid: 'user-1',
        venue: _SearchVenue(),
        evidence: const ClaimEvidence(businessEmail: 'owner@example.com'),
        claimantActive: false,
        existingStatusesForVenue: const [],
      );

      expect((result as ClaimFailure).code, 'claimant-inactive');
    });

    test('rejects duplicate open claim conflict', () {
      final result = submissionService.prepareSubmission(
        venueId: 'venue-1',
        claimantUid: 'user-1',
        venue: _SearchVenue(),
        evidence: const ClaimEvidence(businessEmail: 'owner@example.com'),
        claimantActive: true,
        existingStatusesForVenue: const [ClaimStatus.pendingReview],
      );

      expect((result as ClaimFailure).code, 'open-claim-exists');
    });
  });

  group('ClaimEvidenceValidator', () {
    test('rejects empty evidence', () {
      final result = evidenceValidator.validate(const ClaimEvidence());
      expect((result as ClaimFailure).code, 'evidence-required');
    });

    test('rejects invalid email format', () {
      final result = evidenceValidator.validate(
        const ClaimEvidence(businessEmail: 'not-an-email'),
      );
      expect((result as ClaimFailure).code, 'invalid-email');
    });
  });

  group('ClaimReviewService', () {
    test('allows approve from pending review', () {
      final result = reviewService.prepareReview(
        claimId: 'claim-1',
        action: ClaimReviewAction.approve,
        currentStatus: ClaimStatus.pendingReview,
        notes: '',
        reviewerCanApprove: true,
      );

      expect(result, isA<ClaimSuccess<ClaimReviewPayload>>());
      final payload = (result as ClaimSuccess<ClaimReviewPayload>).value;
      expect(payload.functionName, 'approveVenueClaim');
      expect(payload.nextStatus, ClaimStatus.approved);
    });

    test('requires notes for rejection', () {
      final result = reviewService.prepareReview(
        claimId: 'claim-1',
        action: ClaimReviewAction.reject,
        currentStatus: ClaimStatus.pendingReview,
        notes: '',
        reviewerCanApprove: true,
      );

      expect((result as ClaimFailure).code, 'review-notes-required');
    });

    test('blocks invalid status transition', () {
      final result = reviewService.prepareReview(
        claimId: 'claim-1',
        action: ClaimReviewAction.approve,
        currentStatus: ClaimStatus.rejected,
        notes: '',
        reviewerCanApprove: true,
      );

      expect((result as ClaimFailure).code, 'invalid-status-transition');
    });

    test('allows withdrawal from draft', () {
      final result = reviewService.prepareReview(
        claimId: 'claim-1',
        action: ClaimReviewAction.withdraw,
        currentStatus: ClaimStatus.draft,
        notes: '',
        reviewerCanApprove: false,
      );

      expect(result, isA<ClaimSuccess<ClaimReviewPayload>>());
    });
  });

  group('ClaimConfidenceScorer', () {
    test('scores matching domains highest', () {
      const evidence = ClaimEvidence(
        businessEmail: 'owner@redlion.example',
        website: 'https://redlion.example',
        phone: '01234567890',
        companyRegistration: '12345678',
        notes: 'Additional verification notes for the venue location.',
      );

      final score = scorer.score(venue: _SearchVenue(), evidence: evidence);
      expect(score.score, greaterThanOrEqualTo(75));
      expect(score.autoApproved, isTrue);
    });
  });

  group('ClaimStatusTransitions', () {
    test('detects open claims', () {
      expect(
        ClaimStatusTransitions.hasOpenClaim(const [
          ClaimStatus.rejected,
          ClaimStatus.pendingReview,
        ]),
        isTrue,
      );
    });
  });

  group('ClaimAuditPreparation', () {
    test('prepares ownership transfer fields', () {
      final fields = ClaimOwnershipTransferPreparation.assignOwner(
        claimantUid: 'user-1',
        claimId: 'claim-1',
        venueId: 'venue-1',
      );

      expect(fields['ownerId'], 'user-1');
      expect(fields['isClaimed'], isTrue);
      expect(fields['activeClaimId'], 'claim-1');
    });
  });

  group('ClaimSearchSupport', () {
    test('matches partial venue search tokens', () {
      final venue = _SearchVenue();
      expect(
        ClaimSearchSupport.matchesQuery(venue, 'red', ['red']),
        isTrue,
      );
    });
  });
}
