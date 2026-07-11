# ADR-0010: Claim Evidence Storage Security

## Status

Accepted — 2026-07-11

## Context

Claim evidence uploads use the VexCore document storage contract at:

```text
claims/{claimantUid}/evidence/{fileName}
```

Application code, Claim Engine policy, and Firebase Storage rules must agree on ownership, MIME types, and size limits. Evidence is **private** — it must never be publicly readable like public venue media.

## Decision

1. **Claim Engine** owns evidence workflow rules (what is required, validation, submission).
2. **VexCore** owns provider-independent document contracts (`VexDocumentStorageService`, metadata, access evaluator).
3. **Firebase Storage** remains the Version 1 provider via web adapters.
4. **Claim evidence is private.** Read access is limited to:
   - the claimant (`request.auth.uid == claimantUid`);
   - authorised Vexda staff/admin reviewers (`isAdminOrAbove()` in `storage.rules`, mirroring the existing staff model).
5. **Upload/create** requires authenticated claimant ownership, allowed MIME types (`image/jpeg`, `image/png`, `image/webp`, `application/pdf`), and max size **10 MB** — parity with `ClaimEvidenceDocumentPolicy`.
6. **Updates are denied** (`allow update: if false`) — the app generates unique document ids; retries must use a new object name.
7. **Delete** is allowed for claimant and admin reviewers (moderation/compliance).
8. **Venue media rules are unchanged** for `venues/{venueId}/media/{mediaType}/{fileName}`.
9. **VexDocs** remains deferred — no separate document platform engine.

## Consequences

### Positive

- Claim evidence can be uploaded securely without exposing documents on public venue paths.
- Staff review access uses the same authoritative `staff/{uid}` + claims model already used for venue admin operations.
- Engine, adapter, and Firebase Rules stay aligned via shared constants documented in `ClaimEvidenceDocumentPolicy`.

### Negative

- Storage rules perform Firestore reads for staff/admin checks (existing pattern).
- Email-only staff resolution in the app UI does **not** grant Storage access without `staff/{uid}` or valid custom claims — same limitation as Firestore rules.

## Alternatives considered

| Alternative | Why rejected |
| --- | --- |
| Store evidence under `venues/{venueId}/media/...` | Claimants are not venue owners before approval |
| Public read for confidence scoring | Violates private evidence requirement |
| Client-provided role fields in metadata | Insecure — must use Auth uid and server-side staff docs |

## References

- [docs/engines/claim.md](../engines/claim.md)
- [docs/vexcore/11-foundation-lock.md](../vexcore/11-foundation-lock.md)
- `apps/nightlife_app/storage.rules`
- `packages/vex_engines/lib/claim/application/claim_evidence_document_policy.dart`
