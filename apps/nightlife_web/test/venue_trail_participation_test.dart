import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/core/theme/app_colors.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_context.dart';
import 'package:nightlife_web/features/venue_management/models/venue_trail_participation_presentation.dart';
import 'package:nightlife_web/features/venue_management/services/venue_trail_participation_action_resolver.dart';
import 'package:nightlife_web/features/venue_management/services/venue_trail_participation_audit_mapper.dart';
import 'package:nightlife_web/features/venue_management/services/venue_trail_participation_presentation_mapper.dart';
import 'package:nightlife_web/features/venue_management/widgets/trails/participation/trail_participation_application_form_dialog.dart';
import 'package:nightlife_web/features/venue_management/widgets/trails/participation/trail_participation_detail_dialog.dart';
import 'package:nightlife_web/features/venue_management/widgets/trails/participation/trail_participation_withdraw_dialog.dart';
import 'package:nightlife_web/features/venue_management/widgets/trails/venue_trails_management_page.dart';
import 'package:nightlife_web/features/venue_management/widgets/trails/venue_trails_presentation.dart';
import 'package:nightlife_web/features/venue_management/widgets/venue_dashboard_controller.dart';
import 'package:vex_core/workflow/workflow.dart';
import 'package:vex_engines/trail/domain/participation/trail_participation_display_status.dart';
import 'package:vex_engines/workflow/domain/workflow_status.dart';

import 'venue_dashboard_test_data.dart';

void main() {
  const trailDisplay = VenueTrailDisplayPresentation(
    trailId: 'trail-1',
    name: 'Northern Quarter Night Out',
    description: 'Late-night venues across the Northern Quarter.',
    bannerImageUrl: 'https://example.com/banner.jpg',
    stopCount: 8,
    maximumStops: 12,
    participationInstructions: 'Include your latest menu.',
    acceptsApplications: true,
    applicationWindowLabel: '5 Jul – 12 Jul',
  );

  VenueTrailParticipationApplicationPresentation sampleApplication({
    WorkflowStatus status = WorkflowStatus.submitted,
    TrailParticipationDisplayStatus displayStatus =
        TrailParticipationDisplayStatus.submitted,
    String? informationRequestNote,
    String? decisionReason,
    List<VenueTrailParticipationAuditPresentation> auditTimeline = const [],
  }) {
    final actions = VenueTrailParticipationActionResolver.forApplication(
      workflowStatus: status,
      managesVenue: true,
      ownsRequest: true,
      trailEligibleForNewApplication: true,
    );

    return VenueTrailParticipationApplicationPresentation(
      requestId: 'req-1',
      trailId: 'trail-1',
      trailName: trailDisplay.name,
      trailBannerUrl: trailDisplay.bannerImageUrl,
      trailDescription: trailDisplay.description,
      venueId: 'venue-1',
      displayStatus: displayStatus,
      workflowStatus: status,
      requestedStopOrder: 3,
      participationNote: 'We host live DJs every Friday.',
      submittedAt: DateTime.utc(2026, 7, 2),
      updatedAt: DateTime.utc(2026, 7, 3),
      revision: 2,
      actions: actions,
      statusColor: AppColors.primaryPink,
      informationRequestNote: informationRequestNote,
      decisionReason: decisionReason,
      auditTimeline: auditTimeline,
      trailStopCount: trailDisplay.stopCount,
      trailMaximumStops: trailDisplay.maximumStops,
      trailParticipationInstructions: trailDisplay.participationInstructions,
      trailApplicationWindowLabel: trailDisplay.applicationWindowLabel,
    );
  }

  group('VenueTrailParticipationActionResolver', () {
    test('draft exposes edit and submit actions', () {
      final actions = VenueTrailParticipationActionResolver.forApplication(
        workflowStatus: WorkflowStatus.draft,
        managesVenue: true,
        ownsRequest: true,
        trailEligibleForNewApplication: true,
      );

      expect(actions, contains(VenueTrailParticipationAction.editDraft));
      expect(actions, contains(VenueTrailParticipationAction.submit));
    });

    test('submitted exposes withdraw only besides view', () {
      final actions = VenueTrailParticipationActionResolver.forApplication(
        workflowStatus: WorkflowStatus.submitted,
        managesVenue: true,
        ownsRequest: true,
        trailEligibleForNewApplication: false,
      );

      expect(actions, [
        VenueTrailParticipationAction.view,
        VenueTrailParticipationAction.withdraw,
      ]);
    });

    test('rejected eligible trail exposes reapply', () {
      final actions = VenueTrailParticipationActionResolver.forApplication(
        workflowStatus: WorkflowStatus.rejected,
        managesVenue: true,
        ownsRequest: true,
        trailEligibleForNewApplication: true,
      );

      expect(actions, contains(VenueTrailParticipationAction.reapply));
    });
  });

  group('VenueTrailParticipationPresentationMapper', () {
    test('maps trail name instead of trail id for applications', () {
      final rows = VenueTrailParticipationPresentationMapper.mapApplications([
        sampleApplication(),
      ]);

      expect(rows.single.name, 'Northern Quarter Night Out');
      expect(rows.single.name, isNot('trail-1'));
    });

    test('maps eligible trails to discovery items', () {
      final rows = VenueTrailParticipationPresentationMapper.mapEligibleTrails([
        VenueTrailEligiblePresentation(
          trail: trailDisplay,
          eligible: true,
          blockingReasons: const [],
          validStopPositions: const [3],
          suggestedStopPosition: 3,
          venueState: VenueTrailEligibleVenueState.eligible,
        ),
      ]);

      expect(rows.single.name, trailDisplay.name);
      expect(rows.single.venueState, VenueTrailVenueState.eligible);
    });
  });

  group('VenueTrailParticipationAuditMapper', () {
    test('maps audit snapshots to venue-visible labels', () {
      final rows = VenueTrailParticipationAuditMapper.mapSnapshots([
        WorkflowAuditEntrySnapshot(
          auditId: 'audit-1',
          requestId: 'req-1',
          action: 'submitted',
          fromStatus: 'draft',
          toStatus: 'submitted',
          actorUid: 'owner-1',
          actorKind: 'submitter',
          notes: 'Submitted for review',
          metadata: const {'revision': 2},
          createdAt: DateTime.utc(2026, 7, 2),
        ),
      ]);

      expect(rows.single.displayAction, 'Submitted');
      expect(rows.single.actorLabel, 'Venue');
      expect(rows.single.note, 'Submitted for review');
      expect(rows.single.revision, 2);
    });
  });

  group('Trail participation widgets', () {
    Future<void> pumpPage(
      WidgetTester tester, {
      required List<VenueTrailParticipationApplicationPresentation>
      applications,
      Size size = const Size(1440, 2400),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final mapped = VenueTrailParticipationPresentationMapper.mapApplications(
        applications,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: SingleChildScrollView(
            child: VenueDashboardController(
              selectTab: (_, {pendingActionKey}) {},
              contextData: const VenueDashboardContext(
                ownerName: 'Alex Morgan',
                ownerFirstName: 'Alex',
                venueName: 'Copper Lantern',
                venueId: 'venue-copper-lantern',
              ),
              homeData: VenueDashboardTestData.sampleHomeData(),
              child: VenueTrailsManagementPage(
                discoveryTrails: const [],
                participationTrails: mapped,
                opportunityTrails: const [],
                liveApplications: applications,
                onApplicationPrimaryAction: (_) async {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows trail name on participation row', (tester) async {
      await pumpPage(tester, applications: [sampleApplication()]);

      expect(find.text('Northern Quarter Night Out'), findsOneWidget);
      expect(find.text('trail-1'), findsNothing);
    });

    testWidgets('information-requested note appears in detail dialog', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => TrailParticipationDetailDialog.show(
                  context,
                  application: sampleApplication(
                    status: WorkflowStatus.informationRequested,
                    displayStatus:
                        TrailParticipationDisplayStatus.informationRequested,
                    informationRequestNote: 'Please confirm opening hours.',
                  ),
                ),
                child: const Text('Open'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Please confirm opening hours.'), findsOneWidget);
      expect(find.text('Information requested'), findsWidgets);
    });

    testWidgets('withdraw confirmation dialog requires explicit confirm', (
      tester,
    ) async {
      var confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  confirmed = await TrailParticipationWithdrawDialog.show(
                    context,
                    trailName: trailDisplay.name,
                  );
                },
                child: const Text('Withdraw'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Withdraw'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('trail_participation_confirm_withdraw_button')),
      );
      await tester.pumpAndSettle();

      expect(confirmed, isTrue);
    });

    testWidgets('application form validates required note on submit', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 900);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => TrailParticipationApplicationFormDialog.show(
                  context,
                  trail: trailDisplay,
                  validStopPositions: const [2, 3],
                  mode: TrailParticipationFormMode.create,
                ),
                child: const Text('Apply'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('trail_participation_submit_button')),
      );
      await tester.tap(
        find.byKey(const Key('trail_participation_submit_button')),
      );
      await tester.pump();

      expect(find.text('Participation note is required.'), findsOneWidget);
    });

    testWidgets(
      'narrow viewport renders participation section without overflow',
      (tester) async {
        await pumpPage(
          tester,
          applications: [sampleApplication()],
          size: const Size(390, 2400),
        );

        expect(tester.takeException(), isNull);
      },
    );
  });
}
