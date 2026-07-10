# Vex Engines

Vex Engines contains Vexda business capability modules such as discovery,
claims, trails, analytics, growth, intelligence, and **venue**.

Foundation 1.0 creates package boundaries and engine folder structures. Final
engine APIs and Firebase adapters are introduced incrementally via migration
plans in each engine folder.

Engines may depend on VexCore contracts. Engines must not depend directly on
Firebase SDKs, Flutter UI, or another engine's private persistence model.

## Engine Acceptance Rule

An engine is not considered complete until all capability-specific code has one
clear home, web and mobile can consume it where required, shared platform
behaviour comes from VexCore, the engine adds no unnecessary network calls or
listeners, it has its own tests and documentation, failures trace clearly to it,
and it does not depend on another engine's private implementation. See the Venue
Engine README for the canonical wording. `docs/master-blueprint.md` is not yet
created.

## Engines

| Engine | Path | Status |
| --- | --- | --- |
| Venue | `lib/venue/` | Phases 0–2 complete (helpers + domain rules) |
| Discovery | `lib/discovery/` | README boundary only |
| Claim | `lib/claim/` | README boundary only |
| Trail | `lib/trail/` | README boundary only |
| Analytics | `lib/analytics/` | README boundary only |
| Growth | `lib/growth/` | README boundary only |
| Intelligence | `lib/intelligence/` | README boundary only |
