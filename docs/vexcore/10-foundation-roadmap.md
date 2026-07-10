# Foundation Roadmap

## Phase 0 — Structure and Audit

Create `packages/vex_core`, `packages/vex_engines`, and `docs/vexcore`. Audit Firebase access, identity, permissions, duplication, and migration risk.

Completion criteria:

- Shared package structure exists.
- Foundation docs are written.
- No feature code migrated.
- No Firebase Rules changed.
- Both apps remain structurally intact.

## Phase 1 — Core Contracts and Shared Primitives

Stabilise VexCore primitives: exceptions, results, clock, identifiers, auth/identity/permission/data/storage/events/integration/config/observability contracts.

Completion criteria:

- `vex_core` analyzes and tests cleanly.
- No Firebase or Flutter imports in pure VexCore contracts.
- Apps can add the local path dependency without runtime imports.

## Phase 2 — Authentication Adapter

Create app-compatible Firebase Auth adapter behind `AuthenticationService`.

Completion criteria:

- Mobile anonymous/provider/email behavior is covered.
- Web readiness/signup/login audit behavior is covered.
- Existing app services can delegate without changing user-facing behavior.

## Phase 3 — Identity Resolver

Model current identity resolution behind `IdentityService`.

Completion criteria:

- Tests cover custom claims, `staff/{uid}`, email fallback, `users/{uid}`, `venueIds`, owned venues, role aliases, and role levels.
- Bootstrap deadlock scenarios are tested.
- No final role model decision is made without test evidence.

## Phase 4 — Permission Evaluator

Centralise admin, venue staff, owner, employee, and entitlement decisions behind `PermissionService`.

Completion criteria:

- Web permission matrix is preserved.
- Mobile admin/management/founder behavior is preserved.
- Permission decisions accept context such as venue ID where needed.

## Phase 5 — Admin Route Pilot Migration

Use VexCore auth/identity/permission contracts in a narrow admin route guard pilot.

Completion criteria:

- Web `/admin` guard behavior is unchanged.
- Denied/loading/retry states remain equivalent.
- Rollback to legacy `UserRoleService` is straightforward.

## Phase 6 — Data Engine Repository Contracts

Define repository contracts for bounded data access without moving broad repositories.

Completion criteria:

- Public, admin, venue management, claim, and storage boundaries are named.
- Repository contracts do not contain Firebase paths.
- Tenant context requirements are explicit.

## Phase 7 — First Repository Migration

Migrate one narrow repository method behind a VexCore data contract.

Completion criteria:

- One small, well-tested method is migrated.
- Mobile and web still analyze.
- No Firebase Rules changes are needed.
- Rollback uses the existing repository path.

### Completed pilots

| Pilot | Status | Notes |
| --- | --- | --- |
| Public venue discovery catalog | Complete | Web search/catalog reads through `VenueDataService`. |
| Public venue details profile | Complete | Web `VenueDetailsRepository` load/watch through `VenueDataService`. |
| Public venue drinks menu | Complete | Web `VenueDrinksRepository.watchDrinks` through `VenueDrinkDataService`. |
| Public venue deals menu | Complete | Web `VenueDealsRepository.watchDeals` through `VenueDealDataService`. |
| Public venue events menu | Complete | Web `VenueEventsRepository.watchEvents` through `VenueEventDataService`. |
| Admin route guard | Complete | Web `/admin` guard uses VexCore auth/identity/permissions. |

See `13-venue-details-pilot.md`, `14-venue-drinks-pilot.md`, `15-venue-deals-pilot.md`, and `16-venue-events-pilot.md` for rollback paths.

### Venue Engine structure (in progress)

| Phase | Status | Notes |
| --- | --- | --- |
| Structure + migration plan | Complete | `packages/vex_engines/lib/venue/` |
| Phase 1 shared helpers | Complete | Contact, opening hours, image position, profile completion |
| Phase 2 domain rules | Complete | Profile field codec/constants, image field parser |
| Phase 3 profile updates | Complete | `VenueProfileUpdateService` + Firebase write adapter |
| Phase 4 orchestration | Planned | Dashboard aggregation and broader management workflows |

Engine Acceptance Rule documented in `packages/vex_engines/lib/venue/README.md`.
`docs/master-blueprint.md` still needs to be created.

## Phase 8 — Event Bus Foundation

Introduce event publishing for completed business actions only.

Completion criteria:

- Event base type and no-op/local adapter are tested.
- No command/query path is replaced by events.
- First event candidate has clear consumers and privacy review.

## Phase 9 — Enforce Architecture Rules

Add automated checks for forbidden imports and direct Firebase access in the wrong layers.

Completion criteria:

- VexCore domain folders reject Firebase imports.
- Engine folders reject Firebase imports.
- New direct Firebase access in UI is flagged.
- Existing legacy exceptions are tracked until migrated.
