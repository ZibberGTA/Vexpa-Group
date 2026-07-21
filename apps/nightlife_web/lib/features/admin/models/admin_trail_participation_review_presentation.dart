import 'package:flutter/material.dart';
import 'package:vex_engines/trail/domain/participation/trail_participation_display_status.dart';
import 'package:vex_engines/workflow/domain/workflow_status.dart';

import '../services/admin_trail_participation_action_resolver.dart';

/// Administrator inbox row for a participation review request.
final class AdminTrailParticipationInboxItemPresentation {
  const AdminTrailParticipationInboxItemPresentation({
    required this.requestId,
    required this.venueId,
    required this.venueName,
    required this.trailId,
    required this.trailName,
    required this.requestedStopOrder,
    required this.displayStatus,
    required this.workflowStatus,
    required this.statusLabel,
    required this.submittedAt,
    required this.updatedAt,
    required this.revision,
    required this.wasResubmitted,
    required this.actions,
    required this.primaryActionLabel,
  });

  final String requestId;
  final String venueId;
  final String venueName;
  final String trailId;
  final String trailName;
  final int requestedStopOrder;
  final TrailParticipationDisplayStatus displayStatus;
  final WorkflowStatus workflowStatus;
  final String statusLabel;
  final DateTime? submittedAt;
  final DateTime updatedAt;
  final int revision;
  final bool wasResubmitted;
  final List<AdminTrailParticipationAction> actions;
  final String primaryActionLabel;

  String get stopLabel => 'Stop $requestedStopOrder';
}

/// Filter state for the administrator review inbox.
final class AdminTrailParticipationInboxFilters {
  const AdminTrailParticipationInboxFilters({
    this.statusFilter = 'All',
    this.trailFilter = 'All',
    this.venueSearch = '',
    this.oldestFirst = true,
  });

  final String statusFilter;
  final String trailFilter;
  final String venueSearch;
  final bool oldestFirst;

  AdminTrailParticipationInboxFilters copyWith({
    String? statusFilter,
    String? trailFilter,
    String? venueSearch,
    bool? oldestFirst,
  }) {
    return AdminTrailParticipationInboxFilters(
      statusFilter: statusFilter ?? this.statusFilter,
      trailFilter: trailFilter ?? this.trailFilter,
      venueSearch: venueSearch ?? this.venueSearch,
      oldestFirst: oldestFirst ?? this.oldestFirst,
    );
  }
}

/// Planned trail placement shown before approval confirmation.
final class AdminTrailParticipationApprovalPlanPresentation {
  const AdminTrailParticipationApprovalPlanPresentation({
    required this.requestId,
    required this.trailId,
    required this.venueId,
    required this.approvedRequestedStopOrder,
    required this.proposedInsertionOrder,
    required this.requiresManualPlacement,
    required this.trailWillBeMutated,
    this.conflictWarnings = const [],
  });

  final String requestId;
  final String trailId;
  final String venueId;
  final int approvedRequestedStopOrder;
  final int proposedInsertionOrder;
  final bool requiresManualPlacement;
  final bool trailWillBeMutated;
  final List<String> conflictWarnings;
}

/// Administrator-visible audit timeline entry.
final class AdminTrailParticipationAuditPresentation {
  const AdminTrailParticipationAuditPresentation({
    required this.auditId,
    required this.displayAction,
    required this.timestamp,
    required this.actorLabel,
    required this.actorRole,
    this.note,
    this.revision,
    this.fromStatusLabel,
    this.toStatusLabel,
  });

  final String auditId;
  final String displayAction;
  final DateTime timestamp;
  final String actorLabel;
  final String actorRole;
  final String? note;
  final int? revision;
  final String? fromStatusLabel;
  final String? toStatusLabel;
}

/// Full administrator detail for a participation request.
final class AdminTrailParticipationRequestDetailPresentation {
  const AdminTrailParticipationRequestDetailPresentation({
    required this.requestId,
    required this.venueId,
    required this.venueName,
    required this.trailId,
    required this.trailName,
    required this.trailDescription,
    required this.trailStopCount,
    required this.trailMaximumStops,
    required this.requestedStopOrder,
    required this.participationNote,
    required this.displayStatus,
    required this.workflowStatus,
    required this.statusLabel,
    required this.revision,
    required this.submittedAt,
    required this.updatedAt,
    required this.decidedAt,
    required this.informationRequestNote,
    required this.decisionReason,
    required this.wasResubmitted,
    required this.actions,
    required this.auditTimeline,
    required this.eligibilityWarnings,
    this.approvalPlan,
  });

  final String requestId;
  final String venueId;
  final String venueName;
  final String trailId;
  final String trailName;
  final String trailDescription;
  final int trailStopCount;
  final int? trailMaximumStops;
  final int requestedStopOrder;
  final String participationNote;
  final TrailParticipationDisplayStatus displayStatus;
  final WorkflowStatus workflowStatus;
  final String statusLabel;
  final int revision;
  final DateTime? submittedAt;
  final DateTime updatedAt;
  final DateTime? decidedAt;
  final String? informationRequestNote;
  final String? decisionReason;
  final bool wasResubmitted;
  final List<AdminTrailParticipationAction> actions;
  final List<AdminTrailParticipationAuditPresentation> auditTimeline;
  final List<String> eligibilityWarnings;
  final AdminTrailParticipationApprovalPlanPresentation? approvalPlan;
}

/// Result of an administrator decision command.
final class AdminTrailParticipationDecisionResult {
  const AdminTrailParticipationDecisionResult._({
    required this.ok,
    this.errorCode,
    this.errorMessage,
    this.isRevisionConflict = false,
    this.isPermissionDenied = false,
    this.refreshedDetail,
  });

  factory AdminTrailParticipationDecisionResult.success({
    AdminTrailParticipationRequestDetailPresentation? refreshedDetail,
  }) {
    return AdminTrailParticipationDecisionResult._(
      ok: true,
      refreshedDetail: refreshedDetail,
    );
  }

  factory AdminTrailParticipationDecisionResult.failure({
    required String errorCode,
    required String errorMessage,
    bool isRevisionConflict = false,
    bool isPermissionDenied = false,
    AdminTrailParticipationRequestDetailPresentation? refreshedDetail,
  }) {
    return AdminTrailParticipationDecisionResult._(
      ok: false,
      errorCode: errorCode,
      errorMessage: errorMessage,
      isRevisionConflict: isRevisionConflict,
      isPermissionDenied: isPermissionDenied,
      refreshedDetail: refreshedDetail,
    );
  }

  final bool ok;
  final String? errorCode;
  final String? errorMessage;
  final bool isRevisionConflict;
  final bool isPermissionDenied;
  final AdminTrailParticipationRequestDetailPresentation? refreshedDetail;
}

/// Loaded administrator inbox presentation.
final class AdminTrailParticipationInboxPresentation {
  const AdminTrailParticipationInboxPresentation._({
    required this.ok,
    this.items = const [],
    this.availableTrailFilters = const [],
    this.errorCode,
    this.errorMessage,
    this.isPermissionDenied = false,
  });

  factory AdminTrailParticipationInboxPresentation.success({
    required List<AdminTrailParticipationInboxItemPresentation> items,
    required List<String> availableTrailFilters,
  }) {
    return AdminTrailParticipationInboxPresentation._(
      ok: true,
      items: items,
      availableTrailFilters: availableTrailFilters,
    );
  }

  factory AdminTrailParticipationInboxPresentation.failure({
    required String errorCode,
    required String errorMessage,
    bool isPermissionDenied = false,
  }) {
    return AdminTrailParticipationInboxPresentation._(
      ok: false,
      errorCode: errorCode,
      errorMessage: errorMessage,
      isPermissionDenied: isPermissionDenied,
    );
  }

  final bool ok;
  final List<AdminTrailParticipationInboxItemPresentation> items;
  final List<String> availableTrailFilters;
  final String? errorCode;
  final String? errorMessage;
  final bool isPermissionDenied;
}

/// Detail load result wrapper.
final class AdminTrailParticipationDetailLoadResult {
  const AdminTrailParticipationDetailLoadResult._({
    required this.ok,
    this.detail,
    this.errorCode,
    this.errorMessage,
    this.isPermissionDenied = false,
    this.isNotFound = false,
  });

  factory AdminTrailParticipationDetailLoadResult.success(
    AdminTrailParticipationRequestDetailPresentation detail,
  ) {
    return AdminTrailParticipationDetailLoadResult._(ok: true, detail: detail);
  }

  factory AdminTrailParticipationDetailLoadResult.failure({
    required String errorCode,
    required String errorMessage,
    bool isPermissionDenied = false,
    bool isNotFound = false,
  }) {
    return AdminTrailParticipationDetailLoadResult._(
      ok: false,
      errorCode: errorCode,
      errorMessage: errorMessage,
      isPermissionDenied: isPermissionDenied,
      isNotFound: isNotFound,
    );
  }

  final bool ok;
  final AdminTrailParticipationRequestDetailPresentation? detail;
  final String? errorCode;
  final String? errorMessage;
  final bool isPermissionDenied;
  final bool isNotFound;
}

/// Shared status colour helper for admin participation UI.
Color adminTrailParticipationStatusColor(
  TrailParticipationDisplayStatus status,
) {
  return switch (status) {
    TrailParticipationDisplayStatus.approved => const Color(0xFFD4AF37),
    TrailParticipationDisplayStatus.rejected ||
    TrailParticipationDisplayStatus.cancelled ||
    TrailParticipationDisplayStatus.expired => const Color(0xFF9CA3AF),
    TrailParticipationDisplayStatus.informationRequested =>
      const Color(0xFF8B5CF6),
    TrailParticipationDisplayStatus.underReview => const Color(0xFF60A5FA),
    _ => const Color(0xFFEC4899),
  };
}
