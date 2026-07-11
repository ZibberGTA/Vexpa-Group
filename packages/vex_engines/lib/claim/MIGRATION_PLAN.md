# Claim Engine — Migration Plan

Status: **Phase 3 complete — web submission and review validation wired**

## Classification key

| Tag | Meaning |
| --- | --- |
| **CLAIM** | Claim Engine |
| **VC** | VexCore |
| **WEB** | Web app shell / Firebase adapters |
| **MOB** | Mobile app shell |
| **ADMIN** | Admin shell (uses engine via repositories) |
| **VEN** | Venue Engine |
| **DECIDE** | Needs product/architecture decision |

---

## Web audit (`apps/nightlife_web`)

| Path | Tag | Batch | Notes |
| --- | --- | --- | --- |
| `features/venue_claims/models/venue_claim.dart` | CLAIM/WEB | Migrated | Engine owns status/evidence/score; web keeps Firestore models |
| `features/venue_claims/data/venue_claim_search_support.dart` | CLAIM | Migrated | Delegates to `ClaimSearchSupport` |
| `features/venue_claims/data/venue_claim_repository.dart` | WEB | Wired | Firebase/callables stay; submission/review/scoring delegate |
| `features/venue_claims/models/venue_claim_search_response.dart` | WEB | — | Search response wrapper |
| `features/business/screens/claim_venue_page.dart` | WEB | — | UI shell; uses repository |
| `features/admin/widgets/claims/admin_venue_claims_page.dart` | ADMIN | Wired | Passes claim status to review validation |
| `features/admin/data/admin_claim_venue_repository.dart` | ADMIN | Later | Directory map load for admin |
| `features/admin/models/admin_claim_venue.dart` | ADMIN | Later | Admin map model |
| `features/admin/widgets/admin_claim_venue_map.dart` | ADMIN | — | Map UI |
| `test/venue_claim_search_support_test.dart` | WEB | — | Parity via facade |
| `test/claim_engine_delegation_test.dart` | WEB | Added | Engine delegation tests |

## Mobile audit (`apps/nightlife_app`)

| Path | Tag | Notes |
| --- | --- | --- |
| `features/claims/` | — | **Not present** — no mobile claim UI yet |
| `scripts/backfill-venue-claim-search-indexes.mjs` | WEB/OPS | Index maintenance script |
| `scripts/seed-claim-test-venue.mjs` | WEB/OPS | Test seed script |
| Auth custom-claim lookups | VC | Not venue-claim workflow |

## VexCore / permissions

| Path | Tag | Notes |
| --- | --- | --- |
| `StaffPermission.venueClaimApprove` etc. | VC | Permission evaluation stays in VexCore |
| Storage uploads for evidence documents | VC/WEB | **Complete (rules drafted)** — adapter + ADR-0010; deploy `storage.rules` to enable live Firebase uploads |

---

## Batch 1 — Shared rules (complete)

| Source | Target | Notes |
| --- | --- | --- |
| `VenueClaimStatus` enum + transitions | **CLAIM** `ClaimStatus` | Web typedef compatibility |
| `VenueClaimEvidence` | **CLAIM** `ClaimEvidence` | |
| `VenueClaimScore` / signals | **CLAIM** `ClaimConfidenceScore` | |
| `VenueClaimSearchSupport` | **CLAIM** `ClaimSearchSupport` | |
| `scoreClaim` in repository | **CLAIM** `ClaimConfidenceScorer` | |
| Domain/email/phone normalisation | **CLAIM** `ClaimDomainUtils` | |

## Batch 2 — Workflow services (complete)

| Source | Target | Notes |
| --- | --- | --- |
| Submit validation + draft prep | **CLAIM** `ClaimSubmissionService` | Callable payload unchanged |
| Approve/reject/more-info validation | **CLAIM** `ClaimReviewService` | Notes required for reject/more-info |
| Audit + ownership fields | **CLAIM** `ClaimAuditPreparation` | Prepared for future writes |
| Open-claim conflict | **CLAIM** `ClaimStatusTransitions` | Client-side when statuses supplied |

Network calls unchanged.

---

## Remaining work

| Item | Tag | Notes |
| --- | --- | --- |
| Admin claim map repository | ADMIN | Keep in admin shell |
| Claim UI pages/dialogs | WEB | Presentation layer later |
| Mobile claim submission | MOB | No flow exists yet |
| Engine write repository interfaces | CLAIM | Phase 5 |
| Cloud Function business rules | DECIDE | Server rules stay until server migration planned |

## Rollback path

1. Revert web repository delegation commits.
2. Restore inline scoring/validation in `venue_claim_repository.dart`.
3. Restore local models in `venue_claim.dart`.
4. Remove `vex_engines` claim exports.

No Firebase Rules or schema changes required.

## Performance before and after

| Path | Reads | Writes | Callables | Listeners |
| --- | --- | --- | --- | --- |
| Claim submit | 0 | 0 | 1 | 0 |
| Admin approve/reject | 0 | 0 | 1 | 0 |
| Claim search | unchanged | unchanged | 0 | 0 |

Engine adds in-memory validation only.
