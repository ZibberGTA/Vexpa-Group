# Discovery Engine

## Overview

Cross-venue discovery: search intent, query handling, text matching, ranking, filters, unified result composition, nearby ordering, trending, and recommendations.

## Purpose

Ensure **one shared implementation** of venue search and discovery rules across mobile and web — no duplicated matchers, normalisers, or sort logic in app shells.

## Responsibilities

- Query normalisation, tokenisation, alias expansion (e.g. whisky/whiskey)
- Venue text matching (web catalog matcher + mobile client matcher with match reasons)
- Search-term indexing rules for venue catalogs
- Relevance ranking and mobile grouped search merge/rank
- Nearby distance ordering and popularity fallback
- Filter state (platform-independent)
- Map centroid and coordinate validation (no Google Maps types in engine)
- Related venue similar/nearby scoring
- Trending and recommendation **scorers** (inputs from adapters)

## Version

**Version 1** — launch engine.

## Dependencies

- VexCore: `VenueDataService`, future cross-entity discovery read services, `DataResult`
- Venue Engine: shared field semantics (opening hours, search terms) where needed — not private persistence

## Uses VexCore Layers

| Layer | Usage |
| --- | --- |
| Vex Data Engine | Catalog and index lookups via adapters |
| Configuration | Filter and feature behaviour |

## Owns

- All discovery **business rules** listed above
- Search match DTOs and filter models in `domain/`

## Consumes

- Venue snapshots from VexCore (does not duplicate venue master records)
- Drink/deal/event/trail match inputs from adapters (Firestore queries stay in apps until VexCore repos exist)

## Provides

- `DiscoveryVenueSearchService`, `DiscoveryUnifiedSearchComposer`
- `DiscoveryVenueClientMatcher`, `DiscoveryNearbySorter`, `DiscoveryVenueSearchTermBuilder`
- `VenueSearchMatcher`, `DiscoveryRelatedVenueService`, trending/recommendation scorers
- Web: `SearchRepository`, `UnifiedSearchService` facades
- Mobile: `VenueSearchService`, `SearchService`, `SearchIndexService` delegation

## Current Status

**~88% complete**

| Phase | Status |
| --- | --- |
| Domain/shared | Complete |
| Application orchestration | Complete |
| Web runtime slice | Complete |
| Shared web/mobile logic | Complete |
| Venue search consolidation (Batch C) | Complete |
| Presentation + cross-entity VexCore repos | Planned |

Network: venue search path remains **1 catalog + 1 index lookup** per search.

## Future Features

- VexCore cross-entity discovery read contracts
- Remove direct Firestore from `UnifiedSearchService`
- Presentation pages under `presentation/web/` and `presentation/mobile/`
- Trail filter integration via Trail Engine when migrated

## Technical Notes

- Performance rule: no extra listeners, catalog reloads, or ranking passes on migration.
- Package: `packages/vex_engines/lib/discovery/`

## Known Risks

- Unified search still queries Firestore collections directly in web adapter until VexCore repos exist.
- Mobile `VenueSearchService` uses Firestore query path distinct from web index flow — convergence is product decision.

## Outstanding Work

- Presentation phase
- Cross-entity VexCore contracts
- Converge mobile venue search with web index where appropriate

**Deep dive:** [packages/vex_engines/lib/discovery/README.md](../../packages/vex_engines/lib/discovery/README.md) · [MIGRATION_PLAN.md](../../packages/vex_engines/lib/discovery/MIGRATION_PLAN.md)
