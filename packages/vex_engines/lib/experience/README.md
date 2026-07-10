# Experience Engine

## Intended responsibility

Version 1 launch engine for everything a venue publishes to customers:

- drinks, deals, and events (runtime support)
- shared publishing lifecycle, visibility, scheduling, validation
- featured flags and limits
- search-term preparation for discovery indexing
- in-memory content orchestration for public surfaces

Future-ready structure only (not implemented in Version 1):

- menus, happy hours, promotions, announcements, seasonal experiences

## May depend on

- VexCore public read contracts: `VenueDrinkDataService`, `VenueDealDataService`, `VenueEventDataService`
- VexCore `DataResult` and shared primitives where write preparation returns results
- Engine-neutral value objects in `domain/` and `shared/`

## Must not contain

- Flutter UI imports in `domain/`, `application/`, or `data/`
- Firebase SDK imports anywhere in the engine
- Raw Firestore collection paths in domain or application layers
- Venue profile ownership (Venue Engine)
- Cross-venue discovery orchestration (Discovery Engine)
- Authentication, permissions, analytics, growth, POS, or distribution

## Layer layout

```text
experience/
  domain/          # content kinds, future placeholders
  application/     # visibility, validation, featured limits, orchestration
  data/            # future write repository interfaces (reads stay in VexCore)
  shared/          # search-term builder, featured sort helpers
  presentation/
    web/           # web management mapping helpers (later phase)
    mobile/        # mobile content surfaces (later phase)
  tests/           # engine test documentation
```

## VexCore contract rule

Public venue content **read contracts** remain in VexCore (`packages/vex_core/lib/venue_drinks`,
`venue_deals`, `venue_events`). The Experience Engine **consumes** those services for reads and owns
**business rules** for publishing, visibility, scheduling, validation, featured flags, and search-term
preparation. Firebase adapters remain in app shells.

## Performance rule

Migrations into this engine must not add network calls, duplicate Firestore listeners,
re-fetch the same content, or introduce extra mapping on hot paths. Prefer in-memory
orchestration over additional repository calls.

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

`docs/master-blueprint.md` does not exist yet. This rule is recorded here until the Master Blueprint is created.

## Migration status

| Phase | Status | Notes |
| --- | --- | --- |
| 0 — Structure | Complete | Folder layout, README, migration plan |
| 1 — Shared rules batch | Complete | Visibility, featured limits, search terms, scheduling, orchestration |
| 2 — Web write facades | Complete | Write payloads and public filters delegate to engine |
| 3 — VexCore parity | Planned | Optional delegation from VexCore visibility modules |
| 4 — Write contracts | Planned | Engine-owned write repository interfaces |
| 5 — Presentation | Planned | Web/mobile management view-model helpers |

## Replaces separate Drink/Deal/Event engines

Version 1 consolidates drinks, deals, and events under one Experience Engine rather than three
separate content engines. VexCore read modules remain for generic contracts; business rules
live here.
