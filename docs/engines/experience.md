# Experience Engine

## Overview

Version 1 launch engine for everything a venue **publishes to customers**: drinks, deals, and events — plus shared publishing lifecycle, visibility, scheduling, validation, featured rules, and search-term preparation.

## Purpose

Replace three would-be engines (Drink, Deal, Event) with **one content engine** so visibility, scheduling, and featured limits are consistent across mobile and web.

## Responsibilities

- Drink, deal, and event **visibility** rules (public vs management views)
- Deal scheduling and effective end datetime resolution
- Deal and event **management status** rules
- Featured limits and featured sort ordering
- Drink categories, deal types, validation
- Drink grouping for display
- Write field preparation (payloads adapted in app shells with Firebase types)
- Search-term building for content indexing (Experience layer; venue index uses Discovery builder)
- In-memory `ExperienceContentOrchestrator` for public content filtering/sorting

## Version

**Version 1** — launch engine. **Replaces** separate Drink/Deal/Event engines.

Future-ready placeholders only (not V1): menus, happy hours, promotions, announcements, seasonal experiences.

## Dependencies

- VexCore: `VenueDrinkDataService`, `VenueDealDataService`, `VenueEventDataService`, `DataResult`
- Discovery Engine: consumes search terms produced by Experience/Discovery builders — no direct dependency on Discovery private code

## Uses VexCore Layers

| Layer | Usage |
| --- | --- |
| Vex Data Engine | Public content reads |
| Shared primitives | Result types for validation |

## Owns

- All content publishing business rules above
- Content kind enumeration and future placeholders in `domain/`

## Consumes

- VexCore read services for drinks, deals, events
- Adapter-provided timestamps and field values for write preparation

## Provides

- Visibility, scheduling, status, validator, grouper, write preparation modules
- Web: `public_venue_content_filters`, write payload shims, repository orchestration
- Mobile: `deal_service`, `event_service`, `drink_service` delegation paths

## Current Status

**~78% complete**

| Phase | Status |
| --- | --- |
| Shared rules batch | Complete |
| Web write facades + orchestrator | Complete |
| Mobile grouping/search-term adoption (Batch B) | Complete |
| VexCore optional visibility delegation | Planned |
| Engine-owned write repository interfaces | Planned |
| Presentation layer | Planned |

## Future Features

- Engine-owned write contracts in `data/`
- Presentation view models
- Extended content kinds when product expands beyond drinks/deals/events

## Technical Notes

- VexCore **cannot import** `vex_engines` — public visibility filtering on web happens at repository boundary.
- Package: `packages/vex_engines/lib/experience/`

## Known Risks

- Residual inline write paths in mobile owner screens not yet delegated.
- Visibility split between VexCore data services and Experience orchestrator requires clear documentation for new contributors.

## Outstanding Work

- Remaining mobile write adoption
- Optional VexCore parity delegation
- Write repository interfaces
- Presentation helpers

**Deep dive:** [packages/vex_engines/lib/experience/README.md](../../packages/vex_engines/lib/experience/README.md) · [MIGRATION_PLAN.md](../../packages/vex_engines/lib/experience/MIGRATION_PLAN.md)
