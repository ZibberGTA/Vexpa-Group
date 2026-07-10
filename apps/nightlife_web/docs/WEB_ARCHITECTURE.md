# Vexda Web Platform — Architecture Blueprint

**Document ID:** WEB-ARCHITECTURE-001  
**Status:** Foundation  
**Project:** Vexda Web Platform (`nightlife_web`)  
**Mobile reference:** `nightlife_app`

---

## Purpose

This document is the master blueprint for the Vexda website. It is not a feature specification — it defines how the platform fits together as one connected product.

Every future web page, module, and implementation prompt should reference **[VEXDA_PRODUCT_PRINCIPLES.md](./VEXDA_PRODUCT_PRINCIPLES.md)** and this document before work begins.

**Core principle:** The desktop website is the natural evolution of the Vexda mobile app — not a separate product.

---

## Platform Vision

Vexda Web is a single connected platform built from shared foundations:

| Reuse from mobile | Apply on web |
|---|---|
| Design language (dark glass, pink/purple brand) | Larger-screen layouts, not new visual identity |
| Firestore models & collections | Same `venues`, `drinks`, `deals`, `events`, `trails` data |
| Business logic & search philosophy | Unified search, venue-centric results, match lines |
| Branding & animations | Desktop-appropriate motion and spacing |
| Venue/business management flows | Venue Portal with mobile-parity management UI |

Desktop should never feel like a marketing site bolted onto an app. It should feel like **Vexda on a larger screen**.

---

## Site Structure Overview

```
PUBLIC WEBSITE
├── Home
├── Search / Map
├── Venue Details
├── Event Details
├── Trail Details
├── Cities (SEO)
├── Deals
└── Download App

BUSINESS
├── Business Landing
├── Pricing
├── Claim Your Venue
├── Venue Onboarding
└── Contact Sales

VENUE PORTAL (authenticated)
├── Login
├── Dashboard
├── Venue Selector
├── Venue Management
│   ├── Drinks
│   ├── Deals
│   ├── Events
│   ├── Gallery
│   ├── Team
│   ├── Analytics
│   ├── Subscription
│   └── Support
└── …

ADMIN (authenticated)
├── Dashboard
├── Venue Approvals
├── Claims
├── Users
├── Subscriptions
├── Events
├── Trails
├── Support
└── Reports
```

---

## Public Website

### Home

**Route (planned):** `/`  
**Current status:** Implemented — hero, trending, trails, events, deals preview sections.

**Purpose:** Landing page introducing Vexda and driving discovery or conversion.

**Contains:**

- Hero search
- Trending venues
- Tonight's Trails
- Featured events
- Featured deals
- Download App CTA
- Business CTA

**Primary navigation:**

| Link | Destination |
|---|---|
| Search | Search / Map |
| Venue | Venue Details (via discovery paths) |
| Business | Business Landing |
| Download App | Download App |

**Links out:** Search, Business Landing, Download App.

---

### Search / Map

**Route (planned):** `/search`  
**Current status:** Implemented — Google Map, floating search, results panel, unified Firestore search, filters.

**Purpose:** Primary discovery experience for venues, drinks, deals, events, and trails.

**Contains:**

- Google Map (venue markers, selection sync, smooth camera)
- Floating search bar
- Results panel with grouped counts
- Unified search (venues, drinks, deals, events, trails)
- Filter chips (Venues, Drinks, Deals, Events, Trails, Open Now)

**Architecture notes:**

- `SearchRepository` orchestrates catalog load and unified search.
- `UnifiedSearchService` queries Firestore collections aligned with mobile `SearchService`.
- Results are venue-centric: drink/deal/event/trail matches resolve to venue cards with match lines.
- Map always shows one marker per venue.

**Links out:**

| Destination | Trigger |
|---|---|
| Venue Details | Venue card / marker selection |
| Trail Details | Trail match or trail chip |
| Event Details | Event match |

---

### Venue Details

**Route (planned):** `/venue/:id`

**Purpose:** Complete desktop venue experience — the web equivalent of mobile venue detail.

**Contains:**

- Hero (banner, logo, name, location, open status)
- Drinks
- Deals
- Events
- Gallery
- Information (hours, contact, features)
- Directions (map / external navigation)

**Data:** Reuse `venues` Firestore documents and mobile venue detail models where practical.

**Links out:** Search, related Events, related Trails.

---

### Event Details

**Route (planned):** `/event/:id`

**Purpose:** Dedicated page for a single event.

**Contains:**

- Banner
- Host venue
- Date & time
- Description
- Related events

**Data:** `events` collection; link to parent venue.

**Links out:** Venue Details, Search.

---

### Trail Details

**Route (planned):** `/trail/:id`

**Purpose:** Desktop Tonight's Trail experience.

**Contains:**

- Interactive route
- Stop venues (ordered)
- Map
- Estimated walking time
- Drinks & deals along the route

**Data:** `trails` collection with `stops[]`; reuse mobile trail models.

**Links out:** Venue Details (per stop), Search.

---

### Cities

**Route (planned):** `/cities`, `/cities/:slug`  
**Examples:** London, Manchester, Liverpool, Birmingham

**Purpose:** SEO and location-based discovery.

**Contains:**

- City hero & copy
- Featured venues, deals, events
- CTA into Search pre-filtered by city/area

**Links out:** Search (with city/area context).

---

### Deals

**Route (planned):** `/deals`

**Purpose:** Browse active offers across the platform.

**Grouped by:**

- City
- Drink
- Venue

**Data:** `deals` collection (`isActive`, `isDeleted` filters per mobile).

**Links out:** Venue Details, Search.

---

### Download App

**Route (planned):** `/download`

**Purpose:** Explain mobile app advantages and drive installs.

**Contains:**

- App benefits
- Apple App Store link
- Google Play link
- QR code

**Links out:** Home, Search (optional).

---

## Business

Business pages connect independently from the consumer discovery funnel but share branding and Firestore ownership models.

### Business Landing

**Route (planned):** `/business`

**Purpose:** Explain Vexda for venue owners and operators.

**Sections:**

- Grow your venue
- Reach more customers
- Increase discoverability
- Subscription overview

**Primary CTA:** Claim Your Venue

**Links out:** Pricing, Claim Your Venue, Contact Sales.

---

### Pricing

**Route (planned):** `/business/pricing`

**Purpose:** Subscription tier comparison.

**Tiers:**

| Tier | Audience |
|---|---|
| Starter | Small venues getting started |
| Professional | Active venues needing full tools |
| Premium | High-traffic venues |
| Corporate | Multi-venue groups |

**Links out:** Claim Your Venue, Contact Sales.

---

### Claim Your Venue

**Route (planned):** `/business/claim`

**Purpose:** Business onboarding entry point.

**Approach:** Reuse claim-flow philosophy from mobile (ownership verification, venue association).

**Links out:** Venue Onboarding, Venue Portal Login.

---

### Venue Onboarding

**Route (planned):** `/business/onboarding`

**Purpose:** Guide new businesses through setup (profile, drinks, deals, gallery, publish).

**Links out:** Venue Portal Dashboard.

---

### Contact Sales

**Route (planned):** `/business/contact`

**Purpose:** Corporate and enterprise enquiries.

---

## Venue Portal

Authenticated area for venue owners and managers. Remains visually and logically separate after login.

**Route prefix (planned):** `/portal`

| Page | Purpose |
|---|---|
| Login | Firebase Auth; same project as mobile |
| Dashboard | Overview, quick actions, alerts |
| Venue Selector | Multi-venue owners switch context |
| Venue Management | Edit profile, hours, location, publish state |
| Drinks | CRUD — reuse mobile drinks management patterns |
| Deals | CRUD — reuse mobile deals management patterns |
| Events | CRUD — reuse mobile events management patterns |
| Gallery | Image management |
| Team | Manager invites & roles |
| Analytics | Views, searches, engagement |
| Subscription | Plan, billing, upgrade |
| Support | Help & tickets |

**Principle:** Reuse mobile management UI and Firestore write paths wherever practical. Adapt layout for desktop, not logic.

---

## Admin

Authenticated internal area for Vexda operations.

**Route prefix (planned):** `/admin`

| Page | Purpose |
|---|---|
| Dashboard | Platform metrics |
| Venue Approvals | Review new / updated venues |
| Claims | Process ownership claims |
| Users | User management |
| Subscriptions | Billing oversight |
| Events | Moderation |
| Trails | Curation & generated trails |
| Support | Ticket queue |
| Reports | Operational reporting |

**Data & logic:** Align with mobile admin services in `nightlife_app` where they exist.

---

## Navigation Flow

### Consumer discovery funnel

```
Home
  ↓
Search / Map
  ↓
Venue Details
  ↓
Event Details  (optional branch)
  ↓
Trail Details  (optional branch)
```

### Business funnel (independent)

```
Business Landing
  ↓
Pricing  |  Claim Your Venue
  ↓
Venue Onboarding
  ↓
Venue Portal (post-login)
```

### Portal & admin (post-authentication)

```
Login → Dashboard → Feature pages
```

Portal and Admin do not share nav with the public marketing shell. Use distinct layouts with consistent Vexda branding.

---

## Routing Conventions (planned)

| Pattern | Example |
|---|---|
| Static pages | `/`, `/search`, `/deals`, `/download` |
| Entity detail | `/venue/:id`, `/event/:id`, `/trail/:id` |
| City SEO | `/cities/:slug` |
| Business | `/business`, `/business/pricing`, `/business/claim` |
| Portal | `/portal`, `/portal/venues/:id/drinks` |
| Admin | `/admin`, `/admin/venues` |

**Router location:** `lib/core/routing/app_router.dart`  
**Current routes:** `/` (Home), `/search` (Search / Map)

New routes should be added to `AppRouter` following existing naming conventions.

---

## Codebase Conventions

### Feature module layout

```
lib/features/<feature>/
├── screens/       # Route-level pages
├── widgets/       # Feature UI components
├── data/          # Repositories, services, mappers
├── models/        # Feature-specific models
└── map/           # Map-specific helpers (search only today)
```

### Shared layers

| Layer | Location | Responsibility |
|---|---|---|
| Routing | `lib/core/routing/` | Route definitions |
| Theme | `lib/core/theme/` | Colors, spacing, typography |
| Firebase | `lib/core/firebase/` | Web Firebase bootstrap |
| Map | `lib/core/map/` | Shared map markers, styles, camera |
| Shared UI | `lib/shared/components/` | Logo, tags, cross-feature widgets |

### Firestore collections (shared with mobile)

| Collection | Primary use on web |
|---|---|
| `venues` | Search, venue details, map markers |
| `drinks` | Unified search, venue details |
| `deals` | Unified search, deals browse, venue details |
| `events` | Unified search, event details, home featured |
| `trails` | Unified search, trail details, home trails |

### Search architecture (reference)

Implemented in `lib/features/search/`:

- `SearchRepository` — catalog + unified search orchestration
- `UnifiedSearchService` — multi-collection Firestore queries
- `SearchVenueMatch` — venue-centric grouped results with match lines
- `VenueSearchMatcher` — client-side venue text matching
- `SearchRanking` — exact-name-first ranking rules

Future search features (city pre-filter, deals browse) should extend this architecture, not duplicate it.

---

## Design Principles

When implementing any new page or feature:

1. **One platform** — Pages connect via clear navigation; no orphaned screens.
2. **Mobile parity** — Same data, same rules, same search philosophy; desktop adds space, not new behaviour.
3. **Reuse first** — Firestore models, mappers, and services from mobile before writing web-only logic.
4. **Venue-centric discovery** — Search results resolve to venues on the map; entity matches show on venue cards.
5. **No UI redesign in data tasks** — Visual polish is separate from architecture and data wiring.
6. **Graceful fallback** — When Firestore is unavailable, mock preview data preserves UX (search page pattern).
7. **Desktop evolution** — Wider layouts, multi-column panels, hover states — not a different brand.

---

## Implementation Status (snapshot)

| Area | Status |
|---|---|
| Home | ✅ Implemented (preview data) |
| Search / Map | ✅ Implemented (Firestore + unified search) |
| Firebase Web | ✅ Initialized |
| Venue Details | ⬜ Planned |
| Event Details | ⬜ Planned |
| Trail Details | ⬜ Planned |
| Cities | ⬜ Planned |
| Deals browse | ⬜ Planned |
| Download App | ⬜ Planned |
| Business section | ⬜ Planned |
| Venue Portal | ⬜ Planned |
| Admin | ⬜ Planned |

Update this table as pages ship. Do not remove planned sections — they define the target platform.

---

## Prompt Checklist

Before implementing any new web page or feature, confirm:

- [ ] Have you read [VEXDA_PRODUCT_PRINCIPLES.md](./VEXDA_PRODUCT_PRINCIPLES.md)?
- [ ] Which section of this document does the work belong to?
- [ ] What routes and navigation links are added or updated?
- [ ] Which Firestore collections and mobile models are reused?
- [ ] Does search/discovery follow venue-centric unified search?
- [ ] Is the change scoped to avoid unrelated UI or logic changes?
- [ ] Does desktop layout respect existing theme (`AppTheme`, `AppColors`, `AppSpacing`)?
- [ ] Are mock fallbacks needed if Firestore is unavailable?

Reference this document ID in feature prompts: **WEB-ARCHITECTURE-001**.

---

## Related Documents

| ID | Topic |
|---|---|
| WEB-PRINCIPLES-001 | [Vexda product principles](./VEXDA_PRODUCT_PRINCIPLES.md) — product authority |
| WEB-ARCHITECTURE-001 | This document — technical blueprint |
| WEB-SEARCH-013 / 013A | Firestore venue data on search map |
| WEB-SEARCH-014 | Real Firestore venue search |
| WEB-SEARCH-015 | Unified search engine |
| WEB-FIREBASE-001 / 002 | Firebase web initialization |

Add new feature IDs to this table as they are completed.
