# VexTrail Migration Plan

## Current runtime

```
Mobile UI → TrailService → Firebase
```

## Implemented (this phase)

```
Mobile Trail UI → TrailService → TrailServiceFacade → VexTrail → VexCore → Firebase adapters   (production default)
Mobile Trail UI → TrailService → TrailServiceLegacy → Firebase                                 (rollback path)
```

## Final target

```
Mobile / Web / Admin / Venue Portal
  ↓
VexTrail application services
  ↓
VexCore repository contracts
  ↓
Firebase adapters
```

## Completed layers

1. **VexCore Trail contracts** — snapshots, repositories, commands
2. **VexTrail domain foundation** — policies, transition plans, events
3. **VexTrail application orchestration** — discovery, management, progress, check-in, generation, activity
4. **Mobile Firebase adapters** — `apps/nightlife_app/lib/core/vexcore/firebase_trail_*.dart`
5. **Migration seam** — `MobileVexCoreTrailStack`, `MobileTrailOrchestration` (not wired to UI)

## Application orchestration

| Service | Responsibility |
| --- | --- |
| `TrailDiscoveryApplicationService` | List/watch visible trails via repository + visibility policy |
| `TrailManagementApplicationService` | CRUD lifecycle, validated vs legacy publish |
| `TrailProgressApplicationService` | Join, resume, progress read/watch, continue, skip |
| `TrailCheckInApplicationService` | Venue lookup + geofence assessment wrapper |
| `TrailGenerationApplicationService` | Draft generation + `replaceDocument` |
| `TrailActivityApplicationService` | Append-only activity (`directions_requested`, etc.) |
| `TrailPersistenceCoordinator` | Activity append + event publish after canonical writes |

## Transaction boundaries

| Operation | Atomicity |
| --- | --- |
| Join progress | Firestore **batch**: active state + canonical progress + optional legacy mirror |
| Check-in / continue / skip | Progress batch (+ active state on check-in); activity **separate** |
| Publish / unpublish / archive | Single document write; events after success |
| Duplicate | Single create write in adapter |
| Activity append | Independent write; failure → warning on progress result |

Legacy mirror failure on join batch fails the whole batch (canonical + legacy in same batch). Activity failure does **not** roll back progress (matches current ordering).

## Event ordering

Domain events publish **only after** canonical repository success. Event publication failure returns a warning on success results for progress operations; management lifecycle treats event failure as operation failure.

## Legacy progress

- Canonical: `users/{uid}/trails/{trailId}/progress/current`
- Active pointer: `users/{uid}/trail_state/active`
- Legacy mirror: `trail_progress/{uid}` when `trailId == activeTrail`
- Adapter reads legacy for `activeTrail` resume when canonical doc missing

## Publish validation vs legacy

- `publishValidated` — enforces `TrailPublicationService.isReady`
- `publishLegacyCompatible` — matches current admin `publishTrail` (no readiness gate)
- Facade must call legacy path for parity until product changes admin behaviour

## Runtime cutover

**Completed for mobile.** `TrailService` delegates to `TrailServiceFacade` by default. Rollback: set `TrailServiceMigrationConfig.useVexTrailFacade = false`. Manual checklist: `apps/nightlife_app/docs/TRAIL_CUTOVER_REGRESSION.md`.

## Risks (preserved)

1. Full-collection trail reads at scale
2. Client-side geofence and permissive missing-location check-in
3. Partial writes: progress succeeds, activity may fail
4. No idempotency keys on activity append
5. Production TrailService does not emit VexTrail domain events yet

## Out of scope

- VexWorkflow integration
- Website trail management
- Firestore rules/index changes
- Storage migration for trail artwork
