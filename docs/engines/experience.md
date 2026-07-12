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
- Admin CRM content count interpretation and upcoming event semantics

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

**~100% complete** (presentation rules consolidated)

| Phase | Status |
| --- | --- |
| Shared rules batch | Complete |
| Web write facades + orchestrator | Complete |
| Mobile grouping/search-term adoption | Complete |
| Venue content services (ordering, validation, gallery, summaries) | Complete |
| Mobile owner write flows (drink/deal/event) | Complete |
| Bulk drink import validation | Complete |
| Admin CRM content summaries | Complete |
| Presentation consolidation (tags, highlights, relative time, mobile parity) | Complete |
| VexCore optional visibility delegation | Planned |
| Engine-owned write repository interfaces | Planned |

## Future Features

- Engine-owned write contracts in `data/`
- Optional VexCore parity delegation
- Extended content kinds when product expands beyond drinks/deals/events

## Technical Notes

- VexCore **cannot import** `vex_engines` — public visibility filtering on web happens at repository boundary.
- Package: `packages/vex_engines/lib/experience/`
- Adapter facades: `WebExperienceContentSupport` (web), `MobileExperienceContentSupport` (mobile), `AdminVenueContentSupport` (admin)
- Mobile write adapters: `MobileDrinkWritePayload`, `MobileDealWritePayload`, `MobileEventWritePayload`

## Known Risks

- Mobile deal schema uses legacy `drink_offer` type — preserved intentionally for runtime parity.

## Outstanding Work

- Optional VexCore parity delegation
- Write repository interfaces

**Deep dive:** [packages/vex_engines/lib/experience/README.md](../../packages/vex_engines/lib/experience/README.md) · [MIGRATION_PLAN.md](../../packages/vex_engines/lib/experience/MIGRATION_PLAN.md)
