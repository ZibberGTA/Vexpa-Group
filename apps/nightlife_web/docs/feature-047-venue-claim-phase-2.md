# FEATURE-047 Venue Claim Phase 2

## Overview

Phase 2 moves privileged venue-claim processing into Firebase Cloud Functions.
Clients can submit evidence and edit private draft data, but they must not assign
venue ownership or publish drafts directly.

The trusted backend is implemented in the Firebase-owning project:

- `nightlife_app/functions/src/index.ts`
- `nightlife_app/firestore.rules`

The web app calls those functions from:

- `nightlife_web/lib/features/venue_claims/data/venue_claim_repository.dart`

## Backend Functions

Callable functions:

- `submitVenueClaim`
- `evaluateVenueClaim`
- `approveVenueClaim`
- `rejectVenueClaim`
- `requestMoreClaimInfo`
- `publishApprovedClaimDraft`
- `createVenueInstant`

`createVenueInstant` is included because Phase 1 added owner-side venue creation,
and the client must not write ownership fields directly.

## Firestore Collections

Primary workflow:

```txt
venue_claims/{claimId}
venue_claims/{claimId}/audit/{eventId}
```

Manual review alerts:

```txt
admin_alerts/{alertId}
```

Live venue publishing:

```txt
venues/{venueId}
users/{uid}
```

## Status Transitions

Supported statuses:

- `draft`
- `pending_review`
- `needs_more_info`
- `auto_approved`
- `approved`
- `rejected`
- `completed`
- `error`

Allowed transitions:

- `draft` -> `pending_review`
- `pending_review` -> `approved`
- `pending_review` -> `rejected`
- `pending_review` -> `needs_more_info`
- `pending_review` -> `auto_approved`
- `needs_more_info` -> `pending_review`
- `needs_more_info` -> `rejected`
- `rejected` -> `pending_review`
- `auto_approved` -> `completed`
- `approved` -> `completed`
- `auto_approved` / `approved` -> `error`

Completed claims are terminal.

## Confidence Scoring

The backend recalculates confidence and ignores client-provided scores.

Current scoring:

- Business email domain matches venue website domain: +35
- Submitted website matches existing venue website: +30
- Submitted phone matches venue phone: +20
- Company registration supplied: +20
- Supporting document uploaded: +15
- Additional notes supplied: +5

Scores are capped at 100. The auto-approval threshold is 75.

The function stores:

- `confidenceScore`
- `confidenceReasons`
- `autoApproved`

## Admin Review Flow

Admins call trusted functions from the Venue Claims admin page:

- Approve: assigns ownership, publishes whitelisted draft fields, completes claim.
- Reject: marks rejected, stores notes, keeps draft data intact.
- Request more info: marks `needs_more_info`, stores notes, keeps draft data intact.

All major actions write audit events under `venue_claims/{claimId}/audit`.

## Draft Publishing

Only whitelisted fields can publish into `venues/{venueId}`:

- `name`
- `description`
- `logoUrl`
- `bannerImageUrl`
- `openingHours`
- `tags`
- `featureTags`
- `venueFeatures`
- `phone`
- `website`
- `websiteUrl`
- `socials`
- `socialLinks`
- `category`
- `venueType`
- `drinks`
- `deals`
- `events`
- `galleryImageUrls`
- `galleryImages`

Restricted ownership, billing, admin, and internal fields are never copied from
draft data.

## Security Assumptions

- Firebase Admin SDK writes bypass Firestore rules and are the trusted path.
- Callable functions verify auth and admin claims before privileged actions.
- Admin callers require `staff == true` and `roleLevel >= 30`.
- Normal clients cannot write ownership fields on `venues`.
- Normal users cannot self-assign `role` or `venueIds` on `users`.
- Claim draft data is readable only by the claimant and staff.
- Audit events are append-only for staff clients; backend writes bypass rules.

## Known Limitations

- No notification centre is built yet; pending claims create `admin_alerts` only.
- The auto-approval threshold is currently a backend constant, not an
  `app_settings` value.
- The frontend supports draft text fields/placeholders, not full media or nested
  drinks/deals/events draft editors yet.
- Callable Functions must be deployed before production use.

## Manual Test Notes

1. Submit strong evidence and confirm `submitVenueClaim` returns `completed`.
2. Submit weak evidence and confirm `pending_review` plus an `admin_alerts` doc.
3. Approve a pending claim and confirm `venues.ownerId`, `users.venueIds`, and
   `claimStatus` update through the function.
4. Reject a claim and confirm `draftVenueData` remains.
5. Request more information and confirm status becomes `needs_more_info`.
6. Call approve as a non-admin and confirm permission denied.
7. Try direct client updates to venue ownership fields and confirm rules reject.
8. Include restricted fields in `draftVenueData` and confirm they are not
   published.
9. Confirm audit events are written for submit, scoring, review, ownership, and
   draft publishing.
10. Confirm pending manual review creates an `admin_alerts` placeholder.

## Future Phase 3 Ideas

- Full claimant resubmission UI with document uploads.
- Admin notification badge powered by `admin_alerts`.
- Configurable scoring weights in `app_settings`.
- Dedicated draft editors for drinks, deals, events, and gallery media.
- Emulator-backed Firestore rules and callable function integration tests.
