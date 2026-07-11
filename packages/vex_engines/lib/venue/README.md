# Venue Engine

## Intended responsibility

Tenant-scoped venue business capability for Vexda:

- public venue profile presentation orchestration (where venue-specific)
- venue management dashboard workflows
- opening hours, contact details, and profile completion
- gallery and media ownership workflows
- venue ownership and staff context (consumed from VexCore identity/permissions)
- venue-specific validation and orchestration

## May depend on

- VexCore contracts: authentication, identity, permissions, data results, storage, events, configuration, observability
- VexCore public read services: `VenueDataService`, and venue-scoped content services where needed
- Shared engine-neutral value objects in `shared/`

## Must not contain

- Flutter UI imports in `domain/`, `application/`, or `data/`
- Firebase SDK imports anywhere in the engine
- Raw Firestore collection paths in domain or application layers
- Generic auth, identity, or permission evaluation (those stay in VexCore)
- Cross-venue discovery orchestration (Discovery Engine)
- Claim review workflows (Claim Engine)

## Layer layout

```text
venue/
  domain/          # venue-specific entities, invariants, validation rules
  application/     # use cases and orchestration (no Firebase, no Flutter)
  data/            # repository interfaces and DTO mapping contracts (no Firebase)
  shared/          # cross-layer venue helpers safe for web and mobile
  presentation/
    web/           # web-specific view models and mapping helpers
    mobile/        # mobile-specific view models and mapping helpers
  tests/           # engine unit tests (no live Firebase)
```

## VexCore contract rule

Public venue **read contracts** remain in VexCore (`packages/vex_core/lib/venue*`).
The Venue Engine **consumes** those services and owns **management writes**,
profile orchestration, and venue-specific workflows.

## Content engines (drinks, deals, events)

Drinks, deals, and events are owned by the **Experience Engine** (Version 1 launch engine).
VexCore keeps generic public read contracts (`venue_drinks`, `venue_deals`, `venue_events`).
The Experience Engine owns business rules; Firebase adapters stay in app shells.
See `packages/vex_engines/lib/experience/README.md` and `MIGRATION_PLAN.md`.

## Performance rule

Migrations into this engine must not add network calls, duplicate Firestore
listeners, or introduce extra mapping layers on hot paths. Prefer composition
over re-fetching when wiring presentation to VexCore services.

## Engine Acceptance Rule

An engine is not considered complete until:

- all code specific to that business capability has one clear home;
- both web and mobile can consume the engine where required;
- shared platform capabilities come from VexCore rather than being duplicated;
- the engine does not add unnecessary network calls or listeners;
- the engine has its own tests;
- the engine has its own documentation;
- failures can be traced clearly to that engine;
- the engine does not directly depend on another engine's private implementation.

`docs/master-blueprint.md` does not exist yet. This rule is recorded here until
the Master Blueprint is created.

## Migration status

| Phase | Status | Notes |
| --- | --- | --- |
| 0 — Structure | Complete | Folder layout, README, migration plan |
| 1 — Shared helpers | Complete | Contact utils, opening hours, image position, profile completion |
| 2 — Domain rules | Complete | Profile field codec/constants, image field parser |
| 3 — Profile update orchestration | Complete | `VenueProfileUpdateService` prepares writes; Firebase adapter persists |
| 4 — Dashboard orchestration | Complete | Active venue selection, whats-next, setup highlights, activity interpretation |
| 5 — Mobile read convergence | Complete | Public catalog, details watch, branding/hours helpers via VexCore adapter |
| 6 — Profile repository writes | Planned | Broader management orchestration beyond profile fields |

See `MIGRATION_PLAN.md` for the file inventory, classification, and phased
migration order.

## Dashboard orchestration (web — partial)

Venue-specific dashboard rules now live in the Venue Engine:

- `VenueActiveVenueSelector` — preferred venue and role-venue fallback
- `VenueWhatsNextComposer` — ordered setup guidance actions
- `VenueDashboardSetupHighlights` / `VenueDashboardHighlightComposer` — setup highlights and merge with analytics highlights
- `VenueActivityInterpreter` — venue-specific activity labels

Firebase queries, auth, permissions, and Flutter widgets remain in
`apps/nightlife_web`. Analytics metric math remains in the Analytics Engine.
Web maps engine DTOs through `VenueDashboardEngineMapper`.
