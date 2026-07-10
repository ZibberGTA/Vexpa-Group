# Vex Engines

Vex Engines contains Vexda business capability modules such as discovery,
claims, trails, analytics, growth, intelligence, and **venue**.

Foundation 1.0 creates package boundaries and engine folder structures. Final
engine APIs and Firebase adapters are introduced incrementally via migration
plans in each engine folder.

Engines may depend on VexCore contracts. Engines must not depend directly on
Firebase SDKs, Flutter UI, or another engine's private persistence model.

## Engines

| Engine | Path | Status |
| --- | --- | --- |
| Venue | `lib/venue/` | Structure + migration plan |
| Discovery | `lib/discovery/` | README boundary only |
| Claim | `lib/claim/` | README boundary only |
| Trail | `lib/trail/` | README boundary only |
| Analytics | `lib/analytics/` | README boundary only |
| Growth | `lib/growth/` | README boundary only |
| Intelligence | `lib/intelligence/` | README boundary only |
