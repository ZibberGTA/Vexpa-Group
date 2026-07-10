# Discovery Engine

## Intended responsibility

Cross-venue discovery for Vexda:

- public search intent and query handling
- search ranking and relevance sorting
- discovery filters (venues, drinks, deals, events, trails, open now)
- venue catalog text matching and index merge
- unified search result composition
- nearby, map, trending, and recommendation orchestration (phased)

## May depend on

- VexCore contracts: authentication context, identity, permissions, `DataResult`, venue public read services
- Venue Engine shared helpers where discovery consumes venue field semantics (opening hours, search terms)
- Engine-neutral value objects in `domain/` and `shared/`

## Must not contain

- Flutter UI imports in `domain/`, `application/`, or `data/`
- Firebase SDK imports anywhere in the engine
- Raw Firestore collection paths in domain or application layers
- Venue master record ownership or venue management writes (Venue Engine)
- Generic auth, identity, or permission evaluation (VexCore)
- Claim review workflows (Claim Engine)

## Layer layout

```text
discovery/
  domain/          # filters, match models, searchable venue contracts
  application/     # search orchestration, ranking, response composition
  data/            # discovery repository interfaces (no Firebase)
  shared/          # text normalisation, open-status, venue text matcher
  presentation/
    web/           # web search pages/widgets (later phase)
    mobile/        # mobile search/map screens (later phase)
  tests/           # engine test documentation
```

## VexCore contract rule

Public venue **read contracts** remain in VexCore (`VenueDataService`, future cross-entity search repos).
The Discovery Engine **consumes** those services and owns **query interpretation, matching,
ranking, filters, and result composition**.

Venue records are not duplicated — discovery consumes venue snapshots from VexCore adapters.

## Performance rule

Migrations into this engine must not add network calls, duplicate Firestore listeners,
re-fetch the same catalog, or introduce extra mapping on hot search paths. Prefer one
catalog load and one index lookup per search, composed in memory by the engine.

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
| 1 — Pure domain/shared | Complete | Text utils, matcher, filters, open status, match models |
| 2 — Application orchestration | Complete | Venue search merge, unified response composer, ranking |
| 3 — Web runtime slice | Complete | `VenueSearchDataSource` + `UnifiedSearchService` composition |
| 4 — Presentation | Planned | Search pages, map widgets, mobile screens |
| 5 — Cross-entity contracts | Planned | Drinks/deals/events/trails via VexCore discovery repos |

See `MIGRATION_PLAN.md` for the file inventory and next batch.

## Runtime flow (web venue discovery)

```text
Search page
  → SearchRepository (web compatibility facade)
  → UnifiedSearchService + VenueSearchDataSource (web adapters)
  → Discovery Engine (matching, ranking, composition)
  → VexCore VenueDataService (catalog + index lookup)
  → FirebaseVenueRepository (Firestore)
```

## Rollback

Point web search data files back to local implementations and stop injecting
`DiscoveryVenueSearchService` / `DiscoveryUnifiedSearchComposer`. Engine modules
can remain unused without affecting Firebase Rules or UI.
