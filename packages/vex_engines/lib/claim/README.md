# Claim Engine

## Intended responsibility

Version 1 launch engine for venue ownership claims:

- claim submission validation and preparation
- claim status model and allowed transitions
- evidence validation, interpretation, and confidence scoring
- admin review decision validation and summaries
- ownership transfer and audit event preparation
- claim search interpretation, ranking, dedupe, and ordering
- claim list ordering and malformed record handling

## May depend on

- VexCore contracts: authentication context, identity, permissions, `DataResult`, storage, events
- Engine-neutral value objects in `domain/` and `shared/`

## Must not contain

- Flutter UI imports in `domain/`, `application/`, or `data/`
- Firebase SDK imports anywhere in the engine
- Raw Firestore collection paths in domain or application layers
- Venue profile editing (Venue Engine)
- Global permission evaluation (VexCore)
- Admin shell layout or routing

## Layer layout

```text
claim/
  domain/          # status, evidence, confidence score, result contracts
  application/     # submission, review, scoring, audit preparation
  data/            # future repository interfaces (adapters stay in apps)
  shared/          # search support, domain normalisation
  presentation/
    web/           # claim pages/dialogs (later phase)
    mobile/        # mobile claim surfaces (later phase)
  tests/           # engine test documentation
```

## VexCore contract rule

Authentication, identity, permissions, storage, and generic data contracts remain in VexCore.
The Claim Engine owns **claim business rules** and **workflow preparation**. Firebase callable
and Firestore adapters remain in app shells.

## Performance rule

Migrations must not add Firestore reads, writes, listeners, evidence uploads, identity lookups,
or notification calls. Engine work is in-memory validation and payload preparation only.

## Engine Acceptance Rule

An engine is not considered complete until:

- all code specific to that business capability has one clear home;
- both web and mobile can consume the engine where required;
- shared platform capabilities come from VexCore rather than being duplicated;
- the engine does not add unnecessary network calls or listeners;
- the engine has its own tests;
- the engine has its own documentation;
- failures can be traced clearly to that engine;
- the engine does not directly depend on another engine's private implementation.

## Migration status

| Phase | Status | Notes |
| --- | --- | --- |
| 0 — Structure | Complete | Folder layout, README, migration plan |
| 1 — Shared rules batch | Complete | Status, evidence, search support, scoring |
| 2 — Submission + review services | Complete | Validation and payload preparation |
| 3 — Web runtime slice | Complete | `VenueClaimRepository` submission/review/scoring |
| 4 — Search + summary batch | Complete | Search orchestration, summaries, evidence interpretation |
| 5 — Mobile + admin UI | Planned | Mobile claim flow; admin map repository |
| 6 — Write contracts | Planned | Engine-owned repository interfaces |

## Runtime flow (Version 1)

**Claim search**

```text
ClaimVenuePage
  → VenueClaimRepository.searchVenues
  → ClaimSearchService (query, dedupe, rank, order)
  → Firestore adapter (directory → indexed → fallback)
```

**Claim submission**

```text
ClaimVenuePage
  → VenueClaimRepository.submitClaim
  → ClaimSubmissionService.prepareSubmission
  → submitVenueClaim callable (unchanged)
  → Firestore
```

**Admin review**

```text
AdminVenueClaimsPage
  → VenueClaimRepository.approve/reject/requestMoreInformation
  → ClaimReviewService.prepareReview
  → approve/reject/requestMoreClaimInfo callable (unchanged)
  → Firestore
```

**Evidence review**

```text
AdminVenueClaimsPage
  → ClaimEvidenceInterpretation (field labels, completeness, reference scope)
  → VexCore private document reference (ClaimEvidencePaths)
  → WebVexCore.documentStorage adapter (no download when access denied)
```

Network calls unchanged: one callable per submission/review action; search query counts unchanged.
Claim evidence Storage rules remain **committed but undeployed** pending Java/emulator validation.
