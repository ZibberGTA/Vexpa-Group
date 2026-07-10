# Venue Engine — Migration Plan

Status: **Phases 0–2 complete for pure domain/shared helpers; orchestration not started**

This plan is derived from the current monorepo (`apps/nightlife_web`,
`apps/nightlife_app`, `packages/vex_core`, `packages/vex_engines`).

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

`docs/master-blueprint.md` does not exist yet. Record this rule in the Venue
Engine README until the Master Blueprint is created.

## Principles

1. VexCore keeps shared contracts and public read services.
2. Venue Engine owns venue-specific orchestration, validation, and management.
3. Apps keep routing, theming, and platform wiring until engine APIs stabilise.
4. No migration may add duplicate listeners or extra Firestore reads.
5. Drinks, deals, and events business rules live in the Experience Engine; VexCore keeps read contracts.

## Classification key

| Tag | Meaning |
| --- | --- |
| **VE** | Move into Venue Engine |
| **VC** | Stay in VexCore |
| **WEB** | Stay in web app shell |
| **MOB** | Stay in mobile app shell |
| **DISC** | Discovery Engine (future) |
| **CLAIM** | Claim Engine (future) |
| **OTHER** | Another engine or shared shell |
| **DECIDE** | Needs product/architecture decision |

---

## VexCore (`packages/vex_core`)

| Path | Tag | Notes |
| --- | --- | --- |
| `lib/venue/*` | **VC** | Public venue entity, repository contract, `VenueDataService` |
| `lib/venue_drinks/*` | **VC** | Public drink read contracts; consumed by profile and discovery |
| `lib/venue_deals/*` | **VC** | Public deal read contracts |
| `lib/venue_events/*` | **VC** | Public event read contracts |
| `test/venue_*_data_service_test.dart` | **VC** | Contract tests stay with VexCore |

**Do not move** VexCore venue modules into the Venue Engine. Engines consume them.

---

## Web — public venue profile (`features/venue/`)

| Path | Tag | Target layer |
| --- | --- | --- |
| `screens/venue_details_page.dart` | **WEB** → later **VE/web** | Presentation stays in app until engine presentation API exists |
| `widgets/**` | **WEB** → later **VE/web** | Section widgets; migrate as a group behind stable view models |
| `models/venue_details_view.dart` | **VE/web** | View model candidate |
| `models/venue_opening_hours_entry.dart` | **VE/shared** | Pure data; safe early migration candidate |
| `data/venue_details_repository.dart` | **WEB** | Thin VexCore facade; keep until composition root moves |
| `data/venue_details_mapper.dart` | **VE/web** | Maps VexCore `Venue` → view model |
| `data/venue_opening_hours_formatter.dart` | **VE/shared** | Pure formatting |
| `data/venue_contact_utils.dart` | **VE/shared** | Pure helpers |
| `data/venue_highlights_mapper.dart` | **VE/web** | Presentation mapping |
| `data/venue_related_repository.dart` | **DISC** | Related venues = discovery concern |
| `data/venue_drinks_grouper.dart` | **VE/web** | UI grouping for menu section |
| `data/public_venue_content_filters.dart` | **DECIDE** | Duplicates VexCore visibility for web models; consolidate later |
| `data/venue_events_repository.dart` | **WEB** | Composition + writes split; public read already via VexCore |
| `data/venue_deals_repository.dart` | **WEB** | Same pattern as events |
| `data/venue_drinks_repository.dart` | **WEB** | Same pattern as events |
| `data/models/event_model.dart` | **OTHER** | Event content; not Venue Engine core |
| `data/models/deal_model.dart` | **OTHER** | Deal content |
| `data/models/drink_model.dart` | **OTHER** | Drink content |

---

## Web — venue management (`features/venue_management/`)

| Path | Tag | Target layer |
| --- | --- | --- |
| `data/venue_profile_repository.dart` | **VE/data** | Profile write orchestration |
| `data/venue_profile_field_codec.dart` | **VE/domain** | **Migrated Phase 2** |
| `data/venue_dashboard_repository.dart` | **VE/application** | Dashboard aggregation |
| `data/venue_images_repository.dart` | **VE/data** | Gallery metadata |
| `data/venue_media_*` | **VE/data** | Upload orchestration (uses VexCore storage adapter) |
| `data/venue_analytics_service.dart` | **OTHER** | Analytics Engine |
| `data/venue_activity_service.dart` | **VE/application** | Activity feed for dashboard |
| `data/*_write_payload.dart` | **OTHER** | Content writes → content modules / future content engines |
| `services/venue_profile_completion_calculator.dart` | **VE/domain** | Pure rules |
| `services/subscription_service.dart` | **OTHER** | Growth/monetisation engine |
| `services/venue_media_access_service.dart` | **VE/application** | Entitlement orchestration |
| `models/**` | **VE/domain** | Dashboard and profile state |
| `widgets/**` | **WEB** → **VE/web** | Management UI stays in app initially |
| `screens/venue_dashboard_screen.dart` | **WEB** | Route host |

---

## Web — shared venue document model (`features/venues/`)

| Path | Tag | Notes |
| --- | --- | --- |
| `models/venue_model.dart` | **DECIDE** | Firestore document model used by adapters; may become adapter DTO in `data/` |
| `models/image_position_metadata.dart` | **VE/shared** | Image positioning value object |
| `data/venue_image_field_parser.dart` | **VE/shared** | **Migrated Phase 2** |

---

## Web — search (venue-specific files)

| Path | Tag | Notes |
| --- | --- | --- |
| `search/data/search_venue_*.dart` | **DISC** | Discovery Engine |
| `search/data/venue_search_matcher.dart` | **DISC** | |
| `search/models/venue_search_result.dart` | **DISC** | |
| `search/widgets/venue_result_card.dart` | **WEB** → **DISC/web** | |

---

## Web — claims and admin

| Path | Tag | Notes |
| --- | --- | --- |
| `venue_claims/**` | **CLAIM** | Claim Engine |
| `business/screens/claim_venue_page.dart` | **WEB** | Route shell |
| `admin/widgets/claims/admin_venue_claims_page.dart` | **WEB** | Admin shell |
| `admin/data/admin_claim_venue_repository.dart` | **CLAIM** | |

---

## Web — VexCore adapters (`core/vexcore/`)

| Path | Tag | Notes |
| --- | --- | --- |
| `firebase_venue_repository.dart` | **WEB** | Infrastructure adapter; stays in app until adapter package exists |
| `firebase_venue_*_repository.dart` | **WEB** | Same |
| `vex_venue_*_mapper.dart` | **WEB** | Maps Firestore DTOs ↔ VexCore entities |
| `web_vexcore.dart` | **WEB** | App composition root |

---

## Mobile (`apps/nightlife_app`)

| Area | Tag | Notes |
| --- | --- | --- |
| `features/venues/**` | **VE** (future) | Primary venue module; consolidate with web engine contracts |
| `features/home/models/venue_model.dart` | **DECIDE** | Duplicate of venues model; merge before engine migration |
| `features/home/services/venue_service.dart` | **VE/data** | Direct Firestore; replace with VexCore + engine |
| `features/owner/**` (venue screens) | **WEB/MOB** | Presentation shell; orchestration → Venue Engine |
| `features/map/venue_map_screen.dart` | **MOB** + **DISC** | Map UI in app; discovery logic in Discovery Engine |
| `core/utils/venue_branding_parser.dart` | **VE/shared** | Pure parser; early migration candidate |

---

## Recommended migration phases

### Phase 0 — Structure (complete)

- Create `packages/vex_engines/lib/venue/` layers and documentation.
- No app dependency on `vex_engines` until Phase 1.

### Phase 1 — Pure shared helpers (complete)

Moved into Venue Engine with web re-export shims:

- `venue_contact_utils.dart` → `venue/shared/`
- `venue_opening_hours_formatter.dart` + `venue_opening_hours_entry.dart`
- `image_position_metadata.dart` (Flutter alignment extension stays in web)
- `venue_profile_completion.dart` + calculator + input

Validation: unit tests in `packages/vex_engines/test/`; web imports unchanged.

### Phase 2 — Domain rules and value objects (complete)

Moved into Venue Engine with web re-export shims:

- `venue_profile_constants.dart` → `venue/domain/`
- `venue_profile_field_codec.dart` → `venue/domain/` (engine-neutral API;
  web shim adapts `VenueModel` for three display/selection helpers)
- `venue_image_field_parser.dart` → `venue/shared/`

Validation: `packages/vex_engines/test/venue/`; existing web tests compile
through compatibility exports.

### Phase 3 — Profile update orchestration (complete)

Moved into Venue Engine:

- `VenueProfileSearchContext` — engine-neutral search term context
- `VenueProfileUpdate` — prepared field map + server timestamp field names
- `VenueProfileUpdateService` — validates and prepares profile updates
- `VenueProfileWriteRepository` — write contract (implementation stays in web)

Web changes:

- `FirebaseVenueProfileWriteRepository` performs one merge write per update
- `VenueProfileRepository` delegates preparation to the engine and writes through the adapter
- Permission checks remain in the web compatibility repository

Rollback: point `VenueProfileRepository` methods back to inline Firestore writes;
leave engine contracts unused.

### Phase 4 — Broader management orchestration (next)

- Extract write orchestration from `venue_profile_repository.dart` into `venue/application/`.
- Keep Firestore adapters in web until a shared adapter strategy exists.
- Management widgets remain in web shell.

### Phase 3 — Public profile view models

- Move mappers and view models to `venue/presentation/web/`.
- Keep `VenueDetailsPage` in web; inject engine view models.
- Preserve single VexCore stream per section (no duplicate listeners).

### Phase 4 — Mobile convergence

- Align duplicate `VenueModel` classes.
- Route mobile reads through VexCore services.
- Move shared orchestration to engine; keep screens in mobile shell.

### Phase 5 — Adapter extraction (optional)

- Move Firebase adapters from `core/vexcore/` to a dedicated adapter package or engine `data/` implementations behind VexCore interfaces.

---

## Explicit non-migrations

| Item | Reason |
| --- | --- |
| VexCore `venue_drinks/deals/events` | Shared read contracts; used by discovery and detail pages |
| Unified search | Discovery Engine scope |
| Event/deal/drink management pages | Content management; separate from venue profile core |
| Auth, identity, permissions | VexCore infrastructure |
| Firebase Rules | Out of scope |

---

## Rollback

Each phase must be independently revertible. Prefer re-export shims at old import
paths during transition so app routes and listeners remain unchanged.
