# VexWorkflow Engine

## Purpose

VexWorkflow is the shared approval and request engine for Vexda. It manages generic workflow lifecycle, audit history, reviewer assignment metadata, and platform workflow events.

Confirmed future consumers:

- Venue Claim Engine (`venue.claim`)
- VexTrail Engine (`trail.venue_participation`)

## Ownership boundaries

### VexWorkflow owns

- Workflow request lifecycle (`draft` → terminal states)
- Transition validation and planning
- Audit entry composition
- Generic workflow events
- Consumer registration contracts (ports and handler signatures)

### VexWorkflow does not own

- Trail participation consequences
- Venue ownership transfer
- Notifications
- Analytics aggregation
- Domain payload meaning
- Firebase SDK access
- Firestore rules
- Staff role matrices

Business engines own the **meaning** of approval. VexWorkflow records that an approval occurred and emits events.

## Status lifecycle

Open statuses:

- `draft`
- `submitted`
- `under_review`
- `information_requested`

Terminal statuses:

- `approved`
- `rejected`
- `withdrawn`
- `cancelled`
- `expired`

Resubmission from `information_requested` returns to `submitted`.

## Consumer responsibilities

Each consumer engine must provide:

1. A stable `WorkflowTypeId`
2. A `WorkflowPermissionPort` implementation
3. A `WorkflowPayloadValidatorPort` implementation
4. Handler contracts for approved/rejected and optional terminal callbacks
5. Domain consequences executed after trusted writes (Cloud Functions)

VexWorkflow stores and transports payloads but does not parse claim or trail domain fields.

## Trusted write boundary

Application services in this package produce `WorkflowTransitionPlan` values only. They do not persist.

Privileged transitions (`approve`, `reject`, `request information`, `cancel`, `assign reviewer`, `expire`) must be executed through `WorkflowCommandGateway` implementations backed by Cloud Functions using Admin SDK.

Draft creation, draft update, submit, withdraw, and resubmit may later be exposed through repositories or callables depending on security rules.

## No Firebase rule

This engine package must not import Firebase SDKs or Flutter UI libraries.

Repository interfaces live in `packages/vex_core/lib/workflow/`. Firebase adapters belong in app shells.

## Registration example (future phase)

```dart
WorkflowConsumerRegistration(
  workflowType: WorkflowTypeId(WorkflowTypeIds.trailVenueParticipation),
  permissionPort: trailWorkflowPermissionPort,
  payloadValidator: trailWorkflowPayloadValidator,
  onApproved: trailEngine.onParticipationApproved,
  onRejected: trailEngine.onParticipationRejected,
);
```

Handlers are contracts only during foundation work; consumer engines wire them in later phases.

## Layer layout

```text
workflow/
  domain/          # status machine, models, transition plans
  application/     # orchestration services and ports
  application/ports/
  shared/          # type id constants only
  data/            # adapter notes (interfaces in VexCore)
```

## Dependencies

- `vex_core` for `VexEvent` types and repository contracts
- No dependency on Claim, Trail, or other business engines
