# Risk Register

| Risk | Likelihood | Impact | Mitigation | Detection method |
| --- | --- | --- | --- | --- |
| Breaking mobile while fixing web | High | High | Keep contracts Firebase-free first; migrate adapters behind existing services; run both app analyzes. | Mobile analyze/tests and smoke route checks. |
| Breaking admin bootstrap | Medium | High | Preserve current staff self-read and fallback behavior until tests prove replacement. | Role resolver tests for claims, `staff/{uid}`, and denied reads. |
| Circular package dependencies | Medium | High | `vex_core` must not import apps or engines; engines may import VexCore only. | `dart analyze`, package import scans. |
| Parent-level packages not versioned with current Git repo | Medium | High | Decide whether parent workspace becomes the repo root or whether packages move under a versioned repo before CI/collaboration. | `git rev-parse --show-toplevel` from parent, apps, and packages. |
| Inconsistent Firebase package versions | Medium | Medium | Keep VexCore pure Dart; avoid Firebase dependencies in Foundation 1.0. | Pub get in both apps after adding path dependency. |
| Event misuse | Medium | Medium | Document request-response vs event boundary; use events only for completed actions. | Architecture review and tests around command paths. |
| VexCore becoming a god object | Medium | High | Keep layer folders separate; add small interfaces; avoid giant service classes. | Code review and import/LOC checks. |
| Public Firestore documents exposing private fields | Medium | High | Keep public discovery repositories behind contracts with explicit public DTOs. | Repository tests checking field filtering and `searchablePublic`. |
| Mixed domain and Firestore models | High | Medium | Introduce mapping/adapters gradually; keep domain objects Firebase-free. | Static import scans for Firebase in VexCore domain folders. |
| Incompatible mobile and web models | High | High | Use interfaces first; add parity tests before shared concrete models. | Golden tests for role and venue model mappings. |
| Moving too much code at once | High | High | Migrate one bounded unit at a time; keep rollback paths. | PR size checks and phase completion criteria. |
| Insufficient tests | High | High | Add contract and adapter tests before runtime swaps. | CI/analyze/test gates per package/app. |
| Hidden direct Firebase access | High | Medium | Repeat `rg` scans for Firebase products and operations after each phase. | Automated architecture scan. |
| Rules and app permissions diverging | Medium | High | Treat app permissions as UX guard only; verify Firebase Rules remain authoritative. | Emulator rules tests and denied-access tests. |
| Email-based staff matching | Medium | High | Treat as transitional; prefer `staff/{uid}` as rules-recognised source. | Logs/tests where found staff doc ID differs from auth UID. |
| Stale custom claims | Medium | Medium | Refresh tokens where needed; prefer Firestore source for live role changes if rules allow. | Tests for claim/doc mismatch and token refresh. |
| Tenant data leakage between venues | Medium | High | Permission context must include venue ID and ownership/assignment before venue repo migration. | Tenant isolation tests for venue dashboard reads/writes. |
| Storage path spoofing | Medium | High | Storage adapter must validate venue-scoped paths against identity context. | Upload/delete tests with mismatched venue IDs. |
| Analytics/intelligence privacy | Medium | High | Use anonymised or aggregated data where appropriate; avoid identifiable tenant joins. | Data review and privacy-focused tests. |
| Existing app warnings blocking validation | Medium | Medium | Distinguish pre-existing from new errors; do not fix unrelated warnings in Foundation 1.0. | Baseline analyze output captured before migration PRs. |
