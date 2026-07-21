import 'package:vex_core/data/data_result.dart';
import 'package:vex_core/trails/trails.dart';
import 'package:vex_core/venue/venue_repository.dart';
import 'package:vex_core/workflow/workflow.dart';
import 'package:vex_engines/trail/application/participation/trail_participation_application_mapper.dart';
import 'package:vex_engines/trail/application/participation/trail_participation_application_service.dart';
import 'package:vex_engines/trail/domain/participation/trail_participation_application.dart';
import 'package:vex_engines/trail/domain/participation/trail_participation_eligibility_policy.dart';
import 'package:vex_engines/trail/domain/trail.dart';
import 'package:vex_engines/trail/domain/trail_result.dart';
import 'package:vex_engines/trail/shared/trail_snapshot_mapper.dart';
import 'package:vex_engines/workflow/domain/workflow_actor.dart';
import 'package:vex_engines/workflow/domain/workflow_status.dart';
import 'package:vex_engines/workflow/shared/shared.dart';

import '../../../core/vexcore/web_vexcore.dart';
import '../models/admin_trail_participation_review_presentation.dart';
import '../services/admin_trail_participation_presentation_mapper.dart';

/// Administrator repository for trail participation review workflows.
class AdminTrailParticipationReviewRepository {
  AdminTrailParticipationReviewRepository({
    WorkflowRequestRepository? workflowRequestRepository,
    WorkflowCommandGateway? workflowCommandGateway,
    WorkflowAuditRepository? workflowAuditRepository,
    TrailRepository? trailRepository,
    VenueRepository? venueRepository,
    TrailParticipationApplicationService? applicationService,
  }) : _workflowRequestRepository =
           workflowRequestRepository ?? WebVexCore.workflowRequestRepository,
       _workflowCommandGateway =
           workflowCommandGateway ?? WebVexCore.workflowCommandGateway,
       _workflowAuditRepository =
           workflowAuditRepository ?? WebVexCore.workflowAuditRepository,
       _trailRepository = trailRepository ?? WebVexCore.trailRepository,
       _venueRepository = venueRepository ?? WebVexCore.venueRepository,
       _applicationService =
           applicationService ??
           TrailParticipationApplicationService(
             trailRepository: trailRepository ?? WebVexCore.trailRepository,
             workflowRepository:
                 workflowRequestRepository ??
                 WebVexCore.workflowRequestRepository,
           );

  final WorkflowRequestRepository _workflowRequestRepository;
  final WorkflowCommandGateway _workflowCommandGateway;
  final WorkflowAuditRepository _workflowAuditRepository;
  final TrailRepository _trailRepository;
  final VenueRepository _venueRepository;
  final TrailParticipationApplicationService _applicationService;

  static const reviewReadyStatuses = <String>[
    'submitted',
    'under_review',
    'information_requested',
  ];

  Future<AdminTrailParticipationInboxPresentation> loadInbox({
    required String actorUid,
    required bool canView,
    required bool canManage,
    AdminTrailParticipationInboxFilters filters =
        const AdminTrailParticipationInboxFilters(),
  }) async {
    if (!canView) {
      return AdminTrailParticipationInboxPresentation.failure(
        errorCode: 'permission-denied',
        errorMessage: 'You do not have permission to view participation reviews.',
        isPermissionDenied: true,
      );
    }

    final statuses = filters.statusFilter == 'All'
        ? reviewReadyStatuses
        : [_statusPersistence(filters.statusFilter)];

    final listResult = await _workflowRequestRepository.list(
      WorkflowListQuery(
        workflowType: WorkflowTypeIds.trailVenueParticipation,
        statuses: statuses,
        limit: 200,
      ),
    );

    if (listResult case DataFailure(error: final error)) {
      return AdminTrailParticipationInboxPresentation.failure(
        errorCode: error.code ?? 'workflow-list-failed',
        errorMessage: error.message,
      );
    }

    final snapshots = (listResult as DataSuccess).value;
    final applications = _mapApplications(snapshots);
    final venueNames = await _loadVenueNames(
      applications.map((app) => app.venueId).toSet(),
    );
    final trailNames = await _loadTrailNames(
      applications.map((app) => app.trailId).toSet(),
    );

    final items = <AdminTrailParticipationInboxItemPresentation>[];
    for (final application in applications) {
      final audit = await _loadAuditSnapshots(application.workflowRequestId);
      items.add(
        AdminTrailParticipationPresentationMapper.mapInboxItem(
          application: application,
          venueName: venueNames[application.venueId] ?? application.venueId,
          trailName: trailNames[application.trailId] ?? application.trailId,
          canManage: canManage,
          auditSnapshots: audit,
        ),
      );
    }

    final filtered = _applyInboxFilters(items, filters);
    _sortInbox(filtered, filters.oldestFirst);

    final trailFilters = {
      for (final item in items) item.trailName,
    }.toList()..sort();

    return AdminTrailParticipationInboxPresentation.success(
      items: filtered,
      availableTrailFilters: trailFilters,
    );
  }

  Future<AdminTrailParticipationDetailLoadResult> loadDetail({
    required String requestId,
    required bool canView,
    required bool canManage,
  }) async {
    if (!canView) {
      return AdminTrailParticipationDetailLoadResult.failure(
        errorCode: 'permission-denied',
        errorMessage: 'You do not have permission to view this request.',
        isPermissionDenied: true,
      );
    }

    final applicationResult = await _loadApplication(requestId);
    if (applicationResult == null) {
      return AdminTrailParticipationDetailLoadResult.failure(
        errorCode: 'workflow-not-found',
        errorMessage: 'This participation request is no longer available.',
        isNotFound: true,
      );
    }

    final application = applicationResult;
    final trail = await _loadTrail(application.trailId);
    final venueName =
        (await _loadVenueNames({application.venueId}))[application.venueId] ??
        application.venueId;
    final audit = await _loadAuditSnapshots(requestId);
    final eligibility = trail == null
        ? const TrailParticipationEligibilityResult(
            eligible: false,
            warnings: ['Trail details could not be loaded for validation.'],
          )
        : _applicationService.assessEligibility(
            trail: trail,
            venueId: application.venueId,
            venueIsManageable: true,
            existingApplicationStatuses: const [],
            requestedStopOrder: application.requestedStopOrder,
          );

    return AdminTrailParticipationDetailLoadResult.success(
      AdminTrailParticipationPresentationMapper.mapDetail(
        application: application,
        venueName: venueName,
        trail: trail,
        canManage: canManage,
        auditSnapshots: audit,
        eligibility: eligibility,
      ),
    );
  }

  Future<AdminTrailParticipationDecisionResult> requestInformation({
    required String actorUid,
    required bool canManage,
    required AdminTrailParticipationRequestDetailPresentation detail,
    required String reviewerNote,
  }) {
    return _invokeReviewCommand(
      actorUid: actorUid,
      canManage: canManage,
      detail: detail,
      reviewerNote: reviewerNote,
      noteRequired: true,
      buildCommand: (actor, revision) => RequestWorkflowInformationCommand(
        requestId: detail.requestId,
        expectedRevision: revision,
        actor: actor,
        notes: reviewerNote.trim(),
      ),
    );
  }

  Future<AdminTrailParticipationDecisionResult> approve({
    required String actorUid,
    required bool canManage,
    required AdminTrailParticipationRequestDetailPresentation detail,
    String? administratorNote,
  }) {
    return _invokeReviewCommand(
      actorUid: actorUid,
      canManage: canManage,
      detail: detail,
      reviewerNote: administratorNote,
      noteRequired: false,
      buildCommand: (actor, revision) => ApproveWorkflowCommand(
        requestId: detail.requestId,
        expectedRevision: revision,
        actor: actor,
        notes: administratorNote?.trim(),
        reason: administratorNote?.trim(),
        decisionCode: 'approved',
      ),
    );
  }

  Future<AdminTrailParticipationDecisionResult> reject({
    required String actorUid,
    required bool canManage,
    required AdminTrailParticipationRequestDetailPresentation detail,
    required String rejectionReason,
  }) {
    return _invokeReviewCommand(
      actorUid: actorUid,
      canManage: canManage,
      detail: detail,
      reviewerNote: rejectionReason,
      noteRequired: true,
      buildCommand: (actor, revision) => RejectWorkflowCommand(
        requestId: detail.requestId,
        expectedRevision: revision,
        actor: actor,
        notes: rejectionReason.trim(),
        reason: rejectionReason.trim(),
        decisionCode: 'rejected',
      ),
    );
  }

  Future<AdminTrailParticipationDecisionResult> _invokeReviewCommand({
    required String actorUid,
    required bool canManage,
    required AdminTrailParticipationRequestDetailPresentation detail,
    required WorkflowPrivilegedCommand Function(
      WorkflowActorContext actor,
      int revision,
    )
    buildCommand,
    required String? reviewerNote,
    required bool noteRequired,
  }) async {
    if (!canManage) {
      return AdminTrailParticipationDecisionResult.failure(
        errorCode: 'permission-denied',
        errorMessage: 'You do not have permission to perform this review action.',
        isPermissionDenied: true,
      );
    }

    if (noteRequired && (reviewerNote == null || reviewerNote.trim().isEmpty)) {
      return AdminTrailParticipationDecisionResult.failure(
        errorCode: 'note-required',
        errorMessage: 'A reviewer note is required.',
      );
    }

    final actor = WorkflowActorContext(
      uid: actorUid,
      kind: WorkflowActorKind.admin.persistenceValue,
    );
    final command = buildCommand(actor, detail.revision);
    final result = await _workflowCommandGateway.invoke(command);
    return _mapDecisionResult(
      result,
      canView: true,
      canManage: canManage,
      requestId: detail.requestId,
    );
  }

  Future<AdminTrailParticipationDecisionResult> _mapDecisionResult(
    DataResult<WorkflowRequestSnapshot> result, {
    required bool canView,
    required bool canManage,
    required String requestId,
  }) async {
    if (result case DataFailure(error: final error)) {
      final isRevisionConflict = error.code == 'workflow-revision-conflict';
      AdminTrailParticipationRequestDetailPresentation? refreshed;
      if (isRevisionConflict) {
        refreshed = (await loadDetail(
          requestId: requestId,
          canView: canView,
          canManage: canManage,
        )).detail;
      }
      return AdminTrailParticipationDecisionResult.failure(
        errorCode: error.code ?? 'workflow-command-failed',
        errorMessage: isRevisionConflict
            ? 'This request was updated by someone else. Review the latest revision before acting again.'
            : error.message,
        isRevisionConflict: isRevisionConflict,
        isPermissionDenied: error.code == 'workflow-permission-denied',
        refreshedDetail: refreshed,
      );
    }

    final refreshed = (await loadDetail(
      requestId: requestId,
      canView: canView,
      canManage: canManage,
    )).detail;

    return AdminTrailParticipationDecisionResult.success(
      refreshedDetail: refreshed,
    );
  }

  List<TrailParticipationApplication> _mapApplications(
    List<WorkflowRequestSnapshot> snapshots,
  ) {
    final mapped = <TrailParticipationApplication>[];
    for (final snapshot in snapshots) {
      final application =
          TrailParticipationApplicationMapper.fromWorkflowSnapshot(snapshot);
      if (application == null) continue;
      if (application.workflowStatus == WorkflowStatus.draft) continue;
      mapped.add(application);
    }
    return mapped;
  }

  Future<TrailParticipationApplication?> _loadApplication(String requestId) async {
    final result = await _workflowRequestRepository.get(requestId);
    if (result case DataFailure()) return null;
    return TrailParticipationApplicationMapper.fromWorkflowSnapshot(
      (result as DataSuccess).value,
    );
  }

  Future<List<WorkflowAuditEntrySnapshot>> _loadAuditSnapshots(
    String requestId,
  ) async {
    final result = await _workflowAuditRepository.list(requestId);
    if (result case DataFailure()) return const [];
    return (result as DataSuccess).value;
  }

  Future<Map<String, String>> _loadVenueNames(Set<String> venueIds) async {
    final names = <String, String>{};
    for (final venueId in venueIds) {
      if (venueId.trim().isEmpty) continue;
      final result = await _venueRepository.findById(venueId);
      if (result case DataSuccess(value: final venue?)) {
        names[venueId] = venue.name;
      }
    }
    return names;
  }

  Future<Map<String, String>> _loadTrailNames(Set<String> trailIds) async {
    final names = <String, String>{};
    for (final trailId in trailIds) {
      if (trailId.trim().isEmpty) continue;
      final trail = await _loadTrail(trailId);
      if (trail != null) names[trailId] = trail.name;
    }
    return names;
  }

  Future<Trail?> _loadTrail(String trailId) async {
    final result = await _trailRepository.get(trailId);
    if (result case DataFailure()) return null;
    final mapped = TrailSnapshotMapper.toDomain((result as DataSuccess).value);
    if (mapped case TrailSuccess<Trail>(:final value)) return value;
    return null;
  }

  List<AdminTrailParticipationInboxItemPresentation> _applyInboxFilters(
    List<AdminTrailParticipationInboxItemPresentation> items,
    AdminTrailParticipationInboxFilters filters,
  ) {
    final search = filters.venueSearch.trim().toLowerCase();
    return [
      for (final item in items)
        if (filters.trailFilter == 'All' || item.trailName == filters.trailFilter)
          if (search.isEmpty ||
              item.venueName.toLowerCase().contains(search) ||
              item.venueId.toLowerCase().contains(search))
            item,
    ];
  }

  void _sortInbox(
    List<AdminTrailParticipationInboxItemPresentation> items,
    bool oldestFirst,
  ) {
    items.sort((a, b) {
      final aDate = a.submittedAt ?? a.updatedAt;
      final bDate = b.submittedAt ?? b.updatedAt;
      return oldestFirst ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
    });
  }

  String _statusPersistence(String label) {
    return switch (label) {
      'Submitted' => 'submitted',
      'Under review' => 'under_review',
      'Information requested' => 'information_requested',
      _ => label.toLowerCase().replaceAll(' ', '_'),
    };
  }
}
