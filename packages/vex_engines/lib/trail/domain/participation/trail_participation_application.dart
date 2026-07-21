import '../../../workflow/domain/workflow_status.dart';
import 'trail_participation_display_status.dart';
import 'trail_participation_submission_payload.dart';

/// Domain view of a venue trail participation workflow request.
final class TrailParticipationApplication {
  const TrailParticipationApplication({
    required this.workflowRequestId,
    required this.trailId,
    required this.venueId,
    required this.submittedByUid,
    required this.requestedStopOrder,
    required this.participationNote,
    required this.workflowStatus,
    required this.submittedAt,
    required this.updatedAt,
    required this.revision,
    this.decisionReason,
    this.informationRequestNote,
    this.createdAt,
    this.decidedAt,
  });

  final String workflowRequestId;
  final String trailId;
  final String venueId;
  final String submittedByUid;
  final int requestedStopOrder;
  final String participationNote;
  final WorkflowStatus workflowStatus;
  final DateTime? submittedAt;
  final DateTime updatedAt;
  final int revision;
  final String? decisionReason;
  final String? informationRequestNote;
  final DateTime? createdAt;
  final DateTime? decidedAt;

  TrailParticipationDisplayStatus get displayStatus =>
      TrailParticipationDisplayStatusMapper.fromWorkflowStatus(workflowStatus);

  bool get isOpen => workflowStatus.isOpen;

  bool get isTerminal => workflowStatus.isTerminal;

  TrailParticipationApplication copyWith({
    String? workflowRequestId,
    String? trailId,
    String? venueId,
    String? submittedByUid,
    int? requestedStopOrder,
    String? participationNote,
    WorkflowStatus? workflowStatus,
    DateTime? submittedAt,
    DateTime? updatedAt,
    int? revision,
    String? decisionReason,
    String? informationRequestNote,
    DateTime? createdAt,
    DateTime? decidedAt,
  }) {
    return TrailParticipationApplication(
      workflowRequestId: workflowRequestId ?? this.workflowRequestId,
      trailId: trailId ?? this.trailId,
      venueId: venueId ?? this.venueId,
      submittedByUid: submittedByUid ?? this.submittedByUid,
      requestedStopOrder: requestedStopOrder ?? this.requestedStopOrder,
      participationNote: participationNote ?? this.participationNote,
      workflowStatus: workflowStatus ?? this.workflowStatus,
      submittedAt: submittedAt ?? this.submittedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      revision: revision ?? this.revision,
      decisionReason: decisionReason ?? this.decisionReason,
      informationRequestNote:
          informationRequestNote ?? this.informationRequestNote,
      createdAt: createdAt ?? this.createdAt,
      decidedAt: decidedAt ?? this.decidedAt,
    );
  }

  static TrailParticipationApplication fromPayload({
    required String workflowRequestId,
    required WorkflowStatus workflowStatus,
    required String submittedByUid,
    required TrailParticipationSubmissionPayload payload,
    required DateTime updatedAt,
    required int revision,
    DateTime? submittedAt,
    DateTime? createdAt,
    DateTime? decidedAt,
    String? decisionReason,
    String? informationRequestNote,
  }) {
    return TrailParticipationApplication(
      workflowRequestId: workflowRequestId,
      trailId: payload.trailId,
      venueId: payload.venueId,
      submittedByUid: submittedByUid,
      requestedStopOrder: payload.requestedStopOrder,
      participationNote: payload.participationNote,
      workflowStatus: workflowStatus,
      submittedAt: submittedAt,
      updatedAt: updatedAt,
      revision: revision,
      decisionReason: decisionReason,
      informationRequestNote: informationRequestNote,
      createdAt: createdAt,
      decidedAt: decidedAt,
    );
  }
}
