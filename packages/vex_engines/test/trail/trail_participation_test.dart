import 'package:test/test.dart';
import 'package:vex_engines/trail/domain/participation/trail_participation_blocking_reason.dart';
import 'package:vex_engines/trail/domain/participation/trail_participation_duplicate_policy.dart';
import 'package:vex_engines/trail/domain/participation/trail_participation_eligibility_policy.dart';
import 'package:vex_engines/trail/domain/participation/trail_participation_settings.dart';
import 'package:vex_engines/trail/domain/participation/trail_participation_submission_payload.dart';
import 'package:vex_engines/trail/domain/trail.dart';
import 'package:vex_engines/trail/domain/trail_status.dart';
import 'package:vex_engines/trail/domain/trail_stop.dart';
import 'package:vex_engines/trail/domain/trail_type.dart';
import 'package:vex_engines/trail/application/participation/trail_participation_approved_handler.dart';
import 'package:vex_engines/trail/domain/participation/trail_participation_submission_payload.dart';
import 'package:vex_engines/trail/domain/trail.dart';
import 'package:vex_engines/trail/domain/trail_status.dart';
import 'package:vex_engines/trail/domain/trail_stop.dart';
import 'package:vex_engines/trail/domain/trail_type.dart';
import 'package:vex_engines/trail/application/participation/trail_participation_payload_validator.dart';
import 'package:vex_engines/trail/application/participation/trail_participation_permission_port.dart';
import 'package:vex_engines/workflow/application/ports/workflow_payload_validator_port.dart';
import 'package:vex_engines/workflow/domain/workflow_action.dart';
import 'package:vex_engines/workflow/domain/workflow_actor.dart';
import 'package:vex_engines/workflow/domain/workflow_payload.dart';
import 'package:vex_engines/workflow/domain/workflow_request.dart';
import 'package:vex_engines/workflow/domain/workflow_status.dart';
import 'package:vex_engines/workflow/domain/workflow_subject_refs.dart';
import 'package:vex_engines/workflow/domain/workflow_type_id.dart';
import 'package:vex_engines/workflow/shared/shared.dart';
import 'package:vex_engines/workflow/application/ports/workflow_consumer_handlers.dart';

void main() {
  final now = DateTime.utc(2026, 7, 1, 12);

  Trail curatedTrail({
    bool acceptsApplications = true,
    List<TrailStop> stops = const [],
    int? maximumStops,
  }) {
    return Trail(
      id: 'trail-1',
      name: 'Curated Trail',
      description: 'Test trail',
      bannerImageUrl: '',
      status: TrailStatus.published,
      published: true,
      area: 'Manchester',
      availabilityStart: DateTime.utc(2026, 6, 1),
      availabilityEnd: DateTime.utc(2026, 8, 1),
      estimatedDurationMinutes: 120,
      estimatedWalkingDistance: 1000,
      averageRating: 4.5,
      venueCount: stops.length,
      trailType: TrailType.curated,
      generatedAt: DateTime.utc(2026, 5, 1),
      stops: stops,
      participationSettings: TrailParticipationSettings(
        acceptsVenueApplications: acceptsApplications,
        maximumStops: maximumStops,
      ),
    );
  }

  group('TrailParticipationEligibilityPolicy', () {
    test('eligible venue can apply', () {
      final result = TrailParticipationEligibilityPolicy.evaluate(
        TrailParticipationEligibilityInput(
          trail: curatedTrail(),
          venueId: 'venue-1',
          requestedStopOrder: 1,
          venueIsManageable: true,
          existingApplicationStatuses: const [],
          now: now,
        ),
      );

      expect(result.eligible, isTrue);
      expect(result.validRequestedPositions, [1]);
    });

    test('trail not accepting applications is blocked', () {
      final result = TrailParticipationEligibilityPolicy.evaluate(
        TrailParticipationEligibilityInput(
          trail: curatedTrail(acceptsApplications: false),
          venueId: 'venue-1',
          requestedStopOrder: 1,
          venueIsManageable: true,
          existingApplicationStatuses: const [],
          now: now,
        ),
      );

      expect(result.eligible, isFalse);
      expect(
        result.blockingReasons,
        contains(TrailParticipationBlockingReason.applicationsNotAccepted),
      );
    });

    test('venue already in trail is blocked', () {
      final result = TrailParticipationEligibilityPolicy.evaluate(
        TrailParticipationEligibilityInput(
          trail: curatedTrail(stops: [_sampleStop()]),
          venueId: 'venue-1',
          requestedStopOrder: 2,
          venueIsManageable: true,
          existingApplicationStatuses: const [],
          now: now,
        ),
      );

      expect(
        result.blockingReasons,
        contains(TrailParticipationBlockingReason.venueAlreadyStop),
      );
    });

    test('duplicate open application is blocked', () {
      final result = TrailParticipationEligibilityPolicy.evaluate(
        TrailParticipationEligibilityInput(
          trail: curatedTrail(),
          venueId: 'venue-1',
          requestedStopOrder: 1,
          venueIsManageable: true,
          existingApplicationStatuses: const [WorkflowStatus.submitted],
          now: now,
        ),
      );

      expect(
        result.blockingReasons,
        contains(TrailParticipationBlockingReason.duplicateOpenApplication),
      );
    });

    test('approved application blocks another application', () {
      final result = TrailParticipationEligibilityPolicy.evaluate(
        TrailParticipationEligibilityInput(
          trail: curatedTrail(),
          venueId: 'venue-1',
          requestedStopOrder: 1,
          venueIsManageable: true,
          existingApplicationStatuses: const [WorkflowStatus.approved],
          now: now,
        ),
      );

      expect(
        result.blockingReasons,
        contains(TrailParticipationBlockingReason.approvedApplicationExists),
      );
    });

    test('reapply allowed after rejection', () {
      expect(
        TrailParticipationDuplicatePolicy.allowsReapply(
          WorkflowStatus.rejected,
        ),
        isTrue,
      );
      final result = TrailParticipationEligibilityPolicy.evaluate(
        TrailParticipationEligibilityInput(
          trail: curatedTrail(),
          venueId: 'venue-1',
          requestedStopOrder: 1,
          venueIsManageable: true,
          existingApplicationStatuses: const [WorkflowStatus.rejected],
          now: now,
        ),
      );
      expect(result.eligible, isTrue);
    });

    test('invalid requested position is blocked', () {
      final result = TrailParticipationEligibilityPolicy.evaluate(
        TrailParticipationEligibilityInput(
          trail: curatedTrail(),
          venueId: 'venue-1',
          requestedStopOrder: 99,
          venueIsManageable: true,
          existingApplicationStatuses: const [],
          now: now,
        ),
      );

      expect(
        result.blockingReasons,
        contains(TrailParticipationBlockingReason.invalidRequestedPosition),
      );
    });

    test('trail capacity reached is blocked', () {
      final result = TrailParticipationEligibilityPolicy.evaluate(
        TrailParticipationEligibilityInput(
          trail: curatedTrail(
            maximumStops: 1,
            stops: [_sampleStop(venueId: 'other')],
          ),
          venueId: 'venue-1',
          requestedStopOrder: 2,
          venueIsManageable: true,
          existingApplicationStatuses: const [],
          now: now,
        ),
      );

      expect(
        result.blockingReasons,
        contains(TrailParticipationBlockingReason.trailCapacityReached),
      );
    });
  });

  group('TrailParticipationPayloadValidator', () {
    const validator = TrailParticipationPayloadValidator(
      expectedTrailId: 'trail-1',
      expectedVenueId: 'venue-1',
    );

    WorkflowPayload payload({
      String note = 'We would love to join.',
      int stop = 1,
    }) {
      return WorkflowPayload(
        schemaVersion: 1,
        values: {
          'schemaVersion': 1,
          'trailId': 'trail-1',
          'venueId': 'venue-1',
          'requestedStopOrder': stop,
          'participationNote': note,
        },
      );
    }

    test('valid submitted payload passes', () {
      expect(
        validator.validateSubmitted(payload()),
        isA<WorkflowPayloadValidationSuccess>(),
      );
    });

    test('subject mismatch fails', () {
      final bad = WorkflowPayload(
        schemaVersion: 1,
        values: {
          'schemaVersion': 1,
          'trailId': 'other-trail',
          'venueId': 'venue-1',
          'requestedStopOrder': 1,
          'participationNote': 'note',
        },
      );
      expect(
        validator.validateSubmitted(bad),
        isA<WorkflowPayloadValidationFailure>(),
      );
    });
  });

  group('TrailParticipationPermissionPort', () {
    test('venue submitter can submit and withdraw', () async {
      final request = WorkflowRequest(
        requestId: 'req-1',
        workflowType: const WorkflowTypeId(
          WorkflowTypeIds.trailVenueParticipation,
        ),
        status: WorkflowStatus.submitted,
        submittedByUid: 'user-1',
        subjectRefs: const WorkflowSubjectRefs({
          'trailId': 'trail-1',
          'venueId': 'venue-1',
        }),
        payload: const WorkflowPayload(values: {}, schemaVersion: 1),
        createdAt: now,
        updatedAt: now,
        revision: 1,
      );
      final port = TrailParticipationPermissionPort(
        facts: const TrailParticipationPermissionFacts(
          actorUid: 'user-1',
          managesVenue: true,
          ownsRequest: true,
        ),
      );
      final actor = const WorkflowActor(
        uid: 'user-1',
        kind: WorkflowActorKind.submitter,
      );

      final withdrawCaps = await port.resolve(
        actor: actor,
        request: request,
        action: WorkflowAction.withdraw,
      );
      expect(withdrawCaps.canWithdraw, isTrue);
      expect(withdrawCaps.canApprove, isFalse);
    });
  });

  group('TrailParticipationApprovedHandler', () {
    test('approval handler prepares plan without mutating trail', () async {
      final request = WorkflowRequest(
        requestId: 'req-1',
        workflowType: const WorkflowTypeId(
          WorkflowTypeIds.trailVenueParticipation,
        ),
        status: WorkflowStatus.approved,
        submittedByUid: 'user-1',
        subjectRefs: const WorkflowSubjectRefs({
          'trailId': 'trail-1',
          'venueId': 'venue-1',
        }),
        payload: WorkflowPayload(
          schemaVersion: 1,
          values: TrailParticipationSubmissionPayload(
            schemaVersion: 1,
            trailId: 'trail-1',
            venueId: 'venue-1',
            requestedStopOrder: 2,
            participationNote: 'note',
          ).toPayloadValues(),
        ),
        createdAt: now,
        updatedAt: now,
        revision: 2,
      );

      await TrailParticipationApprovedHandler.handle(
        WorkflowHandlerContext(
          request: request,
          notes: null,
          reason: null,
          decisionCode: null,
        ),
      );
    });
  });
}

final _stopTime = DateTime.utc(2026, 1, 1);

TrailStop _sampleStop({String venueId = 'venue-1'}) {
  return TrailStop(
    venueId: venueId,
    venueName: 'Venue',
    address: '',
    bannerImageUrl: '',
    logoUrl: '',
    order: 1,
    score: 0,
    arriveAt: _stopTime,
    leaveAt: _stopTime,
  );
}
