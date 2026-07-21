import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/core/vexcore/firebase_workflow_document_mapper.dart';
import 'package:vex_engines/workflow/domain/workflow_payload.dart';
import 'package:vex_engines/workflow/domain/workflow_request.dart';
import 'package:vex_engines/workflow/domain/workflow_status.dart';
import 'package:vex_engines/workflow/domain/workflow_subject_refs.dart';
import 'package:vex_engines/workflow/domain/workflow_type_id.dart';
import 'package:vex_engines/workflow/shared/shared.dart';

void main() {
  group('FirebaseWorkflowDocumentMapper request parsing', () {
    test('parseRequestDocument maps draft payload', () {
      final snapshot = FirebaseWorkflowDocumentMapper.parseRequestDocument(
        'req-draft',
        {
          'requestId': 'req-draft',
          'workflowType': WorkflowTypeIds.trailVenueParticipation,
          'status': 'draft',
          'submittedByUid': 'owner-1',
          'subjectRefs': {'trailId': 'trail-1', 'venueId': 'venue-1'},
          'subjectTrailId': 'trail-1',
          'subjectVenueId': 'venue-1',
          'payload': {
            'schemaVersion': 1,
            'trailId': 'trail-1',
            'venueId': 'venue-1',
            'requestedStopOrder': 1,
            'participationNote': 'Draft note',
          },
          'revision': 1,
          'createdAt': DateTime.utc(2026, 7, 1),
          'updatedAt': DateTime.utc(2026, 7, 1),
        },
      );

      expect(snapshot!.status, 'draft');
      expect(snapshot.payload.values['participationNote'], 'Draft note');
      expect(snapshot.revision, 1);
    });

    test('parseRequestDocument maps information-requested request', () {
      final snapshot = FirebaseWorkflowDocumentMapper.parseRequestDocument(
        'req-info',
        {
          'requestId': 'req-info',
          'workflowType': WorkflowTypeIds.trailVenueParticipation,
          'status': 'information_requested',
          'submittedByUid': 'owner-1',
          'subjectRefs': {'trailId': 'trail-1', 'venueId': 'venue-1'},
          'subjectTrailId': 'trail-1',
          'subjectVenueId': 'venue-1',
          'payload': {
            'schemaVersion': 1,
            'trailId': 'trail-1',
            'venueId': 'venue-1',
            'requestedStopOrder': 2,
            'participationNote': 'Needs update',
          },
          'reviewNotesSummary': 'Confirm opening hours',
          'revision': 3,
          'createdAt': DateTime.utc(2026, 7, 1),
          'updatedAt': DateTime.utc(2026, 7, 4),
          'submittedAt': DateTime.utc(2026, 7, 2),
        },
      );

      expect(snapshot!.status, 'information_requested');
      expect(snapshot.reviewNotesSummary, 'Confirm opening hours');
    });

    test('parseRequestDocument maps rejected request with decision reason', () {
      final snapshot = FirebaseWorkflowDocumentMapper.parseRequestDocument(
        'req-rejected',
        {
          'requestId': 'req-rejected',
          'workflowType': WorkflowTypeIds.trailVenueParticipation,
          'status': 'rejected',
          'submittedByUid': 'owner-1',
          'subjectRefs': {'trailId': 'trail-1', 'venueId': 'venue-1'},
          'subjectTrailId': 'trail-1',
          'subjectVenueId': 'venue-1',
          'payload': const {},
          'decisionReason': 'Trail capacity reached',
          'decisionCode': 'capacity_reached',
          'revision': 4,
          'createdAt': DateTime.utc(2026, 7, 1),
          'updatedAt': DateTime.utc(2026, 7, 5),
          'decidedAt': DateTime.utc(2026, 7, 5),
        },
      );

      expect(snapshot!.decisionReason, 'Trail capacity reached');
      expect(snapshot.decisionCode, 'capacity_reached');
    });

    test('parseRequestDocument maps approved request', () {
      final snapshot = FirebaseWorkflowDocumentMapper.parseRequestDocument(
        'req-approved',
        {
          'requestId': 'req-approved',
          'workflowType': WorkflowTypeIds.trailVenueParticipation,
          'status': 'approved',
          'submittedByUid': 'owner-1',
          'subjectRefs': {'trailId': 'trail-1', 'venueId': 'venue-1'},
          'subjectTrailId': 'trail-1',
          'subjectVenueId': 'venue-1',
          'payload': const {},
          'revision': 5,
          'createdAt': DateTime.utc(2026, 7, 1),
          'updatedAt': DateTime.utc(2026, 7, 6),
          'decidedAt': DateTime.utc(2026, 7, 6),
        },
      );

      expect(snapshot!.status, 'approved');
    });

    test('parseRequestDocument returns null for missing data', () {
      expect(
        FirebaseWorkflowDocumentMapper.parseRequestDocument('req-1', null),
        isNull,
      );
    });

    test('parseRequestDocument tolerates unknown status string', () {
      final snapshot =
          FirebaseWorkflowDocumentMapper.parseRequestDocument('req-unknown', {
            'requestId': 'req-unknown',
            'workflowType': WorkflowTypeIds.trailVenueParticipation,
            'status': 'legacy_status',
            'submittedByUid': 'owner-1',
            'subjectRefs': const {},
            'payload': const {},
            'revision': 1,
            'createdAt': DateTime.utc(2026, 7, 1),
            'updatedAt': DateTime.utc(2026, 7, 1),
          });

      expect(snapshot!.status, 'legacy_status');
    });
  });

  group('FirebaseWorkflowDocumentMapper audit parsing', () {
    test('parseAuditDocument maps audit fields and metadata', () {
      final snapshot = FirebaseWorkflowDocumentMapper.parseAuditDocument(
        'audit-1',
        {
          'auditId': 'audit-1',
          'requestId': 'req-1',
          'action': 'resubmitted',
          'fromStatus': 'information_requested',
          'toStatus': 'submitted',
          'actorUid': 'owner-1',
          'actorKind': 'submitter',
          'notes': 'Updated note',
          'metadata': {'revision': 4},
          'createdAt': DateTime.utc(2026, 7, 4),
        },
      );

      expect(snapshot!.action, 'resubmitted');
      expect(snapshot.metadata['revision'], 4);
      expect(snapshot.notes, 'Updated note');
    });

    test('parseAuditDocument returns null for missing data', () {
      expect(
        FirebaseWorkflowDocumentMapper.parseAuditDocument('audit-1', null),
        isNull,
      );
    });
  });

  test(
    'requestWriteData includes indexed subject fields and immutable ids',
    () {
      final request = WorkflowRequest(
        requestId: 'req-1',
        workflowType: const WorkflowTypeId(
          WorkflowTypeIds.trailVenueParticipation,
        ),
        status: WorkflowStatus.draft,
        submittedByUid: 'user-1',
        subjectRefs: const WorkflowSubjectRefs({
          'trailId': 'trail-1',
          'venueId': 'venue-1',
        }),
        payload: const WorkflowPayload(
          schemaVersion: 1,
          values: {
            'trailId': 'trail-1',
            'venueId': 'venue-1',
            'requestedStopOrder': 2,
            'participationNote': 'note',
          },
        ),
        createdAt: DateTime.utc(2026, 7, 1),
        updatedAt: DateTime.utc(2026, 7, 1),
        revision: 1,
      );

      final data = FirebaseWorkflowDocumentMapper.requestWriteData(
        request: request,
        isCreate: true,
      );

      expect(data['subjectTrailId'], 'trail-1');
      expect(data['subjectVenueId'], 'venue-1');
      expect(data['requestId'], 'req-1');
      expect(data['workflowType'], WorkflowTypeIds.trailVenueParticipation);
      expect(data['payload'], isA<Map>());
    },
  );
}
