import 'package:vex_core/workflow/workflow.dart';
import 'package:vex_engines/trail/domain/participation/trail_participation_display_status.dart';
import 'package:vex_engines/workflow/domain/workflow_result.dart';
import 'package:vex_engines/workflow/domain/workflow_status.dart';

import '../models/admin_trail_participation_review_presentation.dart';

/// Maps workflow audit snapshots to administrator timeline entries.
abstract final class AdminTrailParticipationAuditMapper {
  static List<AdminTrailParticipationAuditPresentation> mapSnapshots(
    List<WorkflowAuditEntrySnapshot> snapshots,
  ) {
    final sorted = [...snapshots]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return [
      for (final entry in sorted) mapSnapshot(entry),
    ];
  }

  static AdminTrailParticipationAuditPresentation mapSnapshot(
    WorkflowAuditEntrySnapshot entry,
  ) {
    return AdminTrailParticipationAuditPresentation(
      auditId: entry.auditId,
      displayAction: displayAction(entry.action),
      timestamp: entry.createdAt,
      actorLabel: actorLabel(entry.actorKind, entry.actorUid),
      actorRole: actorRole(entry.actorKind),
      note: _note(entry),
      revision: _readRevision(entry.metadata),
      fromStatusLabel: _statusLabel(entry.fromStatus),
      toStatusLabel: _statusLabel(entry.toStatus),
    );
  }

  static String displayAction(String persistenceAction) {
    return switch (persistenceAction) {
      'draft_created' => 'Draft created',
      'draft_updated' => 'Draft updated',
      'submitted' => 'Submitted',
      'resubmitted' => 'Resubmitted',
      'information_requested' => 'Information requested',
      'review_started' => 'Review started',
      'approved' => 'Approved',
      'rejected' => 'Rejected',
      'withdrawn' => 'Withdrawn',
      'cancelled' => 'Cancelled',
      'expired' => 'Expired',
      'reviewer_assigned' => 'Reviewer assigned',
      _ => persistenceAction.replaceAll('_', ' '),
    };
  }

  static String actorLabel(String actorKind, String actorUid) {
    final role = actorRole(actorKind);
    if (actorUid.trim().isEmpty) return role;
    return '$role · ${actorUid.trim()}';
  }

  static String actorRole(String actorKind) {
    return switch (actorKind) {
      'submitter' => 'Venue',
      'reviewer' => 'Reviewer',
      'admin' => 'Administrator',
      'system' => 'System',
      _ => 'Participant',
    };
  }

  static bool wasResubmitted(List<WorkflowAuditEntrySnapshot> snapshots) {
    return snapshots.any((entry) => entry.action == 'resubmitted');
  }

  static String? _note(WorkflowAuditEntrySnapshot entry) {
    final notes = entry.notes?.trim();
    if (notes != null && notes.isNotEmpty) return notes;
    final reason = entry.reason?.trim();
    if (reason != null && reason.isNotEmpty) return reason;
    return null;
  }

  static int? _readRevision(Map<String, Object?> metadata) {
    final value = metadata['revision'];
    if (value is num) return value.toInt();
    return null;
  }

  static String? _statusLabel(String? persistenceStatus) {
    if (persistenceStatus == null || persistenceStatus.trim().isEmpty) {
      return null;
    }
    final parsed = WorkflowStatusTransitions.parsePersistenceValue(
      persistenceStatus,
    );
    if (parsed case WorkflowSuccess<WorkflowStatus>(:final value)) {
      return TrailParticipationDisplayStatusMapper.label(
        TrailParticipationDisplayStatusMapper.fromWorkflowStatus(value),
      );
    }
    return persistenceStatus.replaceAll('_', ' ');
  }
}
