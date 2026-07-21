import 'package:vex_core/workflow/workflow.dart';

import '../models/venue_trail_participation_presentation.dart';

/// Maps workflow audit snapshots to venue-visible timeline labels.
abstract final class VenueTrailParticipationAuditMapper {
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

  static String actorLabel(String actorKind) {
    return switch (actorKind) {
      'submitter' => 'Venue',
      'reviewer' => 'Reviewer',
      'admin' => 'Administrator',
      'system' => 'System',
      _ => 'Participant',
    };
  }

  static List<VenueTrailParticipationAuditPresentation> mapSnapshots(
    List<WorkflowAuditEntrySnapshot> snapshots,
  ) {
    return [
      for (final entry in snapshots)
        VenueTrailParticipationAuditPresentation(
          auditId: entry.auditId,
          displayAction: displayAction(entry.action),
          timestamp: entry.createdAt,
          actorLabel: actorLabel(entry.actorKind),
          note: entry.notes ?? entry.reason,
          revision: _readRevision(entry.metadata),
        ),
    ];
  }

  static int? _readRevision(Map<String, Object?> metadata) {
    final value = metadata['revision'];
    if (value is num) return value.toInt();
    return null;
  }
}
