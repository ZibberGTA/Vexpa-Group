# ADR-0007: Admin Portal Architecture

## Status

Accepted — 2026-07-11

## Context

Vexda requires internal operations tooling: claim review, venue approvals, user management, subscriptions oversight, trails curation, and support queues. Mobile already contains admin services; web needs equivalent capability for desktop operations.

Options included a separate admin application, a standalone SaaS admin product, or an authenticated area within the existing website.

## Decision

1. The **Admin Portal is part of the website** — route prefix `/admin` in `apps/nightlife_web`.
2. It is **not** a separate deployable or repository at launch.
3. Admin uses the **same Firebase project**, VexCore identity/permission contracts, and engines as mobile admin flows.
4. Admin layout is **distinct** from public marketing and venue portal shells after login.
5. Admin guard uses VexCore auth/identity/permissions (admin route pilot complete per foundation roadmap).
6. Mobile admin tools remain for field operations; **parity** is goal, not mandatory feature equivalence on every screen.

## Consequences

### Positive

- One web deploy; shared auth session with business/portal where appropriate.
- Reuses web VexCore wiring and Claim/Analytics engines.
- Lower ops burden than separate admin app.

### Negative

- Admin code lives in same Flutter web codebase — requires strict route guards and bundle awareness.
- Founder-level permissions must be carefully enforced (rules + app guards).

## Alternatives considered

| Alternative | Why rejected |
| --- | --- |
| Separate admin Flutter app | Duplicate routing, auth, deploy pipeline |
| Retool/external admin | Does not reuse engines; data model drift |
| Admin only on mobile | Poor fit for claim review and bulk operations |

## Future review

Revisit if admin bundle size or security isolation requirements justify split deploy (e.g. admin subdomain with separate build target — still same repo acceptable).

**References:** [WEB_ARCHITECTURE.md § Admin](../../apps/nightlife_web/docs/WEB_ARCHITECTURE.md), [10-foundation-roadmap.md § Phase 5](../vexcore/10-foundation-roadmap.md)
