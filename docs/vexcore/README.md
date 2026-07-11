# VexCore Foundation 1.0

> **Platform entry point:** [Master Blueprint](../master-blueprint.md) · [Documentation index](../README.md)

This documentation set records the approved VexCore package boundary, dependency rules, current Firebase access audit, identity/permission audit, duplication audit, migration inventory, risk register, and foundation roadmap.

Foundation 1.0 is structural only:

- Create `packages/vex_core` as a pure Dart contract package.
- Create `packages/vex_engines` as a placeholder for future business engines.
- Document current mobile and web architecture.
- Do not migrate feature code.
- Do not change Firebase Rules.
- Do not deploy.

## Documents

1. `01-foundation-overview.md`
2. `02-layer-boundaries.md`
3. `03-dependency-rules.md`
4. `04-current-code-audit.md`
5. `05-firebase-access-audit.md`
6. `06-identity-permissions-audit.md`
7. `07-duplication-audit.md`
8. `08-migration-inventory.md`
9. `09-risk-register.md`
10. `10-foundation-roadmap.md`

## Entitlements (subscription access)

**Locked decision:** subscription **entitlements** (what a plan allows) are owned by VexCore at `packages/vex_core/lib/entitlements/`. Engines and apps must not compare raw subscription plan name strings for feature access — they call `EntitlementService` with plan ids already loaded by billing adapters.

| Module | Purpose |
| --- | --- |
| `subscription_tier.dart` | Canonical venue tiers, consumer plans, normalisation, admin labels |
| `entitlement.dart` | Feature flags and media library limit keys |
| `entitlement_limits.dart` | Numeric limits (gallery/deal/event image caps) |
| `entitlement_service.dart` | In-memory entitlement evaluation (no network I/O) |

**Billing stays in apps:** Stripe/Firestore payment status, renewal dates, and checkout flows remain in mobile/web adapters. VexCore answers capability questions only.

**Related ownership:** Claim Engine owns claim evidence workflows. VexCore owns document storage contracts, metadata, permissions, and retrieval. VexDocs remains a future shared platform service if document management expands beyond claims.
