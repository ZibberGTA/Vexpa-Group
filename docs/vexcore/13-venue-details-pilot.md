# Venue Details Pilot

## What moved

Public venue profile loading on the website now follows the same VexCore data path as venue search:

```text
VenueDetailsPage
    ↓
VenueDetailsRepository (page composition layer)
    ↓
VexCore VenueDataService
    ↓
VenueRepository
    ↓
FirebaseVenueRepository
    ↓
Firestore venues/{venueId}
```

## What stayed outside VexCore

The venue details page still loads these sections directly from existing web repositories:

- events
- related venue suggestions
- gallery-specific helpers
- venue management and admin repositories

Those remain deliberate follow-up migrations.

## Behaviour preserved

- same page layout, loading, not-found, and error states
- same live document updates for logo, banner, and profile fields
- same image positioning and opening-hours formatting in the web layer
- public visibility filtering aligned with Firestore `isPublicVenue()` rules

When a venue becomes hidden, deleted, suspended, or otherwise non-public while the page is open, the stream now resolves to `null` and the existing not-found UI is shown.

## Rollback path

1. Point `VenueDetailsRepository` back to direct Firestore reads.
2. Leave the VexCore contracts and Firebase adapter in place unused.
3. No Firebase Rules changes are required to roll back.

## Validation

- VexCore unit tests cover one-time load, watch streams, empty IDs, not-found, and repository failures.
- Web tests cover adapter mapping, hidden/deleted filtering, stream removal, and repository integration without live Firebase.
