# Mobile Venue VexCore Convergence

## Target flow

```text
Mobile venue screen/service
  → compatibility facade (VenueService / VenueDetailsService)
  → VexCore VenueRepository / VenueDataService
  → MobileVenueDocumentMapper + Venue Engine helpers
  → FirebaseVenueRepository
  → Firestore
```

## Migrated in this batch

| Path | Role |
| --- | --- |
| `lib/core/vexcore/firebase_venue_repository.dart` | Firestore queries, document parsing, VexCore contract |
| `lib/core/vexcore/mobile_venue_document_mapper.dart` | Shared mapping to VexCore `Venue` and mobile view models |
| `lib/core/vexcore/mobile_vexcore.dart` | Composition root |
| `lib/features/home/services/venue_service.dart` | Public catalog stream facade |
| `lib/features/venues/services/venue_details_service.dart` | Details watch facade |
| `lib/features/startup/services/startup_data_service.dart` | Startup catalog preload |
| `lib/core/utils/venue_branding_parser.dart` | Delegates to `VenueImageFieldParser` |

## Duplicate VenueModel decision

| Model | Status | Reason |
| --- | --- | --- |
| `features/home/models/venue_model.dart` | **Retained** | Owner/home/map fields (`ownerId`, `presenceRadiusMeters`, timestamps) |
| `features/venues/models/venue_model.dart` | **Retained** | Search card shape with `matchReasons` |
| `features/venues/models/venue_details_model.dart` | **Retained** | Rich profile view model for details tabs |
| VexCore `Venue` | **Used for catalog/load contract** | Shared business record without Flutter/Firebase types |

Full model merge deferred — compatibility shims are safer than a risky unified delete.

## Network calls (before → after)

| Flow | Before | After |
| --- | --- | --- |
| Home catalog stream | 1 × `venues` listener (`isDeleted==false`) | Same — 1 listener via adapter |
| Startup preload | 1 × `venues` get (limit 100) | Same — 1 get via `loadPublicVenues` |
| Details watch | 1 × venue doc listener | Same — 1 listener via adapter |
| Owner catalog | 1 × owner query listener | Same — 1 listener via adapter |

## Migrated in owner convergence batch

| Path | Role |
| --- | --- |
| `lib/features/owner/services/owner_venue_service.dart` | Owner list/create/update facade |
| `lib/core/vexcore/firebase_venue_write_repository.dart` | Firestore create/update adapter |
| `packages/vex_core/lib/venue/venue_write_repository.dart` | Firebase-independent write contract |
| `packages/vex_engines/.../venue_owner_profile_service.dart` | Validated owner create/update preparation |

## Network calls (owner batch — before → after)

| Flow | Before | After |
| --- | --- | --- |
| Owner venue list | 1 × owner query listener | Same — 1 listener via adapter |
| Add venue save | 1 × Firestore add | Same — 1 add via write adapter |
| Edit venue save | 1 × Firestore update | Same — 1 update via write adapter |
| Edit venue delete cascade | Direct Firestore reads/writes | Unchanged (deferred) |

## Remaining direct Firestore (deferred)

- Owner venue delete cascade (edit screen)
- Map screen venue preload
- Venue discovery search preload
- Trending/recommendation venue reads

## Rollback

Point `VenueService`, `VenueDetailsService`, and `StartupDataService` back to inline Firestore queries.
Remove `lib/core/vexcore/` wiring. Engine and VexCore packages can remain unused without Firebase Rules changes.
