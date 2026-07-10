# FEATURE-047 — Venue claim search index backfill

One-off script to backfill searchable index fields on existing `venues` documents and populate `venue_claim_directory` for the web venue claim flow.

## Problem

The claim search UI queries indexed fields such as `searchKeywords`, `nameLower`, and `postcodeLower`, plus the `venue_claim_directory` collection. Older venue documents were created before these fields existed, so claim search returned no matches even when venues existed in Firestore.

## Script

Path: `scripts/backfill-venue-claim-search-indexes.mjs`

### What it updates

**On `venues/{venueId}` (merge only — unrelated fields are preserved):**

- `nameLower`
- `townLower`
- `cityLower`
- `postcodeLower`
- `addressLower`
- `searchKeywords`
- `isClaimed`
- `claimStatus`
- `updatedAt`

**On `venue_claim_directory/{venueId}` (safe claim-search fields only):**

- `venueId`, `name`, `nameLower`
- `address`, `addressLower`
- `town`, `townLower`
- `postcode`, `postcodeLower`
- `category`
- `bannerImageUrl`, `logoUrl`
- `isClaimed`, `claimStatus`
- `searchKeywords`
- `updatedAt`

### Search keyword generation

Keywords are derived from:

- Full venue name (lower-case)
- Individual name tokens and combinations (e.g. `red`, `lion`, `red lion`)
- Postcode full value, compact form, and partial outward tokens (e.g. `cm`, `cm12`)
- Town, address line tokens, category

### Address parsing

Supports mixed legacy schemas:

- `address` as string
- `address.line`, `address.line1`, `address.street`
- `address.city`, `address.town`
- Top-level `city`, `town`, `postcode`, `postalCode`
- Nested `location` objects when present

### Claim status rules

- **Has owner** (`ownerId`, `ownerUid`, non-empty `ownerIds`, etc.) → `isClaimed: true`, `claimStatus: claimed`
- **No owner** → `isClaimed: false`, `claimStatus: unclaimed`
- **Preserved statuses** are not overwritten: `blocked`, `suspended`, `deleted`, `rejected`, `pending`, `pending_review`, `needs_more_info`, etc.

### Safety

- **Dry-run by default** — no writes unless `--write` is passed
- Uses **batched writes** (200 venues per batch)
- Skips documents whose computed indexes already match
- Logs scanned / updated / skipped / claimed / unclaimed counts

## Prerequisites

1. Firebase Admin credentials:

   ```powershell
   set GOOGLE_APPLICATION_CREDENTIALS=C:\path\to\serviceAccount.json
   ```

2. Node dependencies installed in `scripts/`:

   ```powershell
   cd nightlife_app\scripts
   npm install
   ```

3. Deploy updated Firestore rules so authenticated users can read `venue_claim_directory`:

   ```powershell
   cd nightlife_app
   firebase deploy --only firestore:rules
   ```

## Commands

### Dry run (recommended first)

```powershell
cd nightlife_app\scripts
node backfill-venue-claim-search-indexes.mjs
```

Optional verbose logging:

```powershell
node backfill-venue-claim-search-indexes.mjs --verbose
```

### Write mode

```powershell
cd nightlife_app\scripts
node backfill-venue-claim-search-indexes.mjs --write
```

## After backfill

1. Log in to the web app as a venue owner.
2. Open **Claim Existing Venue**.
3. Search for existing venues by name, postcode, town, or address (e.g. `red`, `pulse`, `cm`, `basildon`).
4. Confirm result cards remain visible and **Claim Venue** opens the submission form.

If test venues are still missing, run the seed script (creates indexed test data only when absent):

```powershell
node seed-claim-test-venue.mjs
```

## Related

- Web search: `nightlife_web/lib/features/venue_claims/data/venue_claim_repository.dart`
- Keyword helpers: `nightlife_web/lib/features/venue_claims/data/venue_claim_search_support.dart`
- Test seed: `scripts/seed-claim-test-venue.mjs`
