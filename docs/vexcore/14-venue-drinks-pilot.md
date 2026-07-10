# Venue Drinks Pilot

## What moved

Public venue drinks on the website now follow the same VexCore pattern as venue search and venue profile:

```text
VenueDrinksSection
    ↓
VenueDrinksRepository.watchDrinks (page composition layer)
    ↓
VexCore VenueDrinkDataService
    ↓
VenueDrinkRepository
    ↓
FirebaseVenueDrinkRepository
    ↓
Firestore drinks collection
```

## What stayed outside VexCore

These paths still use existing web repositories or direct Firestore:

- venue drink writes (add, update, delete, bulk import)
- venue management drinks dashboard
- unified search drink queries
- deals on the public venue page
- admin drink moderation repositories

## Behaviour preserved

- same drinks displayed on the public venue page
- same category grouping, featured state, prices, and availability icons
- same alphabetical sort within categories via `VenueDrinksGrouper`
- same live stream updates for menu changes
- same loading, empty, and error states

The adapter preserves the existing Firestore query:

- collection: `drinks`
- filters: `venueId`, `isDeleted == false`
- client-side exclusion of hidden/draft/non-public status fields when present

Unavailable drinks remain visible on the public page, matching the previous behaviour.

## Rollback path

1. Restore direct Firestore streaming in `VenueDrinksRepository.watchDrinks`.
2. Leave the VexCore contracts and Firebase adapter in place unused.
3. No Firebase Rules changes are required to roll back.

## Remaining direct drinks-related Firebase access

- `VenueDrinksRepository` write methods (management)
- `venue_drinks_management_page.dart` via the same repository writes
- `venue_dashboard_repository.dart` drink counts
- `unified_search_service.dart` cross-venue drink search

## Validation

- VexCore unit tests cover load, watch, empty venue IDs, repository failures, and deleted-drink filtering.
- Web tests cover adapter mapping, hidden/draft/deleted exclusion, grouping parity, and repository integration without live Firebase.
