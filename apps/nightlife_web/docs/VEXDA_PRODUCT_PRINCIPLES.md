# Vexda Product Principles

**Document ID:** WEB-PRINCIPLES-001  
**Status:** Product Authority  
**Project:** Vexda Web Platform (`nightlife_web`)

---

## Purpose

This document defines the philosophy behind every page of the Vexda platform.

It is not a coding document. It is the **product authority**.

Every future Epic should reference this document before implementation.

If a design decision conflicts with these principles, **these principles take precedence**.

---

## How to use this document

Before starting any Epic, read:

1. [VEXDA_PRODUCT_PRINCIPLES.md](./VEXDA_PRODUCT_PRINCIPLES.md) — *this document*
2. [WEB_ARCHITECTURE.md](./WEB_ARCHITECTURE.md) — technical blueprint and sitemap

Only then should implementation begin.

Reference this document ID in feature prompts: **WEB-PRINCIPLES-001**.

---

# Principle 1 — Every page sells Vexda

Even when viewing a venue, event, or trail, the page is still communicating **why Vexda exists**.

The platform should never feel like a static directory.

It should continuously encourage discovery.

---

# Principle 2 — Every page answers one question

| Page | Question |
|---|---|
| **Home** | What is Vexda? |
| **Search** | Where should I go tonight? |
| **Venue** | Why should I visit this venue? |
| **Event** | Should I attend this event? |
| **Trail** | Is this the perfect night out? |
| **Business** | Why should my venue join Vexda? |
| **Pricing** | Which subscription is right for me? |

Every page must answer its question **within seconds**.

---

# Principle 3 — Every page has one primary conversion

| Page | Primary conversion |
|---|---|
| **Home** | Search |
| **Search** | Open a venue |
| **Venue** | Get directions · Save venue · Download the app |
| **Business** | Claim your venue |
| **Pricing** | Subscribe |

The page should guide users naturally towards its primary action.

Secondary actions are permitted, but the primary conversion must remain obvious.

---

# Principle 4 — Premium is mandatory

Nothing should feel ordinary.

**Avoid:**

- Default Material layouts
- Generic spacing
- Unnecessary boxes

**Prefer:**

- Large imagery
- Glassmorphism
- Subtle gradients
- Layered depth
- Premium typography
- Intentional whitespace
- Soft hover animations
- Premium loading states
- Elegant transitions

Every interaction should feel **considered**.

---

# Principle 5 — Reuse before rebuilding

Reuse:

- Firestore models
- Business logic
- Search behaviour
- Animations
- Theme
- Components

Desktop should **extend** the mobile experience rather than replace it.

Do not invent a different product.

---

# Principle 6 — Discovery first

The platform exists to help users discover nightlife.

Every page should encourage exploration.

**Examples:**

- Nearby venues
- Similar drinks
- Related events
- Tonight's Trails
- Continue your night

Users should rarely reach a dead end.

When data is unavailable, provide architecture and copy that still invites the next step — never a blank wall.

---

# Principle 7 — Business value is always visible

Venue owners should immediately understand:

- How Vexda increases discoverability
- How Vexda increases customer reach
- How Vexda helps them grow

The philosophy remains:

**Venue Experience Discovery Advertising.**

Grow your venue — not simply manage your venue.

---

# Principle 8 — Performance equals trust

Pages should feel fast.

- Skeleton loaders
- Smooth scrolling
- Lazy loading
- Minimal layout shift
- Optimised images
- Consistent responsiveness

Fast software feels like premium software.

Slow software erodes trust — regardless of visual design.

---

# Principle 9 — Consistency over creativity

Do not redesign existing successful components.

Improve them. Extend them. Refine them.

The entire platform should feel like **one product**.

Local creativity is welcome when it strengthens the whole — not when it fragments it.

---

# Principle 10 — Build pages investors would want to demo

Every completed page should be capable of being shown to:

- Investors
- Venue owners
- Partners
- The public

**Without apology.**

Every completed page should feel launch-ready.

If a page would embarrass you in a demo, it is not done.

---

## Conflict resolution

When implementation choices diverge:

1. **Product principles** (this document) — highest authority
2. **Architecture blueprint** ([WEB_ARCHITECTURE.md](./WEB_ARCHITECTURE.md))
3. **Epic-specific requirements**
4. **Implementation convenience** — lowest authority

---

## Related documents

| ID | Document | Role |
|---|---|---|
| WEB-PRINCIPLES-001 | VEXDA_PRODUCT_PRINCIPLES.md | Product philosophy and decision authority |
| WEB-ARCHITECTURE-001 | WEB_ARCHITECTURE.md | Sitemap, routing, technical blueprint |

Add new principle-driven feature IDs to Epic prompts as they are completed.
