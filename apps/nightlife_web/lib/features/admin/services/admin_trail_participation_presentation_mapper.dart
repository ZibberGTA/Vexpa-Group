import 'package:vex_engines/trail/domain/participation/trail_participation_application.dart';
import 'package:vex_engines/trail/domain/participation/trail_participation_display_status.dart';
import 'package:vex_engines/trail/domain/participation/trail_participation_eligibility_policy.dart';
import 'package:vex_engines/trail/domain/trail.dart';
import 'package:vex_engines/workflow/domain/workflow_status.dart';
import 'package:vex_core/workflow/workflow.dart';

import '../models/admin_trail_participation_review_presentation.dart';
import '../services/admin_trail_participation_action_resolver.dart';
import '../services/admin_trail_participation_audit_mapper.dart';

/// Maps participation domain data into administrator presentation models.
abstract final class AdminTrailParticipationPresentationMapper {
  static AdminTrailParticipationInboxItemPresentation mapInboxItem({
    required TrailParticipationApplication application,
    required String venueName,
    required String trailName,
    required bool canManage,
    required List<WorkflowAuditEntrySnapshot> auditSnapshots,
  }) {
    final displayStatus = application.displayStatus;
    final actions = AdminTrailParticipationActionResolver.forRequest(
      workflowStatus: application.workflowStatus,
      canManage: canManage,
    );
    final primary = AdminTrailParticipationActionResolver.primaryAction(
      actions,
    );

    return AdminTrailParticipationInboxItemPresentation(
      requestId: application.workflowRequestId,
      venueId: application.venueId,
      venueName: venueName,
      trailId: application.trailId,
      trailName: trailName,
      requestedStopOrder: application.requestedStopOrder,
      displayStatus: displayStatus,
      workflowStatus: application.workflowStatus,
      statusLabel: TrailParticipationDisplayStatusMapper.label(displayStatus),
      submittedAt: application.submittedAt,
      updatedAt: application.updatedAt,
      revision: application.revision,
      wasResubmitted: AdminTrailParticipationAuditMapper.wasResubmitted(
        auditSnapshots,
      ),
      actions: actions,
      primaryActionLabel: primary == null
          ? 'View'
          : AdminTrailParticipationActionResolver.label(primary),
    );
  }

  static AdminTrailParticipationRequestDetailPresentation mapDetail({
    required TrailParticipationApplication application,
    required String venueName,
    required Trail? trail,
    required bool canManage,
    required List<WorkflowAuditEntrySnapshot> auditSnapshots,
    required TrailParticipationEligibilityResult eligibility,
  }) {
    final auditTimeline = AdminTrailParticipationAuditMapper.mapSnapshots(
      auditSnapshots,
    );
    final actions = AdminTrailParticipationActionResolver.forRequest(
      workflowStatus: application.workflowStatus,
      canManage: canManage,
    );
    final approvalPlan = _approvalPlan(
      application: application,
      trail: trail,
      eligibility: eligibility,
    );

    return AdminTrailParticipationRequestDetailPresentation(
      requestId: application.workflowRequestId,
      venueId: application.venueId,
      venueName: venueName,
      trailId: application.trailId,
      trailName: trail?.name ?? application.trailId,
      trailDescription: trail?.description ?? '',
      trailStopCount: trail?.effectiveVenueCount ?? 0,
      trailMaximumStops: trail?.participationSettings.maximumStops,
      requestedStopOrder: application.requestedStopOrder,
      participationNote: application.participationNote,
      displayStatus: application.displayStatus,
      workflowStatus: application.workflowStatus,
      statusLabel: TrailParticipationDisplayStatusMapper.label(
        application.displayStatus,
      ),
      revision: application.revision,
      submittedAt: application.submittedAt,
      updatedAt: application.updatedAt,
      decidedAt: application.decidedAt,
      informationRequestNote: application.informationRequestNote,
      decisionReason: application.decisionReason,
      wasResubmitted: AdminTrailParticipationAuditMapper.wasResubmitted(
        auditSnapshots,
      ),
      actions: actions,
      auditTimeline: auditTimeline,
      eligibilityWarnings: [
        ...eligibility.blockingReasons,
        ...eligibility.warnings,
      ],
      approvalPlan: approvalPlan,
    );
  }

  static AdminTrailParticipationApprovalPlanPresentation? _approvalPlan({
    required TrailParticipationApplication application,
    required Trail? trail,
    required TrailParticipationEligibilityResult eligibility,
  }) {
    final status = application.workflowStatus;
    if (status != WorkflowStatus.submitted &&
        status != WorkflowStatus.underReview) {
      return null;
    }

    return AdminTrailParticipationApprovalPlanPresentation(
      requestId: application.workflowRequestId,
      trailId: application.trailId,
      venueId: application.venueId,
      approvedRequestedStopOrder: application.requestedStopOrder,
      proposedInsertionOrder: application.requestedStopOrder,
      requiresManualPlacement: true,
      trailWillBeMutated: false,
      conflictWarnings: [
        ...eligibility.blockingReasons,
        ...eligibility.warnings,
      ],
    );
  }
}
