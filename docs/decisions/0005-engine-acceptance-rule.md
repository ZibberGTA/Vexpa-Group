# ADR-0005: Engine Acceptance Rule

## Status

Accepted — 2026-07-11

## Context

Partial migrations leave duplicate logic in apps and engines. Without a clear "done" definition, engines are declared complete prematurely and technical debt returns.

## Decision

An engine is **not considered complete** until **all** of the following are true:

1. All code specific to that business capability has **one clear home** in the engine.
2. **Web and mobile** consume the engine where required (via facades if needed).
3. Shared platform behaviour comes from **VexCore**, not duplication in the engine.
4. The engine adds **no unnecessary** network calls, listeners, or extra mapping on hot paths.
5. The engine has its **own tests** (no live Firebase in engine tests).
6. The engine has its **own documentation** (README + migration plan minimum).
7. Failures can be **traced clearly** to that engine.
8. The engine does **not** directly depend on another engine's **private** implementation.

Canonical wording also appears in each engine README under `packages/vex_engines/lib/*/README.md`.

## Consequences

### Positive

- Objective completion criteria for roadmap reporting.
- Prevents "engine folder exists therefore done" false progress.
- Protects performance during migration.

### Negative

- Higher bar delays "100% complete" labels.
- Requires delegation tests in both apps for shared engines.

## Alternatives considered

| Alternative | Why rejected |
| --- | --- |
| Code coverage threshold only | Does not capture duplication or network discipline |
| Web-only completion | Mobile is co-equal launch surface |
| No acceptance rule | Repeated partial migrations (observed in audits) |

## Future review

Amend if engines deploy as independent services (add operational readiness criteria).

**References:** [master-blueprint.md §13 #005](../master-blueprint.md), [packages/vex_engines/README.md](../../packages/vex_engines/README.md)
