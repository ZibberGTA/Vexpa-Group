# Experience Engine — Migration Plan

Status: **Phase 7 complete — admin CRM content summaries (~99%)**

This plan is derived from the current monorepo (`apps/nightlife_web`, `apps/nightlife_app`,
`packages/vex_core`, `packages/vex_engines`).

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

## Principles

1. VexCore keeps generic public read/write contracts for drinks, deals, and events.
2. Experience Engine owns venue-published content business rules and orchestration.
3. Apps keep routing, theming, Firebase adapters, and UI shell.
4. No migration may add duplicate listeners or extra Firestore reads.
5. One unified engine replaces separate Drink, Deal, and Event engines for Version 1.

## Classification key

| Tag | Meaning |
| --- | --- |
| **EXP** | Move into Experience Engine |
| **VC** | Stay in VexCore |
| **WEB** | Stay in web app shell |
| **MOB** | Stay in mobile app shell |
| **VEN** | Venue Engine |
| **DISC** | Discovery Engine |

---

## Batch 1 — Shared rules (complete)

Visibility, featured limits, search terms, scheduling, orchestration, drink/deal validators,
write preparation, drink grouper, deal/event management status.

---

## Batch 2 — Web write facades (complete)

Write payloads and public filters delegate to engine. Repository orchestration at boundaries.

---

## Batch 5 — Venue content services (complete)

| Source | Target | Notes |
| --- | --- | --- |
| Deal/drink table sort | **EXP** `VenueContentOrderingService` | Featured-first + column compare |
| Public deal/event ordering | **EXP** | Current-before-upcoming, start date |
| Gallery media sort | **EXP** | Featured → sortOrder → uploadedAt |
| Brand asset sort | **EXP** | isCurrent → logo → upload time |
| Duplicate deal/event | **EXP** `VenueFeaturedContentService` | Copy title, paused draft defaults |
| Event form validation | **EXP** `ExperienceEventValidator` | Title, dates, HH:mm range |
| Drink/deal/event presentation | **EXP** `VenuePresentationSupport` | Prices, labels, upcoming copy |
| Management metrics/activity | **EXP** `VenueContentSummaryService` | Counts, recent activity heuristics |
| Pause eligibility | **EXP** `VenueAvailabilityService` | Active/scheduled deals only |
| Gallery categories/legacy URLs | **EXP** `ExperienceGalleryCategories` | Public cap, legacy mapping |
| Web/mobile adapters | **WEB/MOB** | `WebExperienceContentSupport`, `MobileExperienceContentSupport` |

Network calls unchanged — all rules are in-memory.

---

## Batch 6 — Mobile owner writes + import validation (complete)

| Source | Target | Notes |
| --- | --- | --- |
| Mobile add/edit drink | **EXP** `ExperienceOwnerWriteService` | Preset create, edit validation, duplicate detection |
| Mobile add/edit deal | **EXP** | Legacy `drink_offer` schema, mobile search terms preserved |
| Mobile add/edit event | **EXP** | Legacy event fields, 4h end fallback |
| Bulk drink import validation | **EXP** `ExperienceDrinkImportValidator` | Row validation, booleans, price parse, duplicates |
| Mobile write payloads | **MOB** | `MobileDrinkWritePayload`, `MobileDealWritePayload`, `MobileEventWritePayload` |
| Web spreadsheet adapter | **WEB** | `DrinkSpreadsheetService` delegates validation to engine |

Network calls and Firestore field shapes unchanged — business rules only.

---

## Batch 7 — Admin CRM content summaries (complete)

| Source | Target | Notes |
| --- | --- | --- |
| Admin upcoming event filter | **EXP** `ExperienceAdminContentService` | Legacy startAt/startDate semantics preserved |
| Admin content summary assembly | **EXP** | Count fields supplied by repository I/O |
| Admin venue health scoring | **VEN** `VenueAdminHealthService` | 12-item checklist, accent tiers |
| Admin adapters | **WEB** | `AdminVenueContentSupport`, `AdminVenueHealthSupport` |

Firestore queries unchanged — repositories remain infrastructure only.

---

## Batch 8 — Presentation consolidation (complete)

| Source | Target | Notes |
| --- | --- | --- |
| Web deal/event/drink repo relative time | **EXP** `VenuePresentationSupport.managementRelativeTimeLabel` | Long-form owner UI preserved |
| Web venue highlights/tags | **EXP** `VenuePublicPresentationService` | `VenueHighlightsMapper`, `VenueDetailsMapper` adapters |
| Mobile map preview tags | **EXP** | Tag label formatting + preview fallbacks |
| Mobile venues drinks tab | **EXP** `ExperienceDrinkGrouper` + `VenuePresentationSupport` | Removed ~70 lines duplicated logic |
| Mobile deal/event models | **EXP** | `expiryLabel`, formatted date/time, 4h end fallback |
| Mobile venue feature tags | **EXP** | `parseFeatureTags` from Firestore maps |

UI strings unchanged — repositories and models are thin adapters only.

---

## Batch 3 — Remaining (optional)

| Source | Tag | Notes |
| --- | --- | --- |
| VexCore visibility modules | **DECIDE** | Parity tests only |
| Engine-owned write contracts | **EXP** | `data/` interfaces |

---

## Does not migrate here

| Capability | Owner |
| --- | --- |
| Venue profile | Venue Engine |
| Cross-venue search | Discovery Engine |
| Auth / permissions | VexCore |
| Analytics / growth | Growth Engine |
| Firebase adapters | App shells |
| UI tables and dialogs | App shells |
