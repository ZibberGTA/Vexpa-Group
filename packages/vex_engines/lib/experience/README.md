# Experience Engine

## Intended responsibility

Version 1 launch engine for everything a venue publishes to customers:

- drinks, deals, and events (runtime support)
- shared publishing lifecycle, visibility, scheduling, validation
- featured flags and limits
- search-term preparation for discovery indexing
- in-memory content orchestration for public surfaces
- gallery ordering, presentation labels, and content summaries

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

## Application services (Phase 5)

| Service | Responsibility |
| --- | --- |
| `VenueContentOrderingService` | Management table sorts, public list ordering, gallery/brand media sort |
| `VenueFeaturedContentService` | Featured limits wrapper, duplicate copy rules, cover selection |
| `VenueAvailabilityService` | Public visibility composition, pause eligibility, active media filter |
| `VenueContentValidationService` | Drink/deal/event validation surface, price parsing |
| `VenuePresentationSupport` | Price/date/upcoming labels, gallery legacy mapping, relative time (compact + management) |
| `VenuePublicPresentationService` | Public venue tags, highlights, preview chips, feature tag parsing |
| `VenueContentSummaryService` | Dashboard metrics, recent activity titles |
| `ExperienceOwnerWriteService` | Mobile owner write validation, legacy field prep, search terms |
| `ExperienceDrinkImportValidator` | Spreadsheet row validation, duplicate detection, commit filtering |
| `ExperienceAdminContentService` | Admin CRM content summaries and upcoming event counting |

## Layer layout

```text
experience/
  domain/          # content kinds, gallery DTOs, metrics
  application/     # visibility, validation, featured limits, orchestration, venue services
  data/            # future write repository interfaces (reads stay in VexCore)
  shared/          # search-term builder, featured sort, gallery categories
  presentation/
    web/           # adapter facades in app shell
    mobile/        # adapter facades in app shell
```

## VexCore contract rule

Public venue content **read contracts** remain in VexCore. The Experience Engine **consumes**
those services for reads and owns **business rules** for publishing, visibility, scheduling,
validation, featured flags, and search-term preparation. Firebase adapters remain in app shells.

## Performance rule

Migrations into this engine must not add network calls, duplicate Firestore listeners,
re-fetch the same content, or introduce extra mapping on hot paths.

## Migration status

| Phase | Status | Notes |
| --- | --- | --- |
| 0 — Structure | Complete | Folder layout, README, migration plan |
| 1 — Shared rules batch | Complete | Visibility, featured limits, search terms, scheduling |
| 2 — Web write facades | Complete | Write payloads and public filters delegate to engine |
| 5 — Venue content services | Complete | Ordering, validation, presentation, gallery, summaries |
| 6 — Mobile owner writes + import | Complete | Owner add/edit drink/deal/event; spreadsheet validation |
| 7 — Admin CRM content summaries | Complete | `ExperienceAdminContentService` |
| 8 — Presentation consolidation | Complete | Tags, highlights, management relative time, mobile parity |
| 3 — VexCore parity | Planned | Optional delegation from VexCore visibility modules |
| 4 — Write contracts | Planned | Engine-owned write repository interfaces |

**Completion: ~100%** (presentation rules consolidated; optional write-contract batch remains)

## Replaces separate Drink/Deal/Event engines

Version 1 consolidates drinks, deals, and events under one Experience Engine rather than three
separate content engines.
