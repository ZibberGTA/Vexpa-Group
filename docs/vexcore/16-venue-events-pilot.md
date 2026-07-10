# Venue Events Pilot

## What moved

Public venue events on the website now follow the same VexCore pattern as venue search, profile, drinks, and deals:

```text
VenueEventsSection
    ↓
VenueEventsRepository.watchEvents (page composition layer)
    ↓
VexCore VenueEventDataService
    ↓
VenueEventRepository
    ↓
FirebaseVenueEventRepository
    ↓
Firestore events collection
```

## What stayed outside VexCore

These paths still use existing web repositories or direct Firestore:

- venue event writes (add, update, delete, duplicate, bulk patch)
- venue management events dashboard (`watchManagementEvents`)
- unified search event queries
- event details page repository
- admin event moderation repositories
- mobile event services

## Behaviour preserved

- same Firestore query: `events` filtered by `venueId` and `isDeleted == false`
- same public visibility rules for current and upcoming events
- same sort order: by `startDateTime` ascending
- same live stream updates
- same loading, empty, and error states
- same featured styling on current event cards
- same legacy field mapping for `dateTime` and `artistName`
- same default four-hour end time when `endDateTime` is missing

Paused, expired, and draft (inactive) events remain hidden from the public page.

## Rollback path

1. Restore direct Firestore streaming in `VenueEventsRepository.watchEvents`.
2. Leave the VexCore contracts and Firebase adapter in place unused.
3. No Firebase Rules changes are required to roll back.

## Remaining direct events-related Firebase access

- `VenueEventsRepository` write methods and `watchManagementEvents`
- `venue_events_management_page.dart` via the same repository
- `event_details_repository.dart`
- `unified_search_service.dart` cross-venue event search
- admin dashboard event moderation

## Validation

- VexCore unit tests cover load, watch, empty venue IDs, repository failures, visibility filtering, and sort order.
- Web tests cover adapter mapping, legacy field mapping, ordering parity, and repository integration without live Firebase.
