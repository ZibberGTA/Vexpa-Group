# VexTrail Engine

Firebase-independent trail lifecycle, visibility, progress, check-in, and generation policies extracted from the mobile production baseline.

## Purpose

VexTrail decides **what should happen** for trail operations. It does not persist data, call Firebase, or render UI.

## Ownership boundaries

| Layer | Owns |
| --- | --- |
| **VexCore** | Snapshots, repository contracts, query/command DTOs |
| **VexTrail** | Business rules, transition plans, activity drafts, domain events |
| **Apps** | Flutter UI, navigation, location permission prompts, map apps |
| **Firebase adapters** | Firestore mapping, server timestamps, legacy mirrors |

## Domain policies

- **Lifecycle** — draft/publish/unpublish/archive/duplicate transitions
- **Visibility** — mobile public rules (`status`, `published`, stops, availability window, same-day pre-start)
- **Availability** — structured time states separate from publication
- **Publication readiness** — admin checklist parity (`TrailPublishWorkflow`)
- **Stop order** — 1-based route order, index/order conversion, renumbering
- **Progress** — join, check-in, continue, skip state machine (mobile `TrailService` parity)
- **Check-in** — geofence assessment (venue facts supplied via port)
- **Completion** — terminal stop states (`checkedIn`, `skipped`, `missed`, `completed`)
- **Generation** — `generateDraftTrail` scoring and stop timing

## Progress model

- `currentStopIndex` — 0-based list index (matches mobile `currentStop`)
- `stopStates` / `checkedInStopOrders` — keyed by persisted stop **order** (1-based)
- Check-in does **not** auto-advance; Continue marks checked-in stop completed and advances
- Trail may complete on check-in alone when all stops are terminal (`checkedIn` is terminal)

## Check-in architecture

1. App resolves venue location/radius via `TrailVenueLookupPort`
2. App obtains user location and permission (not in engine)
3. `TrailCheckInPolicy.assess` returns structured eligibility
4. `TrailProgressService.planCheckIn` produces progress + activity drafts

Missing venue location → **allowed** (mobile parity).

## Time handling

All policies accept explicit `DateTime now`. Use `TrailClock` in application services when needed. Assumes **local device/venue time** (mobile parity); timezone behaviour is undefined beyond `DateTime` local fields.

## Mapping boundary

`TrailSnapshotMapper` converts VexCore snapshots into normalized domain models:

- Resolves `name`/`title` and `description`/`subtitle` once at the boundary
- Unknown trail **status** → mapping failure (no silent default to draft)
- Unknown trail **type** missing → defaults to curated (mobile parity)
- Unknown stop state → failure unless empty (defaults to upcoming)

Domain policies never read persistence alias pairs directly.

## Relationship to VexCore

Repositories and commands live in `packages/vex_core/lib/trails/`. VexTrail produces transition plans that application facades later translate into VexCore commands.

## Dependencies

- `vex_core` for snapshots/events/repository contracts
- No Firebase SDK
- No Flutter SDK

## Application layer (orchestration)

Repository-backed services live in `lib/trail/application/`:

- Load snapshots through VexCore repositories
- Map to domain via `TrailPersistenceMapper` / `TrailSnapshotMapper`
- Apply domain policies via pure services (`TrailProgressService`, `TrailLifecycleService`, …)
- Persist through adapter commands
- Append activity and publish events via `TrailPersistenceCoordinator`

Mobile Firebase adapters live in `apps/nightlife_app/lib/core/vexcore/`. Production `TrailService` delegates to `TrailServiceFacade` by default; see `MOBILE_FACADE_MAPPING.md` and `apps/nightlife_app/docs/TRAIL_CUTOVER_REGRESSION.md`.

## Known preserved weaknesses

See tests and `MIGRATION_PLAN.md` for documented risks (client-side geofence, status/published duplication, check-in terminal completion, legacy progress mirror, etc.).

## Venue participation applications

See [TRAIL_PARTICIPATION.md](TRAIL_PARTICIPATION.md) for the `trail.venue_participation` workflow foundation (eligibility, duplicate policy, approval planning without automatic stop mutation). Venue Management UI in `nightlife_web` completes the venue-facing apply / draft / resubmit / withdraw flows; administrator review remains deferred.
