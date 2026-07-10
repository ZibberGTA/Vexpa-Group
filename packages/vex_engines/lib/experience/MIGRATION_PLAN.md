# Experience Engine — Migration Plan

Status: **Phase 1 complete — shared rules batch migrated from web duplicates**

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

## VexCore (`packages/vex_core`)

| Path | Tag | Notes |
| --- | --- | --- |
| `lib/venue_drinks/*` | **VC** | Public drink read contracts |
| `lib/venue_deals/*` | **VC** | Public deal read contracts + visibility (parity tests) |
| `lib/venue_events/*` | **VC** | Public event read contracts + visibility (parity tests) |
| `test/venue_*_data_service_test.dart` | **VC** | Contract tests stay with VexCore |

**Do not move** VexCore read repositories into the Experience Engine. Engines consume them.

---

## Batch 1 — Shared rules (complete)

| Source | Target | Notes |
| --- | --- | --- |
| `drink_write_payload.dart` `buildSearchTerms` | **EXP** `ExperienceSearchTermBuilder` | Identical logic consolidated |
| `deal_write_payload.dart` `buildSearchTerms` | **EXP** | Web payload delegates |
| `event_write_payload.dart` `buildSearchTerms` | **EXP** | Web payload delegates |
| `public_venue_content_filters.dart` | **EXP** visibility rules | Web filters delegate |
| `featured_*_limit.dart` | **EXP** `ExperienceFeaturedLimit` | Presets for drinks/deals/events |
| `deal_write_payload.dart` `combineDealDateAndTime` | **EXP** `ExperienceSchedulingUtils` | |
| `event_write_payload.dart` merge helpers | **EXP** | |
| `event_table_layout.dart` featured sort | **EXP** `sortExperienceFeaturedFirst` | |
| `AddDrinkFormValidator` | **EXP** `ExperienceDrinkValidator` | Category allow-list stays in web |

Network calls unchanged — all rules are in-memory.

---

## Batch 2 — Planned

| Source | Tag | Notes |
| --- | --- | --- |
| Web drink/deal/event repositories (writes) | **EXP** write preparation service | Engine prepares fields; Firebase stays in app |
| Mobile drink/deal/event surfaces | **EXP** | Adopt visibility and orchestration helpers |
| VexCore visibility modules | **DECIDE** | Cannot import engine from VexCore; parity tests only |

---

## Batch 3 — Future content (structure only)

| Kind | Tag | Notes |
| --- | --- | --- |
| Menus | **EXP** | Domain placeholder only |
| Happy hours | **EXP** | Domain placeholder only |
| Promotions | **EXP** | Domain placeholder only |
| Announcements | **EXP** | Domain placeholder only |
| Seasonal experiences | **EXP** | Domain placeholder only |

---

## Does not migrate here

| Capability | Owner |
| --- | --- |
| Venue profile | Venue Engine |
| Cross-venue search | Discovery Engine |
| Auth / permissions | VexCore |
| Analytics / growth | Future engines |
| Firebase adapters | App shells |
| UI tables and dialogs | App shells |
