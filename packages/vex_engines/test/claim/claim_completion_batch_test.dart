import 'package:test/test.dart';
import 'package:vex_engines/claim/application/claim_evidence_interpretation.dart';
import 'package:vex_engines/claim/application/claim_search_service.dart';
import 'package:vex_engines/claim/application/claim_summary_service.dart';
import 'package:vex_engines/claim/domain/claim_evidence.dart';
import 'package:vex_engines/claim/domain/claim_list_entry.dart';
import 'package:vex_engines/claim/domain/claim_result.dart';
import 'package:vex_engines/claim/domain/claim_search_candidate.dart';
import 'package:vex_engines/claim/domain/claim_status.dart';
import 'package:vex_engines/claim/shared/claim_presentation_support.dart';
import 'package:vex_engines/claim/shared/claim_record_support.dart';

final class _Candidate implements ClaimSearchCandidate {
  _Candidate({
    required this.venueId,
    required this.name,
    this.address = '',
    this.city = '',
    this.postcode = '',
    this.category = 'Venue',
    this.website = '',
    this.phone = '',
    this.rawData = const {},
  });

  @override
  final String venueId;

  @override
  final String name;

  @override
  final String address;

  @override
  final String city;

  @override
  final String postcode;

  @override
  final String category;

  @override
  final String website;

  @override
  final String phone;

  @override
  final Map<String, dynamic> rawData;
}

void main() {
  const searchService = ClaimSearchService();
  const summaryService = ClaimSummaryService();
  const evidenceInterpretation = ClaimEvidenceInterpretation();

  group('ClaimSearchService', () {
    test('treats short queries as too short', () {
      expect(searchService.interpretQuery('a'), isA<ClaimSearchTooShort>());
    });

    test('removes duplicate candidates by venue id', () {
      final matches = <String, _Candidate>{};
      final candidate = _Candidate(venueId: 'v1', name: 'Red Lion');
      searchService.tryMergeCandidate(
        matches: matches,
        candidate: candidate,
        normalizedQuery: 'red',
        tokens: const ['red'],
      );
      searchService.tryMergeCandidate(
        matches: matches,
        candidate: _Candidate(venueId: 'v1', name: 'Red Lion Pub'),
        normalizedQuery: 'red',
        tokens: const ['red'],
      );
      expect(matches.length, 1);
      expect(matches['v1']!.name, 'Red Lion Pub');
    });

    test('ranks prefix matches ahead of partial matches', () {
      final query =
          (searchService.interpretQuery('red') as ClaimSearchReady).query;
      final ranked = searchService.finalizeResults([
        _Candidate(venueId: 'b', name: 'Old Red Tavern'),
        _Candidate(venueId: 'a', name: 'Red Lion'),
      ], query);
      expect(ranked.first.venueId, 'a');
    });

    test('preserves deterministic ties by first seen order', () {
      final query =
          (searchService.interpretQuery('pub') as ClaimSearchReady).query;
      final ranked = searchService.finalizeResults([
        _Candidate(venueId: 'z', name: 'Alpha Pub'),
        _Candidate(venueId: 'y', name: 'Beta Pub'),
      ], query);
      expect(ranked.map((item) => item.venueId).toList(), ['z', 'y']);
    });

    test('returns empty finalize results unchanged', () {
      final query =
          (searchService.interpretQuery('venue') as ClaimSearchReady).query;
      expect(searchService.finalizeResults(<_Candidate>[], query), isEmpty);
    });

    test('limits indexed query tokens to three', () {
      final query =
          (searchService.interpretQuery('one two three four five')
                  as ClaimSearchReady)
              .query;
      expect(searchService.indexedQueryTokens(query).length, 3);
    });
  });

  group('ClaimPresentationSupport', () {
    test('labels directory pending review status', () {
      expect(
        ClaimPresentationSupport.directoryClaimStatusLabel(const {
          'claimStatus': 'pending_review',
        }),
        'Pending review',
      );
    });

    test('formats display address with fallback', () {
      expect(
        ClaimPresentationSupport.formatDisplayAddress(
          address: '',
          city: '',
          postcode: '',
        ),
        'Address not listed',
      );
    });
  });

  group('ClaimSummaryService', () {
    test('computes admin metrics', () {
      final metrics = summaryService.adminMetrics([
        ClaimListEntry(
          id: '1',
          venueId: 'v1',
          venueName: 'A',
          claimantUid: 'u1',
          claimantEmail: '',
          status: ClaimStatus.pendingReview,
          autoApproved: false,
          confidenceScore: 50,
          evidence: const ClaimEvidence(businessEmail: 'a@example.com'),
        ),
        ClaimListEntry(
          id: '2',
          venueId: 'v2',
          venueName: 'B',
          claimantUid: 'u2',
          claimantEmail: '',
          status: ClaimStatus.autoApproved,
          autoApproved: true,
          confidenceScore: 90,
          evidence: const ClaimEvidence(businessEmail: 'b@example.com'),
        ),
      ]);

      expect(metrics.total, 2);
      expect(metrics.pendingReview, 1);
      expect(metrics.autoApproved, 1);
    });

    test('blocks submission when open claim conflict exists', () {
      final result = summaryService.submissionReadiness(
        evidence: const ClaimEvidence(businessEmail: 'owner@example.com'),
        claimantActive: true,
        existingStatusesForVenue: const [ClaimStatus.pendingReview],
      );
      expect((result as ClaimFailure).code, 'open-claim-exists');
    });

    test('marks admin review ready when evidence complete', () {
      final summary = summaryService.adminReviewSummary(
        claim: ClaimListEntry(
          id: 'claim-1',
          venueId: 'v1',
          venueName: 'Red Lion',
          claimantUid: 'u1',
          claimantEmail: '',
          status: ClaimStatus.pendingReview,
          autoApproved: false,
          confidenceScore: 80,
          evidence: const ClaimEvidence(businessEmail: 'owner@example.com'),
        ),
        reviewerCanApprove: true,
      );
      expect(summary.reviewReady, isTrue);
      expect(summary.canApprove, isTrue);
    });
  });

  group('ClaimEvidenceInterpretation', () {
    test('detects evidence missing contact details', () {
      expect(
        evidenceInterpretation.completeness(const ClaimEvidence()),
        ClaimEvidenceCompleteness.missingContactEvidence,
      );
    });

    test('scopes private evidence references to claimant', () {
      expect(
        evidenceInterpretation.referencesBelongToClaimant(
          documentUrls: const ['claims/user-1/evidence/doc-1.pdf'],
          claimantUid: 'user-1',
        ),
        isTrue,
      );
      expect(
        evidenceInterpretation.referencesBelongToClaimant(
          documentUrls: const ['claims/user-2/evidence/doc-1.pdf'],
          claimantUid: 'user-1',
        ),
        isFalse,
      );
    });

    test('denies evidence download for non-claimant viewers', () {
      expect(
        evidenceInterpretation.canResolveEvidenceReference(
          viewerUid: 'admin-1',
          claimantUid: 'user-1',
          reference: 'claims/user-1/evidence/doc-1.pdf',
        ),
        isFalse,
      );
    });
  });

  group('ClaimRecordSupport', () {
    test('detects malformed claim records', () {
      expect(
        ClaimRecordSupport.isMalformedClaimRecord(const {
          'venueId': '',
          'claimantUid': '',
        }),
        isTrue,
      );
    });

    test('orders submittedAt ties deterministically by id', () {
      final comparison = ClaimRecordSupport.compareSubmittedAtDesc(
        leftSubmittedAt: DateTime(2026, 1, 1),
        rightSubmittedAt: DateTime(2026, 1, 1),
        leftId: 'a',
        rightId: 'b',
      );
      expect(comparison, lessThan(0));
    });
  });
}
