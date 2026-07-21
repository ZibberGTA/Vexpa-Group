# Mobile stabilisation (post-migration)

Branch: `feature/vexcore-identity-foundation`

This batch stabilises the consumer Android app after VexCore identity migration. It does **not** deploy Firestore rules or change admin/owner security posture.

## Public read model

| Collection / path | Public list/get rule | Client filter |
|---|---|---|
| `venues` | `get`: full `isPublicVenue`; `list`: `isDeleted == false` and `searchablePublic != false` | `PublicVenueVisibility` / `MobileVenueDocumentMapper.isCatalogVisible` |
| `drinks`, `deals`, `events` | `list`: `isPublicCatalogItem`; `get`: also requires parent venue public | Search/map adapters drop non-public venues via `_loadVenue` |
| `venues/{id}/media` | `status == active`, `visible != false`, public venue | Query adds `visible == true` and `status == active` |
| `trails` | `published == true` or `status == published` | Map query adds `published == true` |
| `favourites/{uid}_{venueId}` | Signed-in owner only (`userId == auth.uid`) | Anonymous Firebase users supported |

## Anonymous favourites

- Guest sign-in uses Firebase anonymous auth (`AuthService.signInAnonymouslyIfNeeded`).
- Favourites documents remain `{uid}_{venueId}` with `userId` field.
- Anonymous users can add/remove/read only their own favourites.
- Credential linking on register uses `linkWithCredential` and preserves UID when linking succeeds.

## Guest profile field allowlist

Firestore `users/{uid}` self-update allowlist (unchanged):

- `name`, `displayName`, `email`, `pendingEmail`, `phone`, `city`
- `notificationPreferences`, deletion request fields, `status`, login metadata, `updatedAt`

Guests may update display name and city via `AccountSelfService`. Email/password changes are blocked for anonymous users in UI and service guards. Guest account screens show an optional display-name field and a **Create an account** action with copy: *Create an account to protect your saved venues and use them across devices.*

## Saved venues authentication

- Persistent saved venues require a Firebase user (anonymous or registered).
- Guests can save/remove favourites; the UID remains stable while anonymous persistence is available.
- When no Firebase user exists, save actions show: *Sign in or create an account to save venues across your devices.*
- Web `SavedPage` remains a sign-in placeholder — mobile is the authoritative saved-venues surface in Phase 1.

## Consumer read-only business data

- `DealService.watchPublicDealsForVenue` is read-only for customers; expiry is computed via `ExperienceDealVisibility`.
- `DealService.getDealsForVenue` + `deactivateExpiredDealsForVenue` remain for owner/admin maintenance surfaces only.
- Opening a venue no longer triggers deal writes.

## UI → adapter → engine direction

```
Screen/Widget → Feature service/facade → Firebase adapter/repository → Firestore
                              ↓
                     VexEngines (Firebase-free)
                              ↓
                          VexCore contracts
```

Consumer Firestore I/O moved into:

- `SearchService`, `MapDiscoveryService`, `FavouritesService`, `DrinkService`, `DealService`, `VenueMediaService`, `TrailService`, `NotificationService`, `FirebaseVenueRepository`

Documented exemption: `venue_details_screen.dart` drinks tab still types `QueryDocumentSnapshot` rows while I/O lives in `DrinkService`.

## Remaining mobile work

- Remove owner/admin/artist Firestore from screens (web remains admin platform).
- Migrate venue drinks tab to `DrinkModel` and drop the documented exemption.
- App Check provider (report-only in this batch).
- Denormalised `venueSearchablePublic` on catalog items for stricter list/get parity without app-side venue filtering.

## Validation

Run locally (not executed in CI by this doc):

```bash
cd apps/nightlife_app
flutter analyze
flutter test test/mobile_stabilisation_test.dart test/mobile_firestore_ui_boundary_test.dart
npm run test:rules
flutter build apk --debug
```

Rules changes are in `apps/nightlife_app/firestore.rules` — **do not deploy** until reviewed.
