# Venue Deals Pilot

## What moved

Public venue deals on the website now follow the same VexCore pattern as venue search, profile, and drinks:

```text
VenueDealsSection
    ↓
VenueDealsRepository.watchDeals (page composition layer)
    ↓
VexCore VenueDealDataService
    ↓
VenueDealRepository
    ↓
FirebaseVenueDealRepository
    ↓
Firestore deals collection
```

## What stayed outside VexCore

These paths still use existing web repositories or direct Firestore:

- venue deal writes (add, update, delete, duplicate, bulk patch)
- venue management deals dashboard (`watchManagementDeals`)
- unified search deal queries
- admin deal moderation repositories

## Behaviour preserved

- same Firestore query: `deals` filtered by `venueId` and `isDeleted == false`
- same public visibility rules for current and upcoming deals
- same sort order: current deals before upcoming, then by start date
- same live stream updates
- same loading, empty, and error states
- same featured styling on current deal cards

Paused, expired, hidden, draft, and deleted deals remain hidden from the public page.

## Rollback path

1. Restore direct Firestore streaming in `VenueDealsRepository.watchDeals`.
2. Leave the VexCore contracts and Firebase adapter in place unused.
3. No Firebase Rules changes are required to roll back.

## Remaining direct deals-related Firebase access

- `VenueDealsRepository` write methods and `watchManagementDeals`
- `venue_deals_management_page.dart` via the same repository
- `unified_search_service.dart` cross-venue deal search
- admin dashboard deal moderation

## Validation

- VexCore unit tests cover load, watch, empty venue IDs, repository failures, visibility filtering, and sort order.
- Web tests cover adapter mapping, hidden/draft/deleted exclusion, ordering parity, and repository integration without live Firebase.
