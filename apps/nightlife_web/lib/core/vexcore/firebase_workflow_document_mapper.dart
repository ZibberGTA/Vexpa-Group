import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vex_core/workflow/workflow.dart';
import 'package:vex_engines/workflow/domain/workflow_actor.dart';
import 'package:vex_engines/workflow/domain/workflow_audit_action.dart';
import 'package:vex_engines/workflow/domain/workflow_audit_entry.dart';
import 'package:vex_engines/workflow/domain/workflow_request.dart';
import 'package:vex_engines/workflow/domain/workflow_status.dart';

/// Maps Firestore workflow documents to VexCore snapshots.
abstract final class FirebaseWorkflowDocumentMapper {
  static WorkflowRequestSnapshot? parseRequestDocument(
    String requestId,
    Map<String, dynamic>? data,
  ) {
    if (data == null) return null;

    final subjectRefsRaw = data['subjectRefs'];
    final subjectRefs = subjectRefsRaw is Map
        ? Map<String, String>.from(
            subjectRefsRaw.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            ),
          )
        : <String, String>{};

    final payloadRaw = data['payload'];
    final payloadValues = payloadRaw is Map
        ? Map<String, Object?>.from(payloadRaw)
        : <String, Object?>{};

    final assignedReviewersRaw = data['assignedReviewerUids'];
    final assignedReviewerUids = assignedReviewersRaw is List
        ? assignedReviewersRaw.map((value) => value.toString()).toList()
        : <String>[];

    return WorkflowRequestSnapshot(
      requestId: (data['requestId'] ?? requestId).toString(),
      workflowType: (data['workflowType'] ?? '').toString(),
      status: (data['status'] ?? 'draft').toString(),
      submittedByUid: (data['submittedByUid'] ?? '').toString(),
      subjectRefs: WorkflowSubjectRefsSnapshot(subjectRefs),
      payload: WorkflowPayloadSnapshot(
        values: payloadValues,
        schemaVersion: (payloadValues['schemaVersion'] as num?)?.toInt() ?? 1,
      ),
      assignedReviewerUid: data['assignedReviewerUid']?.toString(),
      assignedReviewerUids: assignedReviewerUids,
      reviewNotesSummary: data['reviewNotesSummary']?.toString(),
      decisionReason: data['decisionReason']?.toString(),
      decisionCode: data['decisionCode']?.toString(),
      expiresAt: _readTimestamp(data['expiresAt']),
      submittedAt: _readTimestamp(data['submittedAt']),
      decidedAt: _readTimestamp(data['decidedAt']),
      createdAt: _readTimestamp(data['createdAt']) ?? DateTime.now().toUtc(),
      updatedAt: _readTimestamp(data['updatedAt']) ?? DateTime.now().toUtc(),
      revision: (data['revision'] as num?)?.toInt() ?? 1,
    );
  }

  static WorkflowAuditEntrySnapshot? parseAuditDocument(
    String auditId,
    Map<String, dynamic>? data,
  ) {
    if (data == null) return null;

    final metadataRaw = data['metadata'];
    final metadata = metadataRaw is Map
        ? Map<String, Object?>.from(metadataRaw)
        : const <String, Object?>{};

    return WorkflowAuditEntrySnapshot(
      auditId: (data['auditId'] ?? auditId).toString(),
      requestId: (data['requestId'] ?? '').toString(),
      action: (data['action'] ?? '').toString(),
      fromStatus: (data['fromStatus'] ?? '').toString(),
      toStatus: (data['toStatus'] ?? '').toString(),
      actorUid: (data['actorUid'] ?? '').toString(),
      actorKind: (data['actorKind'] ?? 'submitter').toString(),
      notes: data['notes']?.toString(),
      reason: data['reason']?.toString(),
      metadata: metadata,
      createdAt: _readTimestamp(data['createdAt']) ?? DateTime.now().toUtc(),
    );
  }

  static Map<String, Object?> requestWriteData({
    required WorkflowRequest request,
    required bool isCreate,
  }) {
    final trailId = request.subjectRefs.ref('trailId') ?? '';
    final venueId = request.subjectRefs.ref('venueId') ?? '';

    return {
      'requestId': request.requestId,
      'workflowType': request.workflowType.value,
      'status': request.status.persistenceValue,
      'submittedByUid': request.submittedByUid,
      'subjectRefs': Map<String, String>.from(request.subjectRefs.values),
      'subjectTrailId': trailId,
      'subjectVenueId': venueId,
      'payload': Map<String, Object?>.from(request.payload.values),
      if (request.assignedReviewerUid != null)
        'assignedReviewerUid': request.assignedReviewerUid,
      'assignedReviewerUids': request.assignedReviewerUids,
      if (request.reviewNotesSummary != null)
        'reviewNotesSummary': request.reviewNotesSummary,
      if (request.decisionReason != null)
        'decisionReason': request.decisionReason,
      if (request.decisionCode != null) 'decisionCode': request.decisionCode,
      if (request.expiresAt != null)
        'expiresAt': Timestamp.fromDate(request.expiresAt!),
      if (request.submittedAt != null)
        'submittedAt': Timestamp.fromDate(request.submittedAt!),
      if (request.decidedAt != null)
        'decidedAt': Timestamp.fromDate(request.decidedAt!),
      'revision': request.revision,
      'updatedAt': FieldValue.serverTimestamp(),
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static Map<String, Object?> auditWriteData(WorkflowAuditEntry entry) {
    return {
      'auditId': entry.auditId,
      'requestId': entry.requestId,
      'action': entry.action.persistenceValue,
      'fromStatus': entry.fromStatus.persistenceValue,
      'toStatus': entry.toStatus.persistenceValue,
      'actorUid': entry.actor.uid,
      'actorKind': entry.actor.kind.persistenceValue,
      if (entry.notes != null) 'notes': entry.notes,
      if (entry.reason != null) 'reason': entry.reason,
      'metadata': entry.metadata,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static DateTime? _readTimestamp(Object? value) {
    if (value is Timestamp) return value.toDate().toUtc();
    if (value is DateTime) return value.toUtc();
    return null;
  }
}
