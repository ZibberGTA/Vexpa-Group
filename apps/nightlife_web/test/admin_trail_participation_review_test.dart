import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/features/admin/data/admin_trail_participation_review_repository.dart';
import 'package:nightlife_web/features/admin/models/admin_trail_participation_review_presentation.dart';
import 'package:nightlife_web/features/admin/permissions/permission_service.dart';
import 'package:nightlife_web/features/admin/permissions/staff_permission.dart';
import 'package:nightlife_web/features/admin/services/admin_trail_participation_action_resolver.dart';
import 'package:nightlife_web/features/admin/services/admin_trail_participation_audit_mapper.dart';
import 'package:nightlife_web/features/admin/services/admin_trail_participation_presentation_mapper.dart';
import 'package:nightlife_web/features/admin/widgets/trails/admin_trail_participation_review_page.dart';
import 'package:vex_core/workflow/workflow.dart';
import 'package:vex_engines/trail/domain/participation/trail_participation_application.dart';
import 'package:vex_engines/trail/domain/participation/trail_participation_display_status.dart';
import 'package:vex_engines/trail/domain/participation/trail_participation_eligibility_policy.dart';
import 'package:vex_engines/trail/domain/participation/trail_participation_submission_payload.dart';
import 'package:vex_engines/trail/domain/trail.dart';
import 'package:vex_engines/trail/domain/trail_status.dart';
import 'package:vex_engines/trail/domain/trail_type.dart';
import 'package:vex_engines/workflow/domain/workflow_status.dart';

void main() {
  TrailParticipationApplication sampleApplication({
    WorkflowStatus status = WorkflowStatus.submitted,
  }) {
    return TrailParticipationApplication.fromPayload(
      workflowRequestId: 'req-1',
      workflowStatus: status,
      submittedByUid: 'owner-1',
      payload: const TrailParticipationSubmissionPayload(
        schemaVersion: 1,
        trailId: 'trail-1',
        venueId: 'venue-1',
        requestedStopOrder: 3,
        participationNote: 'Live DJs every Friday.',
      ),
      updatedAt: DateTime.utc(2026, 7, 3),
      revision: 2,
      submittedAt: DateTime.utc(2026, 7, 2),
      createdAt: DateTime.utc(2026, 7, 1),
    );
  }

  Trail trailFixture() {
    return Trail(
      id: 'trail-1',
      name: 'Northern Quarter Night Out',
      description: 'Late-night venues.',
      bannerImageUrl: '',
      status: TrailStatus.published,
      published: true,
      area: 'Manchester',
      availabilityStart: DateTime.utc(2026, 1, 1),
      availabilityEnd: DateTime.utc(2026, 12, 31),
      estimatedDurationMinutes: 180,
      estimatedWalkingDistance: 1200,
      averageRating: 4.5,
      venueCount: 8,
      trailType: TrailType.curated,
      generatedAt: DateTime.utc(2026, 1, 1),
      stops: const [],
    );
  }

  group('AdminTrailParticipationActionResolver', () {
    test('submitted exposes review decisions for managers', () {
      final actions = AdminTrailParticipationActionResolver.forRequest(
        workflowStatus: WorkflowStatus.submitted,
        canManage: true,
      );

      expect(actions, contains(AdminTrailParticipationAction.approve));
      expect(actions, contains(AdminTrailParticipationAction.reject));
      expect(actions, contains(AdminTrailParticipationAction.requestInformation));
    });

    test('information requested only allows reject for managers', () {
      final actions = AdminTrailParticipationActionResolver.forRequest(
        workflowStatus: WorkflowStatus.informationRequested,
        canManage: true,
      );

      expect(actions, contains(AdminTrailParticipationAction.reject));
      expect(actions, isNot(contains(AdminTrailParticipationAction.approve)));
    });

    test('read-only staff only sees view', () {
      final actions = AdminTrailParticipationActionResolver.forRequest(
        workflowStatus: WorkflowStatus.submitted,
        canManage: false,
      );

      expect(actions, [AdminTrailParticipationAction.view]);
    });

    test('revision conflict exposes refresh action', () {
      final actions = AdminTrailParticipationActionResolver.forRequest(
        workflowStatus: WorkflowStatus.submitted,
        canManage: true,
        revisionConflict: true,
      );

      expect(actions, [AdminTrailParticipationAction.refreshAfterConflict]);
    });
  });

  group('AdminTrailParticipationAuditMapper', () {
    test('maps audit snapshots with actor labels and resubmitted detection', () {
      final snapshots = [
        WorkflowAuditEntrySnapshot(
          auditId: 'req-1-1-submitted',
          requestId: 'req-1',
          action: 'submitted',
          fromStatus: 'draft',
          toStatus: 'submitted',
          actorUid: 'owner-1',
          actorKind: 'submitter',
          createdAt: DateTime.utc(2026, 7, 2),
        ),
        WorkflowAuditEntrySnapshot(
          auditId: 'req-1-2-resubmitted',
          requestId: 'req-1',
          action: 'resubmitted',
          fromStatus: 'information_requested',
          toStatus: 'submitted',
          actorUid: 'owner-1',
          actorKind: 'submitter',
          createdAt: DateTime.utc(2026, 7, 4),
          notes: 'Updated note.',
        ),
      ];

      final mapped = AdminTrailParticipationAuditMapper.mapSnapshots(snapshots);

      expect(mapped, hasLength(2));
      expect(mapped.last.displayAction, 'Resubmitted');
      expect(
        AdminTrailParticipationAuditMapper.wasResubmitted(snapshots),
        isTrue,
      );
    });
  });

  group('AdminTrailParticipationPresentationMapper', () {
    test('maps inbox item with enriched names', () {
      final item = AdminTrailParticipationPresentationMapper.mapInboxItem(
        application: sampleApplication(),
        venueName: 'Public Bar',
        trailName: 'Northern Quarter Night Out',
        canManage: true,
        auditSnapshots: const [],
      );

      expect(item.venueName, 'Public Bar');
      expect(item.trailName, 'Northern Quarter Night Out');
      expect(item.primaryActionLabel, isNot('View'));
    });

    test('approval plan states trail is not mutated automatically', () {
      final detail = AdminTrailParticipationPresentationMapper.mapDetail(
        application: sampleApplication(),
        venueName: 'Public Bar',
        trail: trailFixture(),
        canManage: true,
        auditSnapshots: const [],
        eligibility: const TrailParticipationEligibilityResult(eligible: true),
      );

      expect(detail.approvalPlan, isNotNull);
      expect(detail.approvalPlan!.trailWillBeMutated, isFalse);
      expect(detail.approvalPlan!.requiresManualPlacement, isTrue);
    });

    test('decision failure mapping exposes revision conflict', () {
      final result = AdminTrailParticipationDecisionResult.failure(
        errorCode: 'workflow-revision-conflict',
        errorMessage: 'Stale revision',
        isRevisionConflict: true,
      );

      expect(result.isRevisionConflict, isTrue);
      expect(result.ok, isFalse);
    });
  });

  group('AdminTrailParticipationReviewPage', () {
    testWidgets('shows loading then empty inbox state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminTrailParticipationReviewPage(
            permissions: PermissionService.testing({
              StaffPermission.trailsManage,
            }),
            repository: _EmptyInboxRepository(),
            actorUidOverride: 'admin-1',
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'No participation requests are waiting for administrator review.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('read-only staff do not see decision buttons in detail', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminTrailParticipationReviewPage(
            permissions: PermissionService.testing({
              StaffPermission.trailsView,
            }),
            repository: _SingleItemRepository(),
            actorUidOverride: 'admin-1',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Public Bar'));
      await tester.pumpAndSettle();

      expect(find.text('Approve'), findsNothing);
      expect(find.text('Reject'), findsNothing);
      expect(find.text('Request information'), findsNothing);
    });
  });
}

class _EmptyInboxRepository extends AdminTrailParticipationReviewRepository {
  @override
  Future<AdminTrailParticipationInboxPresentation> loadInbox({
    required String actorUid,
    required bool canView,
    required bool canManage,
    AdminTrailParticipationInboxFilters filters =
        const AdminTrailParticipationInboxFilters(),
  }) async {
    return AdminTrailParticipationInboxPresentation.success(
      items: const [],
      availableTrailFilters: const [],
    );
  }
}

class _SingleItemRepository extends AdminTrailParticipationReviewRepository {
  @override
  Future<AdminTrailParticipationInboxPresentation> loadInbox({
    required String actorUid,
    required bool canView,
    required bool canManage,
    AdminTrailParticipationInboxFilters filters =
        const AdminTrailParticipationInboxFilters(),
  }) async {
    return AdminTrailParticipationInboxPresentation.success(
      items: [
        AdminTrailParticipationInboxItemPresentation(
          requestId: 'req-1',
          venueId: 'venue-1',
          venueName: 'Public Bar',
          trailId: 'trail-1',
          trailName: 'Northern Quarter Night Out',
          requestedStopOrder: 3,
          displayStatus: TrailParticipationDisplayStatus.submitted,
          workflowStatus: WorkflowStatus.submitted,
          statusLabel: 'Submitted',
          submittedAt: DateTime.utc(2026, 7, 2),
          updatedAt: DateTime.utc(2026, 7, 3),
          revision: 2,
          wasResubmitted: false,
          actions: AdminTrailParticipationActionResolver.forRequest(
            workflowStatus: WorkflowStatus.submitted,
            canManage: canManage,
          ),
          primaryActionLabel: 'Approve',
        ),
      ],
      availableTrailFilters: const ['Northern Quarter Night Out'],
    );
  }

  @override
  Future<AdminTrailParticipationDetailLoadResult> loadDetail({
    required String requestId,
    required bool canView,
    required bool canManage,
  }) async {
    return AdminTrailParticipationDetailLoadResult.success(
      AdminTrailParticipationRequestDetailPresentation(
        requestId: 'req-1',
        venueId: 'venue-1',
        venueName: 'Public Bar',
        trailId: 'trail-1',
        trailName: 'Northern Quarter Night Out',
        trailDescription: 'Late-night venues.',
        trailStopCount: 8,
        trailMaximumStops: 12,
        requestedStopOrder: 3,
        participationNote: 'Live DJs every Friday.',
        displayStatus: TrailParticipationDisplayStatus.submitted,
        workflowStatus: WorkflowStatus.submitted,
        statusLabel: 'Submitted',
        revision: 2,
        submittedAt: DateTime.utc(2026, 7, 2),
        updatedAt: DateTime.utc(2026, 7, 3),
        decidedAt: null,
        informationRequestNote: null,
        decisionReason: null,
        wasResubmitted: false,
        actions: AdminTrailParticipationActionResolver.forRequest(
          workflowStatus: WorkflowStatus.submitted,
          canManage: canManage,
        ),
        auditTimeline: const [],
        eligibilityWarnings: const [],
        approvalPlan: const AdminTrailParticipationApprovalPlanPresentation(
          requestId: 'req-1',
          trailId: 'trail-1',
          venueId: 'venue-1',
          approvedRequestedStopOrder: 3,
          proposedInsertionOrder: 3,
          requiresManualPlacement: true,
          trailWillBeMutated: false,
        ),
      ),
    );
  }
}
