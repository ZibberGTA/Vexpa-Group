import 'package:test/test.dart';
import 'package:vex_core/vex_core.dart';

void main() {
  group('Workflow lifecycle events', () {
    test('WorkflowSubmittedEvent exposes generic workflow fields', () {
      final event = WorkflowSubmittedEvent(
        requestId: 'req-1',
        workflowType: 'trail.venue_participation',
        submittedByUid: 'user-1',
        subjectRefs: const {'trailId': 'trail-1', 'venueId': 'venue-1'},
        resultingStatus: 'submitted',
        revision: 2,
        occurredAt: DateTime.utc(2026, 1, 2),
      );

      expect(event.type, 'workflow.submitted');
      expect(event.requestId, 'req-1');
      expect(event.workflowType, 'trail.venue_participation');
      expect(event.revision, 2);
    });

    test('InProcessVexEventBus delivers workflow events', () async {
      final bus = InProcessVexEventBus();
      final received = <WorkflowApprovedEvent>[];

      final subscription = bus.subscribe<WorkflowApprovedEvent>((event) async {
        received.add(event);
      });

      await bus.publish(
        WorkflowApprovedEvent(
          requestId: 'req-1',
          workflowType: 'venue.claim',
          submittedByUid: 'user-1',
          subjectRefs: const {'venueId': 'venue-1'},
          resultingStatus: 'approved',
          revision: 3,
        ),
      );

      expect(received, hasLength(1));
      expect(received.first.type, 'workflow.approved');
      await subscription.cancel();
    });

    test('ClaimLifecycleEvent remains available for compatibility', () {
      final event = ClaimLifecycleEvent(
        claimId: 'claim-1',
        venueId: 'venue-1',
        action: 'approved',
      );

      expect(event.type, 'claim.lifecycle.approved');
    });
  });
}
