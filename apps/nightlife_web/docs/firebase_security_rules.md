# Firebase Security Rules

Security rules for project `nightlife-app-19acd`. Canonical rule files:

- `nightlife_app/firestore.rules`
- `nightlife_app/storage.rules`

**Default posture: deny everything not explicitly allowed.**

The public website can be served without authentication, but Firestore and Storage must never expose private business data by accident.

## Role model

### Admin role source of truth (app + rules)

The web app resolves dashboard access in this order (`UserRoleService`):

1. **`staff/{uid}`** — primary source. A staff document with `role`, `roleLevel`, or `staff: true` grants admin dashboard access.
2. **Firebase Auth custom claims** — `staff: true` and `roleLevel` (used when staff doc is missing).
3. **`users/{uid}`** — fallback for `isAdmin`, `roleLevel >= 30`, or admin role names.

Firestore rules mirror this with `effectiveRoleLevel()` and `isStaffPrincipal()`:

- Custom claims (`request.auth.token.staff`, `request.auth.token.roleLevel`)
- `staff/{request.auth.uid}` document role/level
- `users/{request.auth.uid}` `isAdmin` / `roleLevel` / admin role name (self only — users cannot self-escalate via writes)

**Important:** Admins must have a `staff/{uid}` document whose document ID matches their Firebase Auth UID, or valid custom claims, for Firestore rules to grant admin reads. Email-only staff lookups resolve UI access but do **not** satisfy rules unless `staff/{uid}` exists.

### Role tiers

| Tier | Level | Examples |
|------|-------|----------|
| Support | ≥10 | Read users, venues, claims, reports |
| Admin | ≥30 | Full admin dashboard collections, CRM writes |
| Management | ≥60 | Staff invites, staff create/update |
| Founder | ≥100 | Financials, destructive deletes |

Custom claims (when set by Cloud Functions):

| Claim | Meaning |
|-------|---------|
| `staff: true` | Internal staff account |
| `roleLevel` | Numeric tier (see above) |

Helpers in rules:

- `signedIn()` — authenticated user
- `isSelf(uid)` — user owns the document
- `isStaffPrincipal()` — staff via claims, `staff/{uid}`, or `users/{uid}` admin fields
- `effectiveRoleLevel()` — highest level from claims, staff doc, or user doc
- `isSupportOrAbove()` — support dashboard reads (level ≥ 10)
- `isAdmin()` — admin dashboard access (level ≥ 30)
- `isManagementOrAbove()` — management / founder staff management
- `isFounder()` — founder-only operations
- `ownsVenue(venueId)` / `isVenueOwner(venueId)` — venue `ownerId` matches UID
- `canManageVenue(venueId)` — owner, manager, assigned user, or admin

## Admin dashboard required permissions

The web admin dashboard (`AdminDashboardRepository`) reads these collections. Rules must allow **admin (level ≥ 30)** unless noted.

| Collection | Admin read | Admin write | Notes |
|------------|------------|-------------|-------|
| `users` | Support+ | Admin update | CRM user list |
| `staff` | Self + Support+ list | Management+ | Staff tab; self-read bootstraps role |
| `staff_invites` | Management+ | Management+ | Invites tab |
| `venues` | Support+ | Admin / owner | Includes hidden venues for CRM |
| `drinks`, `deals`, `events` | Support+ | Admin / owner | Catalog moderation |
| `venue_claims` | Support+ | Admin | Claims queue |
| `venue_claim_directory` | Signed-in | Admin | Claim search index |
| `reports` | Support+ | Support+ | Moderation |
| `analytics` | Support+ | — | Metrics |
| `customers` (+ subs) | Admin | — (Stripe extension) | Subscription CRM |
| `payment_events` | Admin | — | Billing events |
| `subscriptions` | Admin read | Founder write | Platform subscriptions |
| `app_settings` | Admin read | Founder write | Internal config |
| `audit_logs` | Admin read | Staff append | Audit trail |
| `account_deletion_requests` | Support+ | Support+ | GDPR queue |
| `favourites` | Support+ (per-user query) | — | User CRM context |
| `trails` | Support+ | Admin | Trail management |
| `notifications` | Support+ | — | Moderation |

Customers and venue owners are **blocked** from these list endpoints by role tier checks.

## Public venue visibility

A venue is **publicly readable** only when `isPublicVenue(data)` is true:

- `isDeleted` is not `true`
- `searchablePublic` is not `false` (defaults to public when field is absent)
- `isHidden` is not `true`
- `publicVisible` / `isVisible` are not `false`
- `status` is not `deleted`, `hidden`, or `suspended`

Admin hide/publish actions in the web CRM set `searchablePublic` alongside `isHidden` / `publicVisible`.

**Query alignment:** public venue list queries must include:

```dart
.where('isDeleted', isEqualTo: false)
.where('searchablePublic', isNotEqualTo: false)
```

The `isNotEqualTo: false` filter matches documents where the field is missing, `true`, or any value other than `false`.

## Collection-by-collection review

### `users`

| Operation | Who |
|-----------|-----|
| Read | Self, or support+ staff |
| Create | Self only; guest or safe self-service signup; no privilege escalation fields |
| Update | Self (safe profile fields only), admin, or support (limited fields + internal notes) |
| Delete | Founder only |

Subcollections `trail_state`, `trails/*/progress`: self only.

**Risk note:** Firestore cannot hide individual fields on read. Do not store payment card data, government IDs, or other highly sensitive PII in user documents.

### `staff`, `staff_invites`

| Operation | Who |
|-----------|-----|
| Read `staff/{uid}` | Self (own record), or support+ (list/CRM) |
| Write `staff` | Management+ |
| Read/write `staff_invites` | Management+ |

Authenticated users can read **only their own** `staff/{uid}` document so role resolution works before custom claims are synced.

### `venues` + `venues/{id}/media`

| Operation | Who |
|-----------|-----|
| Read | Public venues (approved visibility), venue managers, or support+ |
| Create | Signed-in users without ownership keys (claim/onboarding flow) |
| Update | Admins; venue managers (non-admin fields only, ownership unchanged); support (name/images only) |
| Delete | Founder |

Venue owners **cannot** change: `ownerId`, visibility flags, subscription fields, status, or internal/admin notes.

**Known limitation:** Public venue reads return the full document. Fields like `ownerId` and `subscriptionPlanId` are still visible to unauthenticated clients for public venues. Mitigation options (future): move private fields to an owner-only subcollection or serve discovery via Cloud Functions.

### `drinks`, `deals`, `events`

| Operation | Who |
|-----------|-----|
| Read | Active, non-deleted items on public venues; venue managers; support+ |
| Create / update | Venue managers (same `venueId`); admins |
| Delete | Admin / founder |

**Risk note:** If a venue is hidden but its deals remain `isActive: true`, list queries may fail rule evaluation. Deactivate or hide catalog items when hiding a venue.

### `venue_claims` + `audit`

| Operation | Who |
|-----------|-----|
| Read | Claimant (own claim), support+ |
| Create | Claimant (draft / pending_review) |
| Update | Admin; claimant (resubmit only) |
| Audit subcollection | Read: claimant or support+; write: admin only |

### `venue_claim_directory`

Read: any signed-in user (claim search). Write: admin+.

### `trails`, `trail_progress`, `trail_activity`

- Published trails: public read
- Trail progress: self only
- Trail activity: create when signed-in; read admin+

### `artists`, `artist_profiles`, `artist_applications`

- Active public profiles: public read
- Profile write: self or admin
- Applications: applicant + admin

### `favourites`, `notifications`, `bookings`, `chats`

User-private data. Users access only their own records; support+ can read for moderation.

### `analytics`

| Operation | Who |
|-----------|-----|
| Read | Venue managers (own venue), support+ |
| Create | Anyone for **public** venues only (view/tap events) |
| Update / delete | Admin |

### `reports`, `admin_alerts`, `deleted_*`, `audit_logs`, `deleted_items`

Support+ or admin+ as appropriate. Audit logs: append-only for staff.

### `customers` (Stripe extension)

Read: self or management+. **All writes denied in rules** — Stripe extension uses Admin SDK.

### `financials`, `subscriptions`, `app_settings`

Founder or management only.

### `venue_boosts`, `monetisation_events`, `payment_events`, `smart_notification_logs`

Restricted to venue managers (boosts) or management+ (events/logs).

### Default deny

```
match /{document=**} { allow read, write: if false; }
```

Any collection not listed above is blocked.

## Storage rules

### Venue media (unchanged)

Path: `venues/{venueId}/media/{mediaType}/{fileName}`

| Operation | Who |
|-----------|-----|
| Read | Public venues, venue media managers, admin |
| Upload / update | Venue media managers; images only; max 10 MB |
| Delete | Venue media managers or admin |

### Claim evidence (private)

Path: `claims/{claimantUid}/evidence/{fileName}` — see [ADR-0010](../../../docs/decisions/0010-claim-evidence-storage-security.md)

| Operation | Who |
|-----------|-----|
| Read | Claimant (`request.auth.uid == claimantUid`) or admin (level ≥ 30 via staff doc/claims) |
| Create | Claimant only; jpeg/png/webp/pdf; max 10 MB; **no overwrite** |
| Update | Denied |
| Delete | Claimant or admin |

Parity: `ClaimEvidenceDocumentPolicy.maxFileSizeBytes` and `allowedContentTypes` in the Claim Engine.

**Default deny** on all other paths.

Storage CORS is separate — see [firebase_setup.md](./firebase_setup.md).

## Emulator tests

From `nightlife_app/tests`:

```bash
cd tests
npm install
npm run test:rules
npm run test:storage-rules
```

Tests cover:

- Unauthenticated public venue read
- Customer blocked from admin collections
- Venue owner blocked from user list
- Admin (via `staff/{uid}` without custom claims) allowed to list users/venues/claims
- Default deny on unknown collections
- Claim evidence upload/read/delete (private path)
- Venue media storage parity

## Deploy rules

```bash
cd nightlife_web
firebase deploy --only firestore:rules,storage
```

## Pre-production checklist

- [ ] Backfill `searchablePublic: true` on all venues that should appear in discovery (if any were created before this field existed)
- [ ] Confirm hidden/suspended venues have `searchablePublic: false`
- [ ] Update mobile app venue list queries to filter `searchablePublic` (web queries updated; mobile still uses `isDeleted` only — see risk below)
- [ ] Deploy rules to a staging Firebase project and run integration tests
- [ ] Enable App Check before enforcing (see [firebase_app_check.md](./firebase_app_check.md))
- [ ] Review Firebase Auth authorized domains
- [ ] Confirm Storage CORS includes production domains

## Residual risks (not fully closed by rules alone)

1. **Field-level exposure on public venue documents** — owner and subscription metadata visible on public reads.
2. **Mobile app queries** — until mobile adds `searchablePublic` filters, venue list queries may fail if hidden venues exist in the result set.
3. **Storage URL guessing** — obscurity only; paths for non-public venues are blocked by rules.
4. **Analytics spam** — public venues accept anonymous event writes; consider App Check enforcement.
5. **Rules review is point-in-time** — new collections added to app code need matching rule entries.

Security is **not complete** until rules are validated against production data and all client query patterns in both web and mobile apps.
