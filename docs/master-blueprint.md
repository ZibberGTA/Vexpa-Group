# Vexda Master Blueprint

**Document ID:** VEXDA-MASTER-001  
**Status:** Product and architecture authority  
**Audience:** Leadership, product, engineering, future hires  
**Last updated:** 2026-07-11

This document is the **CEO handbook** for Vexda. It organises the platform and points to authoritative technical documentation. It does **not** replace engine READMEs, VexCore foundation docs, or ADRs — it references them.

---

## 1. Executive Summary

### What Vexda is

Vexda is a **nightlife discovery and venue growth platform**. It helps people find where to go tonight — venues, drinks, deals, events, and trails — and helps venue owners grow discoverability, reach, and engagement.

The platform ships as:

- A **Flutter mobile app** (`apps/nightlife_app`)
- A **Flutter web app** (`apps/nightlife_web`) — public site, business pages, venue portal, and admin portal
- Shared packages: **VexCore** (infrastructure contracts) and **Vex Engines** (business capability modules)

Philosophy in one line: **Venue Experience Discovery Advertising** — grow your venue, not simply manage it. See [VEXDA_PRODUCT_PRINCIPLES.md](../apps/nightlife_web/docs/VEXDA_PRODUCT_PRINCIPLES.md).

### Why it exists

Nightlife discovery is fragmented. Venues struggle to be found; customers struggle to decide where to go. Vexda connects both sides with a premium, discovery-first product that reuses one data model and one set of business rules across mobile and web.

### Long-term vision

Vexda becomes the **operating layer for venue-led hospitality discovery**:

- Consumers discover and plan nights out on mobile and web.
- Venues manage profile, content, analytics, and growth on the venue portal.
- Vexda operates the platform through an admin portal embedded in the website.
- Future capabilities — growth campaigns, intelligence, messaging, membership, bookings, ticketing, ordering, POS, and a separate **Distribution** platform — extend the same **VexCore + Engines** architecture without rewriting business logic when infrastructure changes.

---

## 2. Company Vision

### Mission

Help people discover great nights out and help venues grow through discoverability, experience, and measurable engagement.

### Vision

A trusted, premium nightlife platform used by consumers and venue operators across cities, with a architecture that scales to dozens of engineers and multiple product surfaces without fragmentation.

### Values

- **Customer-first discovery** — every surface answers a clear question and avoids dead ends ([Product Principles §2, §6](../apps/nightlife_web/docs/VEXDA_PRODUCT_PRINCIPLES.md)).
- **Venue-first growth** — business value is visible; owners understand why Vexda helps them grow ([Product Principles §7](../apps/nightlife_web/docs/VEXDA_PRODUCT_PRINCIPLES.md)).
- **One product** — mobile and web extend the same experience; reuse before rebuild ([Product Principles §5, §9](../apps/nightlife_web/docs/VEXDA_PRODUCT_PRINCIPLES.md)).
- **Premium by default** — performance and polish equal trust ([Product Principles §4, §8, §10](../apps/nightlife_web/docs/VEXDA_PRODUCT_PRINCIPLES.md)).
- **Architecture discipline** — business logic has one home; infrastructure is swappable ([ADR-0001](./decisions/0001-engine-architecture.md), [ADR-0006](./decisions/0006-database-strategy.md)).

### Core principles

1. Documentation is part of the product ([ADR-0009](./decisions/0009-documentation-policy.md)).
2. Nothing bypasses VexCore for shared infrastructure ([ADR-0003](./decisions/0003-vexcore-layers.md)).
3. Engines own business capability; apps own UI and Firebase adapters ([ADR-0001](./decisions/0001-engine-architecture.md)).
4. Version scope is explicit — not everything ships in Version 1 ([ADR-0002](./decisions/0002-version-1-scope.md)).
5. Firebase is the launch backend; business logic must not depend on it directly ([ADR-0004](./decisions/0004-firebase-launch-strategy.md), [ADR-0006](./decisions/0006-database-strategy.md)).

### Success definition

- Consumers reliably answer “where should I go tonight?” on search and venue surfaces.
- Venues can claim, onboard, publish content, and see analytics without duplicate logic between mobile and web.
- Engineering can assign ownership by engine; failures trace to one module.
- The platform can migrate persistence (e.g. to PostgreSQL) without rewriting engines.

---

## 3. Product Philosophy

Summarised from [VEXDA_PRODUCT_PRINCIPLES.md](../apps/nightlife_web/docs/VEXDA_PRODUCT_PRINCIPLES.md). Full detail lives there.

| Theme | Principle |
| --- | --- |
| Problems we solve | Fragmented nightlife discovery; low venue discoverability; inconsistent venue data across channels |
| Customer-first | Every page answers one question within seconds; primary conversion is obvious |
| Venue-first | Owners see growth value — reach, discoverability, analytics — not just CRUD |
| Data | One Firestore model shared by mobile and web; public reads through VexCore contracts where migrated |
| Growth | Discovery-first; related venues, trails, deals; minimal dead ends |
| Design | Premium mandatory — glass, gradients, intentional motion; desktop extends mobile |
| Security | Firebase Rules authoritative; app permissions are UX guards ([firebase_security_rules.md](../apps/nightlife_web/docs/firebase_security_rules.md)) |
| Scalability | Engines + VexCore allow horizontal team ownership and backend migration |

---

## 4. VexCore

**Authoritative detail:** [docs/vexcore/](./vexcore/README.md)

### Why VexCore exists

Mobile and web duplicated Firebase Auth, Firestore access, role resolution, and permission checks with different names and thresholds. VexCore centralises **infrastructure contracts** so all surfaces share one definition of authentication, identity, permissions, data access, storage, events, integrations, configuration, and observability.

### Why nothing bypasses it

Bypassing VexCore recreates duplication, blocks backend migration, and breaks tenant isolation guarantees. New shared infrastructure must go through VexCore contracts and adapters.

### Layers

| Layer | Purpose |
| --- | --- |
| Authentication | Session lifecycle, sign-in/out, auth state |
| Identity | Who the actor is — roles, venue assignments, source metadata |
| Permissions | Context-aware allow/deny decisions |
| Vex Data Engine | Repository contracts, paging, `DataResult` |
| Storage | Upload, download URL, metadata, deletion |
| Event Bus | Completed business actions only — not request/response |
| Integrations & API | Cloud Functions, Stripe, external APIs |
| Configuration & feature flags | Environment and flag reads |
| Observability & audit | Logging, error reporting, audit events |
| Shared primitives | Exceptions, results, clock, identifiers |

See [02-layer-boundaries.md](./vexcore/02-layer-boundaries.md).

### Responsibilities

VexCore **is**: contracts and adapters for shared platform infrastructure.  
VexCore **is not**: UI, business engines, or venue-specific workflows.

### Contracts

Pure Dart contracts in `packages/vex_core` — no Firebase or Flutter imports in domain folders. Apps implement Firebase adapters behind interfaces.

Completed pilots include public venue catalog, details, drinks, deals, events reads, web admin route guard, mobile AuthGate adoption, mobile auth/identity/permission composition roots, in-process event bus, document storage contracts, configuration/logging defaults, and **web storage adapter pilots** (venue branding upload + claim evidence path).

**Foundation 1.0 — Locked (2026-07-11).** Contract surface frozen; storage adapter adoption is post-lock work — see [11-foundation-lock.md](./vexcore/11-foundation-lock.md).

### Future migration strategy

Phased: stabilise contracts → adapters → migrate one bounded repository method at a time → event bus → foundation lock → automated import enforcement. See foundation roadmap Phases 1–10.

### Database abstraction

Repositories expose engine-neutral DTOs. Collection paths live in adapters only. See [ADR-0006](./decisions/0006-database-strategy.md).

### Engine interaction

```text
Presentation (Flutter apps)
    ↓
Application / Engine (packages/vex_engines)
    ↓
VexCore contracts (packages/vex_core)
    ↓
Infrastructure adapters (app shells)
    ↓
Firebase / external services
```

Engines **consume** VexCore; they **must not** import Firebase or each other's private persistence. **Subscription entitlements** (what a plan allows) are evaluated through `EntitlementService` — engines must not compare raw plan name strings. See [docs/vexcore/README.md § Entitlements](./vexcore/README.md).

---

## 5. Engine Catalogue

**Index:** [docs/engines/README.md](./engines/README.md)

Each engine document follows the same structure. Technical READMEs and migration plans live under `packages/vex_engines/lib/<engine>/`.

### Version 1 engines

#### Venue Engine — [venue.md](./engines/venue.md)

| Field | Summary |
| --- | --- |
| Purpose | Tenant-scoped venue profile, management workflows, validation |
| Version | 1 |
| Status | ~93% — mobile owner reads/writes converged; web management writes planned |
| VexCore | Auth, identity, permissions, `VenueDataService`, storage |
| Owns | Profile field rules, opening hours, media semantics, profile updates, dashboard guidance |
| Consumes | VexCore public venue reads; Experience Engine owns drinks/deals/events content |

#### Discovery Engine — [discovery.md](./engines/discovery.md)

| Field | Summary |
| --- | --- |
| Purpose | Cross-venue search, ranking, filters, trending, recommendations |
| Version | 1 |
| Status | ~92% — unified search orchestration complete; presentation phase planned |
| VexCore | `VenueDataService`, searchable content DTOs (`Searchable*Record`) |
| Owns | Query normalisation, matching, relevance, search-term indexing rules |
| Consumes | Venue snapshots from VexCore — does not duplicate venue master data |

#### Experience Engine — [experience.md](./engines/experience.md)

| Field | Summary |
| --- | --- |
| Purpose | Drinks, deals, events — visibility, scheduling, validation, featured rules |
| Version | 1 (replaces separate Drink/Deal/Event engines) |
| Status | ~78% — Batch A/B migration complete on web and mobile |
| VexCore | `VenueDrinkDataService`, `VenueDealDataService`, `VenueEventDataService` |
| Owns | Publishing lifecycle, visibility, search-term prep for content |
| Consumes | VexCore read contracts; Firebase writes stay in app adapters |

#### Claim Engine — [claim.md](./engines/claim.md)

| Field | Summary |
| --- | --- |
| Purpose | Venue ownership claims — submission, evidence, review, scoring |
| Version | 1 |
| Status | ~70% — web wired; mobile claim UI planned |
| VexCore | Auth, identity, permissions, storage, events |
| Owns | Claim status model, evidence validation, confidence scoring |
| Consumes | Identity context; does not own global permissions |

#### Analytics Engine — [analytics.md](./engines/analytics.md)

| Field | Summary |
| --- | --- |
| Purpose | Venue metrics, charts, engagement, growth comparisons |
| Version | 1 |
| Status | ~90% — dashboard calculations + web/mobile aggregation wired |
| VexCore | Permissions (`viewAnalytics`); future analytics read service |
| Owns | Aggregation rules, chart bucketing, dashboard date ranges, activity ordering |
| Consumes | Count/get results from app adapters — no extra queries on migration |

### Discovery-adjacent (Version 1 product)

#### Trail Engine — [trail.md](./engines/trail.md)

Trails appear in search and web architecture (`trails` collection). Engine folder is a **placeholder**; trail composition rules are not yet migrated from apps.

### Future engines (documented, not Version 1)

| Engine | Document | Version target | Notes |
| --- | --- | --- | --- |
| Growth | [growth.md](./engines/growth.md) | 1.5–2 | Subscriptions, boosts, campaigns — partial logic today in app monetisation services |
| Intelligence | [intelligence.md](./engines/intelligence.md) | 2 | Recommendations/ranking beyond current scorers; anonymised data only |
| Messaging | [messaging.md](./engines/messaging.md) | 3 | Not in Version 1 |
| Membership | [membership.md](./engines/membership.md) | 3 | Not in Version 1 |
| Booking | [booking.md](./engines/booking.md) | 4 | Not in Version 1 |
| Ticketing | [ticket.md](./engines/ticket.md) | 4 | Not in Version 1 |
| Ordering | [ordering.md](./engines/ordering.md) | 4 | Not in Version 1 |
| POS | [pos.md](./engines/pos.md) | 4 | Not in Version 1 |
| Distribution | [distribution.md](./engines/distribution.md) | 4+ | Separate platform on VexCore — [ADR-0008](./decisions/0008-distribution-platform.md) |

---

## 6. Version Roadmap

### Version 1 — Launch platform

**In scope:**

- Public discovery: search, map, venue/event/trail/deal surfaces
- Venue portal: profile, drinks, deals, events, gallery, analytics, subscription UI
- Admin portal (within website): claims, venues, users, moderation
- Version 1 engines: **Venue, Discovery, Experience, Claim, Analytics**
- Trail **product** support via existing data model; Trail **Engine** migration deferred
- Firebase backend; VexCore foundation and engine migration in progress

**Explicitly NOT Version 1:**

- Ticketing
- Bookings
- Membership
- Ordering
- POS
- Distribution platform

See [ADR-0002](./decisions/0002-version-1-scope.md).

### Version 1.5 — Growth foundations

- **Growth Engine** extraction from app-level subscription/boost services
- Trail Engine migration (composition, publishing, discovery rules)
- VexCore analytics read contracts
- Discovery presentation layer; optional VexCore repository interfaces for adapter injection
- Automated architecture enforcement (Foundation Phase 9)
- Post-lock adoption backlog: document storage adapters, remaining Firestore paths, broader entitlements ([11-foundation-lock.md](./vexcore/11-foundation-lock.md))

### Version 2 — Intelligence and scale

- **Intelligence Engine** — insight and decision support on aggregated/anonymised data
- Event bus for completed business actions — **Foundation Phase 8 complete**
- Broader repository migration behind VexCore
- International and multi-city SEO expansion ([WEB_ARCHITECTURE Cities](../apps/nightlife_web/docs/WEB_ARCHITECTURE.md))

### Version 3 — Relationship and loyalty

- **Messaging Engine**
- **Membership Engine**
- Artist portal maturation (mobile artist dashboard exists today as precursor)

### Version 4 — Commerce and distribution

- **Booking Engine**
- **Ticketing Engine**
- **Ordering Engine**
- **POS Engine**
- **Distribution** as standalone platform consuming VexCore ([ADR-0008](./decisions/0008-distribution-platform.md))

Version numbers are planning horizons; sequencing may adjust based on venue demand and team capacity. Scope changes require ADR update.

---

## 7. Platform Architecture

**Web detail:** [WEB_ARCHITECTURE.md](../apps/nightlife_web/docs/WEB_ARCHITECTURE.md)

### Surfaces

| Surface | Codebase | Role |
| --- | --- | --- |
| Mobile app | `apps/nightlife_app` | Primary consumer discovery, map, venue detail, owner tools |
| Website (public) | `apps/nightlife_web` | Home, search, venue/event/trail/deals, cities SEO, download app |
| Business pages | `apps/nightlife_web` | Landing, pricing, claim, onboarding, contact sales |
| Owner / Venue Portal | `apps/nightlife_web` `/portal` | Authenticated venue management — desktop extension of mobile management |
| Admin Portal | `apps/nightlife_web` `/admin` | **Part of the website** — internal operations, not a separate deployable |
| Artist Portal | Mobile-first today | Artist dashboard and tools in mobile app; dedicated web portal future (V3) |
| Distribution (future) | Separate platform | Partner/supplier distribution using VexCore — not embedded in consumer app |

### Interaction model

```text
Consumer:  Mobile app  ←→  Shared Firestore  ←→  Web public + search
Venue:     Mobile owner tools  ←→  Shared Firestore  ←→  Web venue portal
Vexda ops: Web admin portal  ←→  Shared Firestore  ←→  Mobile admin services (parity)
Engines:   Both apps delegate business rules  →  vex_engines  →  vex_core
```

Admin and venue portal use **distinct layouts** after login but share Firebase project, VexCore contracts, and engines with mobile.

### Distribution (future)

Distribution will eventually become **its own platform** that consumes VexCore for identity, permissions, and data — not a Flutter screen inside the consumer web app. See [ADR-0008](./decisions/0008-distribution-platform.md).

---

## 8. Database Strategy

**ADR:** [0006-database-strategy.md](./decisions/0006-database-strategy.md)

### Launch

- **Firebase** (Firestore, Auth, Storage, Cloud Functions, Hosting)
- Canonical rules: `apps/nightlife_app/firestore.rules`, `storage.rules`
- Web hosting deploys from `apps/nightlife_web`; rules reference mobile canonical files

### Future

Possible migration to **PostgreSQL** (or another relational database) if scale, reporting, or analytical workloads require it. No commitment to timing — architecture must preserve optionality.

### Non-negotiable rules

1. **Business logic must never depend directly on Firebase** — only adapters do.
2. **VexCore exists to allow backend migration** without rewriting engines.
3. Collection paths and SDK calls stay in app adapter layers until VexCore data services absorb them.
4. Firebase Security Rules remain authoritative for data access; app permission checks are UX guards.

---

## 9. Security Principles

| Principle | Implementation |
| --- | --- |
| Authentication | Firebase Auth behind VexCore `AuthenticationService` ( phased ) |
| Permissions | Context-aware evaluator — admin, owner, staff, entitlements ([06-identity-permissions-audit.md](./vexcore/06-identity-permissions-audit.md)) |
| Engine isolation | No Firebase in engines; no cross-engine private persistence reads |
| Least privilege | Role levels; venue-scoped permission context; founder-only financials |
| Data ownership | Engines own business rules; VexCore owns infra; tenants own venue data |
| Auditability | Audit events for admin operations, claims, role changes (VexCore observability layer) |

Known risk: public venue documents may expose some owner/subscription fields — tracked in [firebase_security_rules.md](../apps/nightlife_web/docs/firebase_security_rules.md) and [09-risk-register.md](./vexcore/09-risk-register.md).

---

## 10. Revenue Strategy

Current and planned revenue lines aligned with existing product surfaces:

| Stream | Version | Notes |
| --- | --- | --- |
| Venue subscriptions | 1 | Starter / Professional / Premium / Corporate tiers ([WEB_ARCHITECTURE Pricing](../apps/nightlife_web/docs/WEB_ARCHITECTURE.md)) |
| Venue boosts | 1 | Mobile monetisation — migrates to Growth Engine |
| Future Growth subscriptions | 1.5–2 | Campaigns, promoted placement — Growth Engine |
| POS | 4 | Not Version 1 |
| Distribution | 4+ | Partner platform revenue — separate product |
| Future streams | TBD | Enterprise analytics, corporate groups, API access — require ADR before build |

Stripe integration exists for boosts/checkout paths in mobile; full subscription enforcement evolves with Growth Engine.

---

## 11. Hiring Roadmap

Planning horizon for a growing engineering organisation:

| Stage | Roles | Focus |
| --- | --- | --- |
| Founder | Founder-engineer | Architecture, VexCore, Version 1 engines, product |
| First hires | Full-stack / Flutter engineers | Engine migration, web portal parity, test coverage |
| Venue Success | Customer success, onboarding | Claim funnel, venue onboarding, support playbooks |
| Engineering | Backend-leaning engineer | VexCore adapters, Firebase rules, future DB migration |
| Sales | B2B sales | Corporate tiers, city expansion |
| Marketing | Growth marketing | SEO cities, launch campaigns |
| Support | Support ops | Admin portal queue, venue tickets |
| Operations | Ops / finance | Subscriptions, reporting |
| Executive (future) | CTO, CPO, COO | Scale team beyond ~50 engineers |

Hiring follows product milestones: Version 1 launch → Growth → Intelligence → Commerce.

---

## 12. Growth Strategy

| Phase | Strategy |
| --- | --- |
| Launch | Single-city or limited-city launch; premium web + mobile; venue claim funnel |
| Expansion | Additional cities via SEO `/cities/:slug`; trending and trails drive repeat discovery |
| International | Localise city pages; adapt opening-hours and currency when commerce engines arrive |
| Platform expansion | Version 1.5–4 engines; Distribution as separate platform; API partners via VexCore integrations |

Product-led growth loops: search → venue → save/download app → return; business landing → claim → portal → subscription.

---

## 13. Locked Decisions

| ID | Decision | ADR / reference |
| --- | --- | --- |
| 001 | **Engine Architecture** — business capability lives in versioned engines consuming VexCore | [ADR-0001](./decisions/0001-engine-architecture.md) |
| 002 | **VexCore Ownership** — shared infrastructure contracts centralised; apps implement adapters | [ADR-0003](./decisions/0003-vexcore-layers.md) |
| 003 | **Version 1 Scope** — five launch engines; no ticketing/booking/membership/ordering/POS/distribution | [ADR-0002](./decisions/0002-version-1-scope.md) |
| 004 | **Firebase Launch Strategy** — Firebase at launch; adapters only in apps | [ADR-0004](./decisions/0004-firebase-launch-strategy.md) |
| 005 | **Engine Acceptance Rule** — definition of engine completeness | [ADR-0005](./decisions/0005-engine-acceptance-rule.md) |
| 006 | **Admin Portal Architecture** — admin is part of website at `/admin` | [ADR-0007](./decisions/0007-admin-portal.md) |
| 007 | **Distribution Platform Strategy** — future separate platform on VexCore | [ADR-0008](./decisions/0008-distribution-platform.md) |
| 008 | **Database Migration Strategy** — optional PostgreSQL future; logic in engines/VexCore | [ADR-0006](./decisions/0006-database-strategy.md) |
| 009 | **Business Logic Ownership** — engines own rules; VexCore owns infra; UI in apps | [ADR-0001](./decisions/0001-engine-architecture.md) |
| 010 | **Documentation Policy** — blueprint or ADR before major architectural change | [ADR-0009](./decisions/0009-documentation-policy.md) |
| 011 | **Subscription Entitlements** — VexCore owns plan capabilities; billing stays in adapters | [docs/vexcore/README.md § Entitlements](./vexcore/README.md) |

**Document platform note:** Claim Engine owns claim evidence workflows. VexCore owns document storage, metadata contracts, permissions, and retrieval. VexDocs remains a future shared platform service if document management expands beyond claims.

Each ADR includes context, consequences, and review triggers.

---

## 14. Outstanding Work

High-level only — detail in [10-foundation-roadmap.md](./vexcore/10-foundation-roadmap.md) and per-engine migration plans.

### VexCore

- Phases 2–4: auth, identity, permission adapters (partial — admin guard pilot complete)
- Phase 6–7: broader repository contracts and migrations
- Phase 8–9: event bus, automated import enforcement

### Version 1 engines

- **Venue:** Phase 4 orchestration, broader management workflows
- **Discovery:** Presentation layer; mobile/web search path convergence; optional VexCore adapter contracts
- **Experience:** Remaining mobile write adoption; presentation helpers
- **Claim:** Mobile claim flow; admin presentation view models
- **Analytics:** VexCore analytics read service pilot
- **Trail:** Engine migration from app logic

### Platform

- Web route completion per [WEB_ARCHITECTURE.md](../apps/nightlife_web/docs/WEB_ARCHITECTURE.md)
- Duplication elimination ([07-duplication-audit.md](./vexcore/07-duplication-audit.md))
- Risk mitigations ([09-risk-register.md](./vexcore/09-risk-register.md))
- Growth Engine extraction from monetisation services

---

## 15. Revision History

| Version | Date | Author | Changes |
| --- | --- | --- | --- |
| 1.0 | 2026-07-11 | Vexda | Initial Master Blueprint — documentation foundation |

---

## Related documentation map

```text
docs/
  master-blueprint.md          ← you are here
  README.md                    ← documentation index
  decisions/                   ← ADRs
  engines/                     ← engine catalogue
  vexcore/                     ← VexCore foundation 1.0
apps/nightlife_web/docs/       ← web product + architecture
packages/vex_engines/lib/*/    ← engine README + MIGRATION_PLAN
packages/vex_core/             ← VexCore package README
```

When in doubt: **product principles → master blueprint → ADR → engine README → code.**
