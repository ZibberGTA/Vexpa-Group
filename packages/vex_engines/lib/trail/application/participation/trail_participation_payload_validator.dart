import '../../../workflow/application/ports/workflow_payload_validator_port.dart';
import '../../../workflow/domain/workflow_payload.dart';
import '../../domain/participation/trail_participation_submission_payload.dart';

/// Structural payload validation for `trail.venue_participation`.
final class TrailParticipationPayloadValidator
    implements WorkflowPayloadValidatorPort {
  const TrailParticipationPayloadValidator({
    this.expectedTrailId,
    this.expectedVenueId,
  });

  final String? expectedTrailId;
  final String? expectedVenueId;

  @override
  WorkflowPayloadValidationResult validateDraft(WorkflowPayload payload) {
    return _validate(payload, requireNote: false);
  }

  @override
  WorkflowPayloadValidationResult validateSubmitted(WorkflowPayload payload) {
    return _validate(payload, requireNote: true);
  }

  @override
  WorkflowPayloadValidationResult validateResubmitted(WorkflowPayload payload) {
    return _validate(payload, requireNote: true);
  }

  WorkflowPayloadValidationResult _validate(
    WorkflowPayload payload, {
    required bool requireNote,
  }) {
    final issues = <WorkflowPayloadValidationIssue>[];

    if (payload.schemaVersion !=
        TrailParticipationSubmissionPayload.currentSchemaVersion) {
      issues.add(
        const WorkflowPayloadValidationIssue(
          code: 'unsupported-schema-version',
          message: 'Unsupported participation payload schema version.',
          field: 'schemaVersion',
        ),
      );
    }

    final parsed = TrailParticipationSubmissionPayload.fromPayloadValues(
      payload.values,
    );
    if (parsed == null) {
      issues.add(
        const WorkflowPayloadValidationIssue(
          code: 'invalid-payload',
          message: 'Participation payload is missing required fields.',
        ),
      );
      return WorkflowPayloadValidationFailure(issues);
    }

    if (expectedTrailId != null && parsed.trailId != expectedTrailId) {
      issues.add(
        WorkflowPayloadValidationIssue(
          code: 'trail-id-mismatch',
          message: 'Payload trailId does not match subject reference.',
          field: 'trailId',
        ),
      );
    }

    if (expectedVenueId != null && parsed.venueId != expectedVenueId) {
      issues.add(
        WorkflowPayloadValidationIssue(
          code: 'venue-id-mismatch',
          message: 'Payload venueId does not match subject reference.',
          field: 'venueId',
        ),
      );
    }

    if (parsed.requestedStopOrder <= 0) {
      issues.add(
        const WorkflowPayloadValidationIssue(
          code: 'invalid-stop-order',
          message: 'Requested stop position must be a positive integer.',
          field: 'requestedStopOrder',
        ),
      );
    }

    final note = parsed.participationNote.trim();
    if (requireNote && note.isEmpty) {
      issues.add(
        const WorkflowPayloadValidationIssue(
          code: 'participation-note-required',
          message: 'Participation note is required.',
          field: 'participationNote',
        ),
      );
    }

    if (note.length >
        TrailParticipationSubmissionPayload.maxParticipationNoteLength) {
      issues.add(
        WorkflowPayloadValidationIssue(
          code: 'participation-note-too-long',
          message:
              'Participation note must not exceed '
              '${TrailParticipationSubmissionPayload.maxParticipationNoteLength} characters.',
          field: 'participationNote',
        ),
      );
    }

    if (issues.isNotEmpty) {
      return WorkflowPayloadValidationFailure(issues);
    }
    return const WorkflowPayloadValidationSuccess();
  }
}
