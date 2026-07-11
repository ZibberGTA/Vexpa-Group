# Claim Engine — Migration Plan

Status: **Phase 4 complete — search orchestration, summaries, and evidence interpretation wired**

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
| `features/venue_claims/models/venue_claim.dart` | CLAIM/WEB | Migrated | Engine owns labels, list entries, malformed handling |
| `features/venue_claims/data/venue_claim_search_support.dart` | CLAIM | Migrated | Delegates to `ClaimSearchSupport` |
| `features/venue_claims/data/venue_claim_repository.dart` | WEB | Wired | Firestore/callables stay; search/review delegate to engine |
| `features/venue_claims/data/claim_evidence_upload_service.dart` | WEB/VC | Wired | VexCore document adapter; engine policy |
| `features/venue_claims/models/venue_claim_search_response.dart` | WEB | — | Search response wrapper |
| `features/business/screens/claim_venue_page.dart` | WEB | — | UI shell; uses repository |
| `features/admin/widgets/claims/admin_venue_claims_page.dart` | ADMIN | Wired | Metrics + evidence via engine; passes `reviewerCanApprove` |
| `features/admin/data/admin_claim_venue_repository.dart` | ADMIN | Later | Directory map load for admin |
| `features/admin/models/admin_claim_venue.dart` | ADMIN | Later | Admin map model |
| `test/venue_claim_search_support_test.dart` | WEB | — | Parity via facade |
| `test/claim_engine_delegation_test.dart` | WEB | Added | Engine delegation tests |
| `test/venue_claim_repository_search_test.dart` | WEB | Added | Search/review delegation tests |

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
| Storage uploads for evidence documents | VC/WEB | **Adapter complete** — Storage rules committed; **not emulator-validated / not deployed** |

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

## Batch 3 — Search + summary (complete)

| Source | Target | Notes |
| --- | --- | --- |
| Search query interpretation + limits | **CLAIM** `ClaimSearchService` | Directory → indexed → fallback unchanged |
| Candidate dedupe + ranking + ordering | **CLAIM** `ClaimSearchService` | Deterministic ties |
| Directory status labels + address format | **CLAIM** `ClaimPresentationSupport` | |
| Admin metrics + review readiness | **CLAIM** `ClaimSummaryService` | |
| Evidence review fields + reference scope | **CLAIM** `ClaimEvidenceInterpretation` | |
| Malformed claim records + ordering | **CLAIM** `ClaimRecordSupport` | |
| `reviewerCanApprove` wiring | **WEB** | Passed from admin permissions |
| `withdrawVenueClaim` repository method | **WEB** | Callable wired via `ClaimReviewService` |

Network calls unchanged.

---

## Remaining work

| Item | Tag | Notes |
| --- | --- | --- |
| Admin claim map repository | ADMIN | Keep in admin shell |
| Claim UI draft form extraction | WEB | `_draftData()` stays UI-local for now |
| Mobile claim submission | MOB | No flow exists yet |
| Engine write repository interfaces | CLAIM | Phase 6 |
| Cloud Function business rules | DECIDE | Server rules stay until server migration planned |
| Storage rules emulator validation + deploy | WEB/OPS | Java required; rules committed, not deployed |

## Rollback path

1. Revert web repository and admin page delegation commits.
2. Restore inline search limits/dedupe in `venue_claim_repository.dart`.
3. Restore local label/format helpers in `venue_claim.dart`.
4. Remove new engine services (`ClaimSearchService`, `ClaimSummaryService`, etc.).

No Firebase Rules changes required for rollback.

## Performance before and after

| Path | Reads | Writes | Callables | Listeners | Document downloads |
| --- | --- | --- | --- | --- | --- |
| Claim submit | 0 | 0 | 1 | 0 | 0 |
| Admin approve/reject | 0 | 0 | 1 | 0 | 0 |
| Claim search | unchanged | unchanged | 0 | 0 | 0 |
| Evidence review panel | 0 | 0 | 0 | 0 | 0 (URLs displayed only) |

Engine adds in-memory validation and ordering only.
