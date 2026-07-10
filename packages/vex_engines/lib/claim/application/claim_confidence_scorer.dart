import '../domain/claim_confidence_score.dart';
import '../domain/claim_evidence.dart';
import '../domain/claim_search_candidate.dart';
import '../shared/claim_domain_utils.dart';

/// Scores claim confidence from venue listing and submitted evidence.
final class ClaimConfidenceScorer {
  const ClaimConfidenceScorer({this.autoApprovalThreshold = 75});

  final int autoApprovalThreshold;

  ClaimConfidenceScore score({
    required ClaimSearchCandidate venue,
    required ClaimEvidence evidence,
  }) {
    final venueDomain = ClaimDomainUtils.domainFromUrl(venue.website);
    final evidenceEmailDomain = ClaimDomainUtils.domainFromEmail(
      evidence.businessEmail,
    );
    final evidenceWebsiteDomain = ClaimDomainUtils.domainFromUrl(
      evidence.website,
    );
    final phoneMatches =
        ClaimDomainUtils.digits(venue.phone).isNotEmpty &&
        ClaimDomainUtils.digits(venue.phone) ==
            ClaimDomainUtils.digits(evidence.phone);

    final signals = [
      ClaimConfidenceSignal(
        key: 'business_email_domain',
        label: 'Business email matches venue domain',
        points: 35,
        matched: venueDomain.isNotEmpty && venueDomain == evidenceEmailDomain,
      ),
      ClaimConfidenceSignal(
        key: 'website_domain',
        label: 'Website matches existing venue website',
        points: 25,
        matched:
            venueDomain.isNotEmpty && venueDomain == evidenceWebsiteDomain,
      ),
      ClaimConfidenceSignal(
        key: 'company_registration',
        label: 'Company registration supplied',
        points: 25,
        matched: evidence.hasCompanyRegistration,
      ),
      ClaimConfidenceSignal(
        key: 'phone_match',
        label: 'Phone number matches venue listing',
        points: 15,
        matched: phoneMatches,
      ),
      ClaimConfidenceSignal(
        key: 'location_verification',
        label: 'Additional location notes supplied',
        points: 5,
        matched: evidence.notes.trim().length >= 20,
      ),
    ];

    final total = signals
        .where((signal) => signal.matched)
        .fold<int>(0, (totalPoints, signal) => totalPoints + signal.points)
        .clamp(0, 100)
        .toInt();

    return ClaimConfidenceScore(
      score: total,
      threshold: autoApprovalThreshold,
      signals: signals,
    );
  }
}
