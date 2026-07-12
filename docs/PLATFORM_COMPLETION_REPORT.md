# Vexda Version 1 Modular Platform Architecture — Complete

**Completion date:** 2026-07-12  
**Branch context:** `feature/vexcore-identity-foundation`  
**Authority:** This report summarises locked architecture and remaining adoption work. Detailed product and engine documentation lives in linked sources — it does not replace the [Master Blueprint](./master-blueprint.md).

---

## 1. Locked architecture

Version 1 business logic is organised in a single call direction:

```text
Apps (mobile + web UI shells)
  → Business Engines (packages/vex_engines)
    → VexCore (packages/vex_core contracts)
      → Infrastructure adapters (Firebase, Stripe, storage, auth)
        → Firebase / Stripe / Cloud Functions
```

- **Apps** own routing, theming, widgets, and Firebase/Stripe adapter implementations.
- **Engines** own venue-scoped business rules for their capability.
- **VexCore** owns shared infrastructure contracts — not business rules.
- **Adapters** translate between VexCore interfaces and concrete infrastructure.

See [ADR-0001: Business Logic Ownership](./decisions/0001-engine-architecture.md) and [ADR-0003: VexCore Layers](./decisions/0003-vexcore-layers.md).

---

## 2. VexCore Foundation 1.0 lock status

**Status: Locked (2026-07-11)**

The public contract surface in `packages/vex_core` is frozen for Version 1. Breaking changes require an ADR and explicit founder approval. Backward-compatible additions remain allowed.

Full lock scope and adoption backlog: [11-foundation-lock.md](./vexcore/11-foundation-lock.md).

---

## 3. Engine status (Version 1 scope)

| Engine | Completion | Summary |
| --- | --- | --- |
| **Venue** | ~85% | Profile, validation, admin CRM health scoring complete; media/public view adoption and broader management orchestration remain |
| **Discovery** | ~92% | Unified search orchestration complete; presentation layer and optional VexCore adapter contracts remain |
| **Experience** | ~100% | Version 1 business rules and presentation-rule consolidation complete |
| **Analytics** | ~90% | Dashboard calculations and web/mobile aggregation wired; optional VexCore analytics read service not yet piloted |
| **Claim** | ~92% | Web search/review wired; mobile claim UI planned |
| **Growth** | ~92% | Implemented commercial-rule scope wired to web dashboard; checkout/Firestore billing adapters remain in apps |

**Experience Engine detail:** Version 1 business rules (visibility, scheduling, validation, featured limits, owner writes, import validation, admin content summaries) and presentation rules (tags, highlights, relative time, drink grouping, public venue presentation) are complete. Remaining optional work: engine-owned write repository interfaces in `data/` and removal of deprecated VexCore compatibility/parity paths. Version 2 content kinds and infrastructure are **not** complete.

Per-engine documentation:

- [Experience Engine](./engines/experience.md) · [README](../packages/vex_engines/lib/experience/README.md) · [Migration plan](../packages/vex_engines/lib/experience/MIGRATION_PLAN.md)
- [Venue Engine](./engines/venue.md) · [Discovery Engine](./engines/discovery.md) · [Analytics Engine](./engines/analytics.md) · [Claim Engine](./engines/claim.md) · [Growth Engine](./engines/growth.md)

---

## 4. What is permanently frozen

| Area | Rule |
| --- | --- |
| **VexCore contracts** | Breaking changes require ADR + founder approval |
| **Call direction** | Apps → Engines → VexCore → adapters → infrastructure |
| **Version 1 engine set** | Venue, Discovery, Experience, Claim, Analytics (Growth at 1.5 scope) |
| **Data ownership** | One Firestore model; engines own rules, adapters own I/O |
| **Tenant isolation** | No engine may expose another venue's confidential information |
| **Cross-venue insights** | Must be aggregated and anonymised |
| **Firebase/Stripe code** | Stays in app adapters — not in engine domain/application layers |

---

## 5. What remains (adoption, adapter, UI, testing, launch)

This work does **not** require architecture redesign:

- **Venue:** Media/public view adoption; broader management repository writes through engine contracts
- **Discovery:** Presentation layer; mobile/web search path convergence
- **Experience:** Optional VexCore visibility parity delegation; engine write repository interfaces
- **Claim:** Mobile claim flow; write repository contracts; storage rules emulator validation
- **Analytics:** VexCore analytics read service pilot
- **Growth:** Checkout/Firestore billing adapter consolidation; analytics tab mock replacement where applicable
- **Platform:** Web route completion, duplication elimination, launch QA, product UI polish

Detail: [Master Blueprint §14 Outstanding Work](./master-blueprint.md#14-outstanding-work) and [10-foundation-roadmap.md](./vexcore/10-foundation-roadmap.md).

---

## 6. Explicitly deferred work

The following are **out of scope** for Version 1 architecture completion and must not be claimed as done:

- Event Bus broader adoption beyond current contracts
- Mobile claim UI
- Trail Engine migration (trail product data exists; engine rules do not)
- Crowd intelligence extraction
- Future billing/campaign infrastructure (full Stripe checkout pipelines, campaign orchestration, performance analytics backends)
- Optional engine write repository contracts (planned, not blocking V1 architecture)
- Version 2+ engines: Intelligence, Messaging, Membership, Booking, Ticketing, Ordering, POS, Distribution

See [ADR-0002: Version 1 Scope](./decisions/0002-version-1-scope.md).

---

## 7. Governance

| Rule | Detail |
| --- | --- |
| **VexCore changes** | Breaking changes require an ADR and founder approval |
| **Business rules** | New rules belong in the responsible engine — not in apps or VexCore |
| **Infrastructure** | Firebase, Firestore, Storage, Stripe, and Cloud Functions code stays in adapters |
| **Confidentiality** | No engine may expose another venue's confidential information |
| **Cross-venue data** | Insights must be aggregated and anonymised |
| **Documentation** | Major architectural decisions update the Master Blueprint or an ADR ([ADR-0009](./decisions/0009-documentation-policy.md)) |

---

## 8. Declaration

**The Version 1 modular platform architecture is complete.**

All five launch engines have clear homes for their Version 1 business rules. Mobile and web surfaces delegate to engines through thin adapters. VexCore Foundation 1.0 is locked. Remaining work is adoption, adapter consolidation, product UI, testing, and launch preparation — not a redesign of engine boundaries or call direction.

**Primary development now returns to product and UI work** within the locked architecture. New migrations should be scoped as adoption or feature delivery, not as foundational restructuring.

---

## Related links

- [Master Blueprint](./master-blueprint.md)
- [VexCore Foundation](./vexcore/README.md)
- [VexCore Foundation 1.0 Lock](./vexcore/11-foundation-lock.md)
- [Engine Catalogue](./engines/README.md)
- [Architecture Decisions](./decisions/README.md)
