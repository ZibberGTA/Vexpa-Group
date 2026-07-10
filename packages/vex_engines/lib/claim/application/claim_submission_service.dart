import '../domain/claim_evidence.dart';
import '../domain/claim_result.dart';
import '../domain/claim_search_candidate.dart';
import '../domain/claim_status.dart';
import 'claim_confidence_scorer.dart';
import 'claim_evidence_validator.dart';

/// Prepared payload for the submitVenueClaim callable.
final class ClaimSubmissionPayload {
  const ClaimSubmissionPayload({
    required this.venueId,
    required this.submittedEvidence,
    required this.draftVenueData,
    required this.confidenceScore,
  });

  final String venueId;
  final Map<String, dynamic> submittedEvidence;
  final Map<String, dynamic> draftVenueData;
  final int confidenceScore;

  Map<String, dynamic> toFunctionPayload() {
    return {
      'venueId': venueId,
      'submittedEvidence': submittedEvidence,
      'draftVenueData': draftVenueData,
    };
  }
}

/// Validates and prepares venue claim submission.
final class ClaimSubmissionService {
  const ClaimSubmissionService({
    ClaimEvidenceValidator evidenceValidator = const ClaimEvidenceValidator(),
    ClaimConfidenceScorer confidenceScorer = const ClaimConfidenceScorer(),
  })  : _evidenceValidator = evidenceValidator,
        _confidenceScorer = confidenceScorer;

  final ClaimEvidenceValidator _evidenceValidator;
  final ClaimConfidenceScorer _confidenceScorer;

  ClaimResult<ClaimSubmissionPayload> prepareSubmission({
    required String venueId,
    required String claimantUid,
    required ClaimSearchCandidate venue,
    required ClaimEvidence evidence,
    required bool claimantActive,
    required Iterable<ClaimStatus> existingStatusesForVenue,
  }) {
    if (venueId.trim().isEmpty) {
      return const ClaimFailure('venue-id-required', 'Select a venue to claim.');
    }
    if (claimantUid.trim().isEmpty) {
      return const ClaimFailure(
        'claimant-id-required',
        'Sign in to submit a claim.',
      );
    }
    if (!claimantActive) {
      return const ClaimFailure(
        'claimant-inactive',
        'Your account cannot submit claims right now.',
      );
    }
    if (!ClaimStatusTransitions.canSubmit(
      existingStatusesForVenue: existingStatusesForVenue,
    )) {
      return const ClaimFailure(
        'open-claim-exists',
        'You already have an active claim for this venue.',
      );
    }

    final evidenceResult = _evidenceValidator.validate(evidence);
    if (evidenceResult is ClaimFailure<ClaimEvidence>) {
      return ClaimFailure(
        evidenceResult.code,
        evidenceResult.message,
      );
    }

    final validatedEvidence = (evidenceResult as ClaimSuccess<ClaimEvidence>).value;
    final score = _confidenceScorer.score(
      venue: venue,
      evidence: validatedEvidence,
    );

    return ClaimSuccess(
      ClaimSubmissionPayload(
        venueId: venueId.trim(),
        submittedEvidence: validatedEvidence.toMap(),
        draftVenueData: _initialDraftFromVenue(venue, validatedEvidence),
        confidenceScore: score.score,
      ),
    );
  }

  Map<String, dynamic> _initialDraftFromVenue(
    ClaimSearchCandidate venue,
    ClaimEvidence evidence,
  ) {
    return {
      'name': venue.name,
      'address': venue.rawData['address'] ?? venue.address,
      'city': venue.city,
      'postcode': venue.postcode,
      'category': venue.category,
      'venueType': venue.category,
      'description': (venue.rawData['description'] ?? '').toString(),
      'website': evidence.website.trim().isEmpty
          ? venue.website
          : evidence.website.trim(),
      'websiteUrl': evidence.website.trim().isEmpty
          ? venue.website
          : evidence.website.trim(),
      'phone': evidence.phone.trim().isEmpty
          ? venue.phone
          : evidence.phone.trim(),
      'openingHours': venue.rawData['openingHours'] ?? <String, dynamic>{},
      'featureTags': venue.rawData['featureTags'] ?? <String>[],
      'socialLinks': venue.rawData['socialLinks'] ?? <String, dynamic>{},
      'draftChecklist': <String, dynamic>{},
    };
  }
}
