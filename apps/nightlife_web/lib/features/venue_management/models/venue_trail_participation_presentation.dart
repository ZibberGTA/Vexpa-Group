import 'package:flutter/material.dart';
import 'package:vex_engines/trail/domain/participation/trail_participation_display_status.dart';
import 'package:vex_engines/workflow/domain/workflow_status.dart';

import '../services/venue_trail_participation_action_resolver.dart';

/// Trail display information for participation UI.
final class VenueTrailDisplayPresentation {
  const VenueTrailDisplayPresentation({
    required this.trailId,
    required this.name,
    required this.description,
    required this.bannerImageUrl,
    required this.stopCount,
    this.maximumStops,
    this.participationInstructions = '',
    this.acceptsApplications = false,
    this.applicationWindowLabel = '',
  });

  final String trailId;
  final String name;
  final String description;
  final String bannerImageUrl;
  final int stopCount;
  final int? maximumStops;
  final String participationInstructions;
  final bool acceptsApplications;
  final String applicationWindowLabel;
}

/// Eligible trail row for discovery UI.
final class VenueTrailEligiblePresentation {
  const VenueTrailEligiblePresentation({
    required this.trail,
    required this.eligible,
    required this.blockingReasons,
    required this.validStopPositions,
    required this.suggestedStopPosition,
    required this.venueState,
    this.existingApplication,
  });

  final VenueTrailDisplayPresentation trail;
  final bool eligible;
  final List<String> blockingReasons;
  final List<int> validStopPositions;
  final int? suggestedStopPosition;
  final VenueTrailEligibleVenueState venueState;
  final VenueTrailParticipationApplicationPresentation? existingApplication;
}

enum VenueTrailEligibleVenueState {
  eligible,
  alreadyIncluded,
  notEligible,
  requestPending,
}

/// Audit timeline row for venue-visible workflow history.
final class VenueTrailParticipationAuditPresentation {
  const VenueTrailParticipationAuditPresentation({
    required this.auditId,
    required this.displayAction,
    required this.timestamp,
    required this.actorLabel,
    this.note,
    this.revision,
  });

  final String auditId;
  final String displayAction;
  final DateTime timestamp;
  final String actorLabel;
  final String? note;
  final int? revision;
}

/// UI-facing participation application model.
final class VenueTrailParticipationApplicationPresentation {
  const VenueTrailParticipationApplicationPresentation({
    required this.requestId,
    required this.trailId,
    required this.trailName,
    required this.trailBannerUrl,
    required this.trailDescription,
    required this.venueId,
    required this.displayStatus,
    required this.workflowStatus,
    required this.requestedStopOrder,
    required this.participationNote,
    required this.submittedAt,
    required this.updatedAt,
    required this.revision,
    required this.actions,
    required this.statusColor,
    this.informationRequestNote,
    this.decisionReason,
    this.auditTimeline = const [],
    this.warnings = const [],
    this.trailStopCount = 0,
    this.trailMaximumStops,
    this.trailParticipationInstructions = '',
    this.trailApplicationWindowLabel = '',
    this.venueSelectableStopPosition = true,
  });

  final String requestId;
  final String trailId;
  final String trailName;
  final String trailBannerUrl;
  final String trailDescription;
  final String venueId;
  final TrailParticipationDisplayStatus displayStatus;
  final WorkflowStatus workflowStatus;
  final int requestedStopOrder;
  final String participationNote;
  final DateTime? submittedAt;
  final DateTime updatedAt;
  final int revision;
  final List<VenueTrailParticipationAction> actions;
  final Color statusColor;
  final String? informationRequestNote;
  final String? decisionReason;
  final List<VenueTrailParticipationAuditPresentation> auditTimeline;
  final List<String> warnings;
  final int trailStopCount;
  final int? trailMaximumStops;
  final String trailParticipationInstructions;
  final String trailApplicationWindowLabel;
  final bool venueSelectableStopPosition;

  String get statusLabel =>
      TrailParticipationDisplayStatusMapper.label(displayStatus);

  String get actionGuidance =>
      TrailParticipationDisplayStatusMapper.actionGuidance(displayStatus);

  String get positionLabel => 'Stop $requestedStopOrder';

  bool get isEditable =>
      actions.contains(VenueTrailParticipationAction.editDraft) ||
      actions.contains(VenueTrailParticipationAction.respond);

  bool get canSubmit => actions.contains(VenueTrailParticipationAction.submit);

  bool get canResubmit =>
      actions.contains(VenueTrailParticipationAction.resubmit);

  bool get canWithdraw =>
      actions.contains(VenueTrailParticipationAction.withdraw);

  VenueTrailParticipationAction? get primaryAction =>
      actions.isEmpty ? null : actions.first;
}
