import 'package:vex_core/data/data_result.dart';
import 'package:vex_core/trails/trails.dart';
import 'package:vex_core/workflow/workflow.dart';

import '../../../workflow/domain/workflow_actor.dart';
import '../../../workflow/domain/workflow_status.dart';
import '../../../workflow/shared/shared.dart';
import '../../domain/participation/trail_participation_application.dart';
import '../../domain/participation/trail_participation_eligibility_policy.dart';
import '../../domain/participation/trail_participation_submission_payload.dart';
import '../../domain/trail.dart';
import '../../domain/trail_result.dart';
import '../../shared/trail_snapshot_mapper.dart';
import '../trail_application_result.dart';
import 'trail_participation_application_mapper.dart';

/// Actor and venue context for participation operations.
final class TrailParticipationActorContext {
  const TrailParticipationActorContext({
    required this.actorUid,
    required this.venueId,
    required this.managesVenue,
  });

  final String actorUid;
  final String venueId;
  final bool managesVenue;
}

/// Eligible trail summary for venue-side discovery.
final class TrailParticipationEligibleTrail {
  const TrailParticipationEligibleTrail({
    required this.trail,
    required this.eligibility,
    this.existingApplication,
  });

  final Trail trail;
  final TrailParticipationEligibilityResult eligibility;
  final TrailParticipationApplication? existingApplication;
}

/// Repository-backed orchestration for venue trail participation applications.
final class TrailParticipationApplicationService {
  const TrailParticipationApplicationService({
    required this.trailRepository,
    required this.workflowRepository,
  });

  final TrailRepository trailRepository;
  final WorkflowRequestRepository workflowRepository;

  Future<TrailApplicationResult<List<TrailParticipationEligibleTrail>>>
  listEligibleTrails({
    required TrailParticipationActorContext context,
    DateTime? now,
  }) async {
    if (!_hasValidActor(context)) {
      return const TrailApplicationFailure(
        TrailApplicationFailureCodes.authenticationRequired,
        'Authentication and venue access are required.',
      );
    }

    final trailsResult = await trailRepository.list(
      TrailListQuery(publishedOnly: true, includeArchived: false),
    );
    if (trailsResult case DataFailure(error: final error)) {
      return fromRepositoryFailure(error.message, cause: error);
    }

    final trails = (trailsResult as DataSuccess).value;
    final existing = await _loadApplicationsForVenue(context.venueId);
    if (existing case TrailApplicationFailure()) {
      return TrailApplicationFailure(
        existing.code,
        existing.message,
        cause: existing.cause,
      );
    }
    final applications =
        (existing
                as TrailApplicationSuccess<List<TrailParticipationApplication>>)
            .value;

    final eligible = <TrailParticipationEligibleTrail>[];
    for (final snapshot in trails) {
      final mapped = TrailSnapshotMapper.toDomain(snapshot);
      if (mapped case TrailFailure()) continue;
      final trail = (mapped as TrailSuccess<Trail>).value;
      if (!trail.participationSettings.acceptsVenueApplications) continue;

      final trailApplications = applications
          .where((app) => app.trailId == trail.id)
          .toList();
      final eligibility = assessEligibility(
        trail: trail,
        venueId: context.venueId,
        venueIsManageable: context.managesVenue,
        existingApplicationStatuses: [
          for (final app in trailApplications) app.workflowStatus,
        ],
        requestedStopOrder: trail.stops.length + 1,
        now: now,
      );

      eligible.add(
        TrailParticipationEligibleTrail(
          trail: trail,
          eligibility: eligibility,
          existingApplication: trailApplications.isEmpty
              ? null
              : trailApplications.first,
        ),
      );
    }

    return TrailApplicationSuccess(eligible);
  }

  TrailParticipationEligibilityResult assessEligibility({
    required Trail trail,
    required String venueId,
    required bool venueIsManageable,
    required List<WorkflowStatus> existingApplicationStatuses,
    required int requestedStopOrder,
    DateTime? now,
  }) {
    return TrailParticipationEligibilityPolicy.evaluate(
      TrailParticipationEligibilityInput(
        trail: trail,
        venueId: venueId,
        requestedStopOrder: requestedStopOrder,
        venueIsManageable: venueIsManageable,
        existingApplicationStatuses: existingApplicationStatuses,
        now: now,
      ),
    );
  }

  Future<TrailApplicationResult<TrailParticipationApplication>> createDraft({
    required TrailParticipationActorContext context,
    required String trailId,
    required TrailParticipationSubmissionPayload payload,
    required String requestId,
    DateTime? now,
  }) async {
    return _mutateDraft(
      context: context,
      trailId: trailId,
      payload: payload,
      requestId: requestId,
      now: now,
      create: true,
    );
  }

  Future<TrailApplicationResult<TrailParticipationApplication>> updateDraft({
    required TrailParticipationActorContext context,
    required String requestId,
    required TrailParticipationSubmissionPayload payload,
    required int expectedRevision,
    DateTime? now,
  }) async {
    return _mutateDraft(
      context: context,
      trailId: payload.trailId,
      payload: payload,
      requestId: requestId,
      expectedRevision: expectedRevision,
      now: now,
      create: false,
    );
  }

  Future<TrailApplicationResult<TrailParticipationApplication>> submit({
    required TrailParticipationActorContext context,
    required String requestId,
    required int expectedRevision,
  }) async {
    if (!_hasValidActor(context)) return _authFailure();

    final command = SubmitWorkflowCommand(
      requestId: requestId,
      expectedRevision: expectedRevision,
      actor: _actor(context),
    );
    final result = await workflowRepository.submit(command);
    return _mapRepositoryResult(result);
  }

  Future<TrailApplicationResult<TrailParticipationApplication>> resubmit({
    required TrailParticipationActorContext context,
    required String requestId,
    required TrailParticipationSubmissionPayload payload,
    required int expectedRevision,
  }) async {
    if (!_hasValidActor(context)) return _authFailure();

    final command = ResubmitWorkflowCommand(
      requestId: requestId,
      expectedRevision: expectedRevision,
      payload: _payloadSnapshot(payload),
      actor: _actor(context),
    );
    final result = await workflowRepository.resubmit(command);
    return _mapRepositoryResult(result);
  }

  Future<TrailApplicationResult<TrailParticipationApplication>> withdraw({
    required TrailParticipationActorContext context,
    required String requestId,
    required int expectedRevision,
    String? notes,
  }) async {
    if (!_hasValidActor(context)) return _authFailure();

    final command = WithdrawWorkflowCommand(
      requestId: requestId,
      expectedRevision: expectedRevision,
      actor: _actor(context),
      notes: notes,
    );
    final result = await workflowRepository.withdraw(command);
    return _mapRepositoryResult(result);
  }

  Future<TrailApplicationResult<TrailParticipationApplication>> getApplication(
    String requestId,
  ) async {
    final result = await workflowRepository.get(requestId);
    return _mapRepositoryResult(result);
  }

  Stream<TrailApplicationResult<TrailParticipationApplication>>
  watchApplication(String requestId) {
    return workflowRepository.watch(requestId).map(_mapRepositoryResult);
  }

  Future<TrailApplicationResult<List<TrailParticipationApplication>>>
  listApplicationsForVenue(String venueId) async {
    return _loadApplicationsForVenue(venueId);
  }

  Stream<TrailApplicationResult<List<TrailParticipationApplication>>>
  watchApplicationsForVenue(String venueId) {
    return workflowRepository
        .watchList(
          WorkflowListQuery(
            workflowType: WorkflowTypeIds.trailVenueParticipation,
            subjectVenueId: venueId,
            orderByUpdatedAtDesc: true,
          ),
        )
        .map(_mapApplicationList);
  }

  Future<TrailApplicationResult<TrailParticipationApplication>> _mutateDraft({
    required TrailParticipationActorContext context,
    required String trailId,
    required TrailParticipationSubmissionPayload payload,
    required String requestId,
    required bool create,
    int? expectedRevision,
    DateTime? now,
  }) async {
    if (!_hasValidActor(context)) return _authFailure();
    if (payload.trailId != trailId || payload.venueId != context.venueId) {
      return const TrailApplicationFailure(
        'invalid-subject',
        'Trail and venue identifiers must match the active venue context.',
      );
    }

    final trailResult = await trailRepository.get(trailId);
    if (trailResult case DataFailure(error: final error)) {
      return fromRepositoryFailure(error.message, cause: error);
    }
    final trailMapped = TrailSnapshotMapper.toDomain(
      (trailResult as DataSuccess).value,
    );
    if (trailMapped case TrailFailure(:final message)) {
      return TrailApplicationFailure(
        TrailApplicationFailureCodes.mappingFailure,
        message,
      );
    }
    final trail = (trailMapped as TrailSuccess<Trail>).value;

    final existing = await _loadApplicationsForVenue(context.venueId);
    if (existing case TrailApplicationFailure()) {
      return TrailApplicationFailure(existing.code, existing.message);
    }
    final applications =
        (existing
                as TrailApplicationSuccess<List<TrailParticipationApplication>>)
            .value;
    final statuses = applications
        .where(
          (app) => app.trailId == trailId && app.workflowRequestId != requestId,
        )
        .map((app) => app.workflowStatus)
        .toList();

    final eligibility = assessEligibility(
      trail: trail,
      venueId: context.venueId,
      venueIsManageable: context.managesVenue,
      existingApplicationStatuses: statuses,
      requestedStopOrder: payload.requestedStopOrder,
      now: now,
    );
    if (!eligibility.eligible) {
      return TrailApplicationFailure(
        eligibility.blockingReasons.first,
        'Venue is not eligible to apply for this trail.',
      );
    }

    if (create) {
      final command = CreateWorkflowDraftCommand(
        requestId: requestId,
        workflowType: WorkflowTypeIds.trailVenueParticipation,
        submittedByUid: context.actorUid,
        subjectRefs: WorkflowSubjectRefsSnapshot({
          'trailId': trailId,
          'venueId': context.venueId,
        }),
        payload: _payloadSnapshot(payload),
        actor: _actor(context),
      );
      final result = await workflowRepository.createDraft(command);
      return _mapRepositoryResult(result);
    }

    final command = UpdateWorkflowDraftCommand(
      requestId: requestId,
      expectedRevision: expectedRevision ?? 1,
      payload: _payloadSnapshot(payload),
      actor: _actor(context),
    );
    final result = await workflowRepository.updateDraft(command);
    return _mapRepositoryResult(result);
  }

  Future<TrailApplicationResult<List<TrailParticipationApplication>>>
  _loadApplicationsForVenue(String venueId) async {
    final result = await workflowRepository.list(
      WorkflowListQuery(
        workflowType: WorkflowTypeIds.trailVenueParticipation,
        subjectVenueId: venueId.trim(),
        orderByUpdatedAtDesc: true,
      ),
    );
    return _mapApplicationList(result);
  }

  TrailApplicationResult<List<TrailParticipationApplication>>
  _mapApplicationList(DataResult<List<WorkflowRequestSnapshot>> result) {
    if (result case DataFailure(error: final error)) {
      return fromRepositoryFailure(error.message, cause: error);
    }
    final snapshots = (result as DataSuccess).value;
    final mapped = <TrailParticipationApplication>[];
    for (final snapshot in snapshots) {
      final application =
          TrailParticipationApplicationMapper.fromWorkflowSnapshot(snapshot);
      if (application != null) mapped.add(application);
    }
    return TrailApplicationSuccess(mapped);
  }

  TrailApplicationResult<TrailParticipationApplication> _mapRepositoryResult(
    DataResult<WorkflowRequestSnapshot> result,
  ) {
    if (result case DataFailure(error: final error)) {
      return fromRepositoryFailure(error.message, cause: error);
    }
    final application =
        TrailParticipationApplicationMapper.fromWorkflowSnapshot(
          (result as DataSuccess).value,
        );
    if (application == null) {
      return const TrailApplicationFailure(
        TrailApplicationFailureCodes.mappingFailure,
        'Failed to map workflow request to participation application.',
      );
    }
    return TrailApplicationSuccess(application);
  }

  WorkflowPayloadSnapshot _payloadSnapshot(
    TrailParticipationSubmissionPayload payload,
  ) {
    return WorkflowPayloadSnapshot(
      values: payload.toPayloadValues(),
      schemaVersion: payload.schemaVersion,
    );
  }

  WorkflowActorContext _actor(TrailParticipationActorContext context) {
    return WorkflowActorContext(
      uid: context.actorUid,
      kind: WorkflowActorKind.submitter.persistenceValue,
    );
  }

  bool _hasValidActor(TrailParticipationActorContext context) {
    return context.actorUid.trim().isNotEmpty &&
        context.venueId.trim().isNotEmpty &&
        context.managesVenue;
  }

  TrailApplicationFailure<TrailParticipationApplication> _authFailure() {
    return const TrailApplicationFailure(
      TrailApplicationFailureCodes.authenticationRequired,
      'Authentication and venue access are required.',
    );
  }
}
