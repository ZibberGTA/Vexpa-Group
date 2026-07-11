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

**Status: Complete (Version 1).** Web and mobile `FirebaseAuthenticationAdapter` delegate to existing `AuthService` without extra Auth calls.

Completion criteria:

- Mobile anonymous/provider/email behavior is covered.
- Web readiness/signup/login audit behavior is covered.
- Existing app services can delegate without changing user-facing behavior.

## Phase 3 — Identity Resolver

Model current identity resolution behind `IdentityService`.

**Status: Complete (Version 1).** Web and mobile `FirebaseIdentityAdapter` wrap existing `UserRoleService` streams. Mobile role parsing delegates to shared `RoleResolver`.

Completion criteria:

- Tests cover custom claims, `staff/{uid}`, email fallback, `users/{uid}`, `venueIds`, owned venues, role aliases, and role levels.
- Bootstrap deadlock scenarios are tested.
- No final role model decision is made without test evidence.

## Phase 4 — Permission Evaluator

Centralise admin, venue staff, owner, employee, and entitlement decisions behind `PermissionService`.

**Status: Complete (Version 1).** Web `AuthGuard` and mobile admin permission checks delegate to `VexPermissionEvaluator` / `AdminPermissionMatrix`.

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

## Phase 6 — Entitlements (subscription access)

Centralise subscription tier normalisation, feature entitlements, and media limits in `packages/vex_core/lib/entitlements/`.

Completion criteria:

- Web `MediaSubscriptionLimits` and gallery gates delegate to VexCore.
- Mobile consumer feature gates delegate through `SubscriptionEntitlements` facade.
- Admin CRM tier labels use VexCore normalisers.
- No additional Firestore reads on entitlement evaluation paths.
- Unit tests cover each tier, unknown/missing plans, and fail-closed consumer plans.

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
| Unified search content DTOs | Complete | VexCore `Searchable*Record` + `UnifiedSearchCandidateBatch` for adapter-fed candidates. |
| Admin route guard | Complete | Web `/admin` guard uses VexCore auth/identity/permissions. |
| Mobile platform composition root | Complete | `MobileVexCore` wires auth, identity, permissions, entitlements, events, config, logging. |
| Document storage contracts | Complete | `VexDocumentStorageService`, metadata, access evaluator — adapters deferred. |
| In-process event bus | Complete | `InProcessVexEventBus` + venue profile update pilot events. |

See `13-venue-details-pilot.md`, `14-venue-drinks-pilot.md`, `15-venue-deals-pilot.md`, and `16-venue-events-pilot.md` for rollback paths.

### Venue Engine structure (in progress)

| Phase | Status | Notes |
| --- | --- | --- |
| Structure + migration plan | Complete | `packages/vex_engines/lib/venue/` |
| Phase 1 shared helpers | Complete | Contact, opening hours, image position, profile completion |
| Phase 2 domain rules | Complete | Profile field codec/constants, image field parser |
| Phase 3 profile updates | Complete | `VenueProfileUpdateService` + Firebase write adapter |
| Phase 4 dashboard orchestration | Complete | Active venue, whats-next, highlights, activity interpretation |
| Phase 5 management orchestration | Planned | Broader dashboard aggregation and management workflows |
| Mobile venue read convergence | Complete | VexCore adapter for catalog, details watch, engine branding/hours helpers |
| Mobile owner venue convergence | Complete | Owner list/create/update via VexCore write contract and Venue Engine validation |

Engine Acceptance Rule documented in `packages/vex_engines/lib/venue/README.md`.
See [docs/master-blueprint.md](../master-blueprint.md) and [ADR-0005](../decisions/0005-engine-acceptance-rule.md).
See `apps/nightlife_app/docs/venue-vexcore-convergence.md` for mobile rollback notes.

### Discovery Engine structure (in progress)

| Phase | Status | Notes |
| --- | --- | --- |
| Structure + migration plan | Complete | `packages/vex_engines/lib/discovery/` |
| Pure domain/shared batch | Complete | Text utils, matcher, filters, open status, match DTOs |
| Application orchestration | Complete | Venue search merge, ranking, unified composer |
| Web runtime slice | Complete | `VenueSearchDataSource` + `UnifiedSearchService` wired |
| Shared web/mobile logic | Complete | Related venues, trending/recommendation scorers, mobile search rules |
| Venue search consolidation (Batch C) | Complete | Shared matcher, search-term builder, nearby sorter, filter state, map geometry |
| Unified search orchestration (Batch D) | Complete | Cross-entity merge/rank/group; web Firestore adapter retained |
| Presentation + optional VexCore repos | Planned | Pages/widgets; repository interfaces for adapter injection |

Network calls unchanged on unified search path (1 index + up to 4 entity queries per search, parallelised).
See `packages/vex_engines/lib/discovery/MIGRATION_PLAN.md`.

### Experience Engine structure (Version 1 launch engine)

| Phase | Status | Notes |
| --- | --- | --- |
| Structure + migration plan | Complete | `packages/vex_engines/lib/experience/` |
| Shared rules batch | Complete | Visibility, featured limits, search terms, scheduling, orchestration |
| Web write facades | Complete | Write payloads and public filters delegate to engine |
| VexCore parity tests | Complete | Engine visibility matches VexCore deal/event rules |
| Write contracts + mobile | Complete | Batch B: catalogs, grouping, write prep, orchestrator, mobile adoption |
| Remaining experience work | Planned | Mobile write adoption, presentation layer |

The Experience Engine replaces separate Drink, Deal, and Event engines for Version 1.
VexCore read modules (`venue_drinks`, `venue_deals`, `venue_events`) remain generic contracts.
See `packages/vex_engines/lib/experience/MIGRATION_PLAN.md`.

### Claim Engine structure (Version 1 launch engine)

| Phase | Status | Notes |
| --- | --- | --- |
| Structure + migration plan | Complete | `packages/vex_engines/lib/claim/` |
| Shared rules batch | Complete | Status, evidence, search support, confidence scoring |
| Submission + review services | Complete | Validation and callable payload preparation |
| Web runtime slice | Complete | `VenueClaimRepository` submission/review/scoring wired |
| Mobile + admin presentation | Planned | No mobile claim flow yet; admin map stays in shell |

The Claim Engine owns venue-claim lifecycle rules. VexCore continues to own auth,
identity, permissions, and storage contracts. Firebase adapters remain in app shells.
See `packages/vex_engines/lib/claim/MIGRATION_PLAN.md`.

### Analytics Engine structure (Version 1 launch engine)

| Phase | Status | Notes |
| --- | --- | --- |
| Structure + migration plan | Complete | `packages/vex_engines/lib/analytics/` |
| Shared rules batch | Complete | Metrics composer, percent change, chart buckets |
| Aggregation services | Complete | Top entities, weekly growth, engagement |
| Web runtime slice | Complete | `VenueAnalyticsService` dashboard snapshot |
| Mobile runtime slice | Complete | `AnalyticsService` summary and growth |
| Dashboard calculations | Complete | Date ranges, stats, highlights, activity aggregation |
| VexCore read contracts | Planned | Optional analytics data service pilot |

The Analytics Engine owns venue metrics and aggregation rules for Version 1.
VexCore continues to own permissions; Firebase adapters remain in app shells.
See `packages/vex_engines/lib/analytics/MIGRATION_PLAN.md`.

## Phase 8 — Event Bus Foundation

Introduce event publishing for completed business actions only.

**Status: Complete (Version 1 pilot).** `InProcessVexEventBus` with typed platform events. Venue profile update publishes on web/mobile write adapters.

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

## Phase 10 — Foundation Lock

**Status: Complete (2026-07-11).** VexCore Foundation 1.0 contract surface is locked. See [11-foundation-lock.md](./11-foundation-lock.md).

Completion criteria:

- Lock scope, rules, and adoption backlog documented.
- Legacy visibility helpers deprecated with Experience Engine as canonical source.
- Mobile AuthGate and composition roots consume stable VexCore singletons.
- No new Firebase reads, Auth calls, or listeners added during lock work.

Post-lock work (adapters, repository migration, Phase 9 enforcement) continues on separate tracks.

## Phase 11 — Storage Adapter Adoption (post-lock)

**Status: In progress (2026-07-11).** Web Firebase adapters implement locked `VexStorageService` and `VexDocumentStorageService` contracts.

Completion criteria:

- `WebVexCore.storage` and `WebVexCore.documentStorage` expose stable singleton adapters.
- Venue logo/banner upload and gallery delete delegate to `VexStorageService` without duplicate SDK calls.
- Claim evidence upload orchestration uses `VexDocumentStorageService` + Claim Engine document policy.
- No VexCore contract breaking changes; Firebase Rules unchanged in this phase.
- Claim evidence live uploads blocked until rules ADR adds `claims/{uid}/evidence/*` — document explicitly.
