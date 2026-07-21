# VexWorkflow Engine — Migration Plan

Status: **Foundation complete — domain, application services, VexCore contracts, events, unit tests**

## Scope of this phase

- Firebase-independent VexWorkflow domain and application layers
- VexCore repository, command, and snapshot contracts
- Generic workflow lifecycle events
- Comprehensive unit tests

No Firebase adapters, Firestore rules, Cloud Functions, UI, Claim integration, or Trail integration were implemented in this phase.

## Planned consumer order

| Phase | Consumer | Notes |
| --- | --- | --- |
| 1 | **VexTrail venue participation** | Greenfield `trail.venue_participation` workflows |
| 2 | **Venue Claim dual-write** | Link `venue_claims.workflowRequestId`; callables delegate to workflow commands |
| 3 | Unified admin inbox | Optional cross-type review queue |

## Venue Claim migration (later)

- Keep `venue_claims/{claimId}` as the claim aggregate document
- Store `workflowRequestId` on claim records
- Map legacy claim statuses to generic workflow statuses at the adapter boundary
- Retain claim-specific scoring, evidence, and ownership handlers in Claim Engine
- Do **not** remove `ClaimStatus` or `ClaimLifecycleEvent` until subscribers migrate

## Trail migration (later)

- Register `WorkflowTypeIds.trailVenueParticipation`
- Replace venue management mock request actions with workflow-backed requests
- Execute stop inclusion in Trail Engine `onApproved` handler via trusted writes

## Rollback path

1. Revert engine and VexCore workflow exports.
2. Consumer engines continue using local workflow logic until re-wired.

No Firestore schema changes were made in the foundation phase.

## Performance rule

Engine services perform in-memory validation and planning only. No added Firestore reads, listeners, or callables are introduced by this package alone.
