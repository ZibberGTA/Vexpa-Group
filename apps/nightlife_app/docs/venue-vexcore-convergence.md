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
| Owner catalog | 1 × owner query listener | Unchanged (direct Firestore) |

## Remaining direct Firestore (deferred)

- Owner add/edit venue writes
- `VenueService.getVenuesForOwner`
- Map screen venue preload
- Venue discovery search preload
- Trending/recommendation venue reads

## Rollback

Point `VenueService`, `VenueDetailsService`, and `StartupDataService` back to inline Firestore queries.
Remove `lib/core/vexcore/` wiring. Engine and VexCore packages can remain unused without Firebase Rules changes.
