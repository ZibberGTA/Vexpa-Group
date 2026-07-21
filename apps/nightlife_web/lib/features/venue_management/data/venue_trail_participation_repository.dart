import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vex_core/data/data_result.dart';
import 'package:vex_core/workflow/workflow.dart';
import 'package:vex_engines/trail/application/participation/trail_participation_application_service.dart';
import 'package:vex_engines/trail/application/trail_application_result.dart';
import 'package:vex_engines/trail/domain/participation/trail_participation_application.dart';
import 'package:vex_engines/trail/domain/participation/trail_participation_display_status.dart';
import 'package:vex_engines/trail/domain/participation/trail_participation_eligibility_policy.dart';
import 'package:vex_engines/trail/domain/participation/trail_participation_submission_payload.dart';
import 'package:vex_engines/trail/domain/trail.dart';
import 'package:vex_engines/workflow/domain/workflow_status.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/vexcore/web_vexcore.dart';
import '../models/venue_dashboard_context.dart';
import '../models/venue_trail_participation_presentation.dart';
import '../services/venue_trail_participation_action_resolver.dart';
import '../services/venue_trail_participation_audit_mapper.dart';

/// Venue Management facade over VexTrail participation orchestration.
class VenueTrailParticipationRepository {
  VenueTrailParticipationRepository({
    TrailParticipationApplicationService? applicationService,
    WorkflowAuditRepository? auditRepository,
    FirebaseFirestore? firestore,
  }) : _applicationService =
           applicationService ??
           TrailParticipationApplicationService(
             trailRepository: WebVexCore.trailRepository,
             workflowRepository: WebVexCore.workflowRequestRepository,
           ),
       _auditRepository = auditRepository ?? WebVexCore.workflowAuditRepository,
       _firestore = firestore;

  final TrailParticipationApplicationService _applicationService;
  final WorkflowAuditRepository _auditRepository;
  final FirebaseFirestore? _firestore;

  String generateRequestId() {
    final firestore = _firestore ?? FirebaseFirestore.instance;
    return firestore
        .collection(WorkflowPaths.workflowRequestsCollection)
        .doc()
        .id;
  }

  Future<VenueTrailParticipationWorkspacePresentation> loadWorkspace({
    required User user,
    required VenueDashboardContext context,
  }) async {
    final actor = _actor(user, context);

    final eligibleResult = await _applicationService.listEligibleTrails(
      context: actor,
    );
    if (eligibleResult case TrailApplicationFailure(
      :final code,
      :final message,
    )) {
      return VenueTrailParticipationWorkspacePresentation.failure(
        code,
        message,
      );
    }

    final applicationsResult = await _applicationService
        .listApplicationsForVenue(context.venueId);
    if (applicationsResult case TrailApplicationFailure(
      :final code,
      :final message,
    )) {
      return VenueTrailParticipationWorkspacePresentation.failure(
        code,
        message,
      );
    }

    final eligible =
        (eligibleResult
                as TrailApplicationSuccess<
                  List<TrailParticipationEligibleTrail>
                >)
            .value;
    final applications =
        (applicationsResult
                as TrailApplicationSuccess<List<TrailParticipationApplication>>)
            .value;

    final trailLookup = _buildTrailLookup(eligible, applications);
    final missingTrailIds = applications
        .map((app) => app.trailId)
        .where((id) => !trailLookup.containsKey(id))
        .toSet()
        .toList();
    if (missingTrailIds.isNotEmpty) {
      await _loadMissingTrails(missingTrailIds, trailLookup);
    }

    final eligibleRows = [
      for (final item in eligible)
        _mapEligible(item, trailLookup, applications),
    ];

    final applicationRows = [
      for (final app in applications)
        await _mapApplication(
          application: app,
          trailLookup: trailLookup,
          eligible: eligible,
          managesVenue: true,
          ownsRequest: app.submittedByUid == user.uid,
          includeAudit: false,
        ),
    ];

    return VenueTrailParticipationWorkspacePresentation.success(
      eligible: eligibleRows,
      applications: applicationRows,
    );
  }

  Future<VenueTrailParticipationApplicationPresentation> loadApplicationDetail({
    required User user,
    required VenueDashboardContext context,
    required String requestId,
    List<TrailParticipationEligibleTrail>? eligibleCache,
    List<TrailParticipationApplication>? applicationsCache,
  }) async {
    final result = await _applicationService.getApplication(requestId);
    if (result case TrailApplicationFailure(:final code, :final message)) {
      throw VenueTrailParticipationException(code, message);
    }
    final application = (result as TrailApplicationSuccess).value;

    final trailLookup = <String, VenueTrailDisplayPresentation>{};
    if (eligibleCache != null) {
      trailLookup.addAll(_buildTrailLookup(eligibleCache, const []));
    }
    if (!trailLookup.containsKey(application.trailId)) {
      await _loadMissingTrails([application.trailId], trailLookup);
    }

    final audit = await _loadAudit(requestId);

    return _mapApplication(
      application: application,
      trailLookup: trailLookup,
      eligible: eligibleCache ?? const [],
      managesVenue: true,
      ownsRequest: application.submittedByUid == user.uid,
      includeAudit: true,
      auditTimeline: audit,
    );
  }

  Future<TrailParticipationApplication?> getApplicationForMutation(
    String requestId,
  ) async {
    final result = await _applicationService.getApplication(requestId);
    if (result case TrailApplicationFailure()) return null;
    return (result as TrailApplicationSuccess<TrailParticipationApplication>)
        .value;
  }

  Future<TrailApplicationResult<TrailParticipationApplication>> saveDraft({
    required User user,
    required VenueDashboardContext context,
    required String trailId,
    required int requestedStopOrder,
    required String participationNote,
    required String requestId,
  }) {
    return _applicationService.createDraft(
      context: _actor(user, context),
      trailId: trailId,
      payload: _payload(
        trailId: trailId,
        venueId: context.venueId,
        requestedStopOrder: requestedStopOrder,
        participationNote: participationNote,
      ),
      requestId: requestId,
    );
  }

  Future<TrailApplicationResult<TrailParticipationApplication>> updateDraft({
    required User user,
    required VenueDashboardContext context,
    required TrailParticipationApplication application,
    required int requestedStopOrder,
    required String participationNote,
  }) {
    return _applicationService.updateDraft(
      context: _actor(user, context),
      requestId: application.workflowRequestId,
      expectedRevision: application.revision,
      payload: _payload(
        trailId: application.trailId,
        venueId: application.venueId,
        requestedStopOrder: requestedStopOrder,
        participationNote: participationNote,
      ),
    );
  }

  Future<TrailApplicationResult<TrailParticipationApplication>> submitDraft({
    required User user,
    required VenueDashboardContext context,
    required TrailParticipationApplication application,
  }) {
    return _applicationService.submit(
      context: _actor(user, context),
      requestId: application.workflowRequestId,
      expectedRevision: application.revision,
    );
  }

  Future<TrailApplicationResult<TrailParticipationApplication>>
  createAndSubmitApplication({
    required User user,
    required VenueDashboardContext context,
    required String trailId,
    required int requestedStopOrder,
    required String participationNote,
    required String requestId,
  }) async {
    final draft = await saveDraft(
      user: user,
      context: context,
      trailId: trailId,
      requestedStopOrder: requestedStopOrder,
      participationNote: participationNote,
      requestId: requestId,
    );
    if (draft case TrailApplicationFailure()) return draft;
    final application = (draft as TrailApplicationSuccess).value;
    return submitDraft(user: user, context: context, application: application);
  }

  Future<TrailApplicationResult<TrailParticipationApplication>>
  resubmitApplication({
    required User user,
    required VenueDashboardContext context,
    required TrailParticipationApplication application,
    required int requestedStopOrder,
    required String participationNote,
  }) {
    return _applicationService.resubmit(
      context: _actor(user, context),
      requestId: application.workflowRequestId,
      payload: _payload(
        trailId: application.trailId,
        venueId: application.venueId,
        requestedStopOrder: requestedStopOrder,
        participationNote: participationNote,
      ),
      expectedRevision: application.revision,
    );
  }

  Future<TrailApplicationResult<TrailParticipationApplication>>
  withdrawApplication({
    required User user,
    required VenueDashboardContext context,
    required TrailParticipationApplication application,
    String? notes,
  }) {
    return _applicationService.withdraw(
      context: _actor(user, context),
      requestId: application.workflowRequestId,
      expectedRevision: application.revision,
      notes: notes,
    );
  }

  Future<List<VenueTrailParticipationAuditPresentation>> loadAuditTimeline(
    String requestId,
  ) {
    return _loadAudit(requestId);
  }

  TrailParticipationEligibilityResult assessTrailEligibility({
    required Trail trail,
    required String venueId,
    required List<WorkflowStatus> existingStatuses,
    required int requestedStopOrder,
  }) {
    return _applicationService.assessEligibility(
      trail: trail,
      venueId: venueId,
      venueIsManageable: true,
      existingApplicationStatuses: existingStatuses,
      requestedStopOrder: requestedStopOrder,
    );
  }

  Future<List<VenueTrailParticipationAuditPresentation>> _loadAudit(
    String requestId,
  ) async {
    final result = await _auditRepository.list(requestId);
    if (result case DataFailure()) return const [];
    return VenueTrailParticipationAuditMapper.mapSnapshots(
      (result as DataSuccess).value,
    );
  }

  Map<String, VenueTrailDisplayPresentation> _buildTrailLookup(
    List<TrailParticipationEligibleTrail> eligible,
    List<TrailParticipationApplication> applications,
  ) {
    return {
      for (final item in eligible) item.trail.id: _trailDisplay(item.trail),
    };
  }

  Future<void> _loadMissingTrails(
    List<String> trailIds,
    Map<String, VenueTrailDisplayPresentation> lookup,
  ) async {
    for (final trailId in trailIds) {
      if (lookup.containsKey(trailId)) continue;
      final result = await WebVexCore.trailRepository.get(trailId);
      if (result case DataSuccess(value: final snapshot)) {
        lookup[trailId] = VenueTrailDisplayPresentation(
          trailId: snapshot.trailId,
          name: snapshot.name,
          description: snapshot.description,
          bannerImageUrl: snapshot.bannerImageUrl,
          stopCount: snapshot.stops.length,
          maximumStops: snapshot.participationSettings.maximumStops,
          participationInstructions:
              snapshot.participationSettings.participationInstructions,
          acceptsApplications:
              snapshot.participationSettings.acceptsVenueApplications,
        );
      }
    }
  }

  VenueTrailEligiblePresentation _mapEligible(
    TrailParticipationEligibleTrail item,
    Map<String, VenueTrailDisplayPresentation> trailLookup,
    List<TrailParticipationApplication> applications,
  ) {
    final existing = applications
        .where((app) => app.trailId == item.trail.id)
        .map(
          (app) => _mapApplicationSync(
            application: app,
            trailLookup: trailLookup,
            eligible: [item],
            managesVenue: true,
            ownsRequest: true,
          ),
        )
        .cast<VenueTrailParticipationApplicationPresentation?>()
        .firstOrNull;

    final venueState = switch (true) {
      _ when item.eligibility.blockingReasons.contains('venue-already-stop') =>
        VenueTrailEligibleVenueState.alreadyIncluded,
      _ when item.existingApplication != null =>
        VenueTrailEligibleVenueState.requestPending,
      _ when item.eligibility.eligible => VenueTrailEligibleVenueState.eligible,
      _ => VenueTrailEligibleVenueState.notEligible,
    };

    return VenueTrailEligiblePresentation(
      trail: trailLookup[item.trail.id] ?? _trailDisplay(item.trail),
      eligible: item.eligibility.eligible,
      blockingReasons: item.eligibility.blockingReasons,
      validStopPositions: item.eligibility.validRequestedPositions,
      suggestedStopPosition: item.eligibility.suggestedPosition,
      venueState: venueState,
      existingApplication: existing,
    );
  }

  Future<VenueTrailParticipationApplicationPresentation> _mapApplication({
    required TrailParticipationApplication application,
    required Map<String, VenueTrailDisplayPresentation> trailLookup,
    required List<TrailParticipationEligibleTrail> eligible,
    required bool managesVenue,
    required bool ownsRequest,
    required bool includeAudit,
    List<VenueTrailParticipationAuditPresentation>? auditTimeline,
  }) async {
    final audit = includeAudit
        ? (auditTimeline ?? await _loadAudit(application.workflowRequestId))
        : const <VenueTrailParticipationAuditPresentation>[];

    return _mapApplicationSync(
      application: application,
      trailLookup: trailLookup,
      eligible: eligible,
      managesVenue: managesVenue,
      ownsRequest: ownsRequest,
      auditTimeline: audit,
    );
  }

  VenueTrailParticipationApplicationPresentation _mapApplicationSync({
    required TrailParticipationApplication application,
    required Map<String, VenueTrailDisplayPresentation> trailLookup,
    required List<TrailParticipationEligibleTrail> eligible,
    required bool managesVenue,
    required bool ownsRequest,
    List<VenueTrailParticipationAuditPresentation> auditTimeline = const [],
  }) {
    final trail = trailLookup[application.trailId];
    final eligibleTrail = eligible
        .where((item) => item.trail.id == application.trailId)
        .cast<TrailParticipationEligibleTrail?>()
        .firstOrNull;
    final trailEligibleForReapply =
        eligibleTrail?.eligibility.eligible ?? false;

    final actions = VenueTrailParticipationActionResolver.forApplication(
      workflowStatus: application.workflowStatus,
      managesVenue: managesVenue,
      ownsRequest: ownsRequest,
      trailEligibleForNewApplication: trailEligibleForReapply,
    );

    return VenueTrailParticipationApplicationPresentation(
      requestId: application.workflowRequestId,
      trailId: application.trailId,
      trailName: trail?.name ?? application.trailId,
      trailBannerUrl: trail?.bannerImageUrl ?? '',
      trailDescription: trail?.description ?? '',
      venueId: application.venueId,
      displayStatus: application.displayStatus,
      workflowStatus: application.workflowStatus,
      requestedStopOrder: application.requestedStopOrder,
      participationNote: application.participationNote,
      submittedAt: application.submittedAt,
      updatedAt: application.updatedAt,
      revision: application.revision,
      actions: actions,
      statusColor: _statusColor(application.displayStatus),
      informationRequestNote: application.informationRequestNote,
      decisionReason: application.decisionReason,
      auditTimeline: auditTimeline,
      trailStopCount: trail?.stopCount ?? 0,
      trailMaximumStops: trail?.maximumStops,
      trailParticipationInstructions: trail?.participationInstructions ?? '',
      trailApplicationWindowLabel: trail?.applicationWindowLabel ?? '',
      venueSelectableStopPosition:
          eligibleTrail
              ?.trail
              .participationSettings
              .venueSelectableStopPosition ??
          true,
    );
  }

  VenueTrailDisplayPresentation _trailDisplay(Trail trail) {
    return VenueTrailDisplayPresentation(
      trailId: trail.id,
      name: trail.name,
      description: trail.description,
      bannerImageUrl: trail.bannerImageUrl,
      stopCount: trail.effectiveVenueCount,
      maximumStops: trail.participationSettings.maximumStops,
      participationInstructions:
          trail.participationSettings.participationInstructions,
      acceptsApplications: trail.participationSettings.acceptsVenueApplications,
      applicationWindowLabel: _windowLabel(trail),
    );
  }

  String _windowLabel(Trail trail) {
    final opens = trail.participationSettings.participationApplicationOpensAt;
    final closes = trail.participationSettings.participationApplicationClosesAt;
    if (opens == null && closes == null) return 'Open while published';
    if (opens != null && closes != null) {
      return '${opens.day}/${opens.month} – ${closes.day}/${closes.month}';
    }
    if (closes != null) return 'Closes ${closes.day}/${closes.month}';
    return 'Opens ${opens!.day}/${opens.month}';
  }

  TrailParticipationSubmissionPayload _payload({
    required String trailId,
    required String venueId,
    required int requestedStopOrder,
    required String participationNote,
  }) {
    return TrailParticipationSubmissionPayload(
      schemaVersion: TrailParticipationSubmissionPayload.currentSchemaVersion,
      trailId: trailId,
      venueId: venueId,
      requestedStopOrder: requestedStopOrder,
      participationNote: participationNote.trim(),
    );
  }

  TrailParticipationActorContext _actor(
    User user,
    VenueDashboardContext context,
  ) {
    return TrailParticipationActorContext(
      actorUid: user.uid,
      venueId: context.venueId,
      managesVenue: true,
    );
  }

  Color _statusColor(TrailParticipationDisplayStatus status) {
    return switch (status) {
      TrailParticipationDisplayStatus.approved => AppColors.trailGold,
      TrailParticipationDisplayStatus.rejected ||
      TrailParticipationDisplayStatus.cancelled ||
      TrailParticipationDisplayStatus.expired => AppColors.textSecondary,
      TrailParticipationDisplayStatus.informationRequested =>
        AppColors.primaryPurple,
      _ => AppColors.primaryPink,
    };
  }
}

final class VenueTrailParticipationWorkspacePresentation {
  const VenueTrailParticipationWorkspacePresentation._({
    required this.ok,
    this.eligible = const [],
    this.applications = const [],
    this.errorCode,
    this.errorMessage,
  });

  factory VenueTrailParticipationWorkspacePresentation.success({
    required List<VenueTrailEligiblePresentation> eligible,
    required List<VenueTrailParticipationApplicationPresentation> applications,
  }) {
    return VenueTrailParticipationWorkspacePresentation._(
      ok: true,
      eligible: eligible,
      applications: applications,
    );
  }

  factory VenueTrailParticipationWorkspacePresentation.failure(
    String code,
    String message,
  ) {
    return VenueTrailParticipationWorkspacePresentation._(
      ok: false,
      errorCode: code,
      errorMessage: message,
    );
  }

  final bool ok;
  final List<VenueTrailEligiblePresentation> eligible;
  final List<VenueTrailParticipationApplicationPresentation> applications;
  final String? errorCode;
  final String? errorMessage;
}

final class VenueTrailParticipationException implements Exception {
  const VenueTrailParticipationException(this.code, this.message);

  final String code;
  final String message;

  bool get isRevisionConflict =>
      code.contains('revision') || message.toLowerCase().contains('revision');
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
