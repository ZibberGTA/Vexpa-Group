# ADR-0004: Firebase Launch Strategy

## Status

Accepted — 2026-07-11

## Context

Vexda already runs on Firebase (Auth, Firestore, Storage, Functions, Hosting) in both mobile and web apps. A rewrite at launch is not feasible. At the same time, business logic must not become permanently coupled to Firebase APIs.

## Decision

1. **Firebase is the launch backend** for Auth, Firestore, Storage, Cloud Functions, and web Hosting.
2. **Firebase SDK usage is confined to app adapter layers** and future VexCore infrastructure adapters — never in engine domain/application/data layers.
3. **Canonical security rules** live in `apps/nightlife_app/firestore.rules` and `storage.rules`; web references them for deploy.
4. **Cloud Functions** remain the integration point for privileged operations (e.g. claim submission callables).
5. **No new production Firebase integrations** during pure Foundation documentation phases without explicit review.
6. Engine migrations must **not add** Firestore reads, listeners, or queries — only reorganise existing call paths.

## Consequences

### Positive

- Leverages existing investment and team familiarity.
- Rapid iteration for launch.
- Clear rule: adapters only.

### Negative

- Firestore query limitations affect search architecture until VexCore discovery repos mature.
- Public document field exposure risks require rules and DTO discipline.
- Vendor concentration until migration option is exercised.

## Alternatives considered

| Alternative | Why rejected |
| --- | --- |
| PostgreSQL from day one | Delays launch; reimplements working Firebase flows |
| Supabase/other BaaS | Migration cost with no immediate product gain |
| Firebase inside engines | Blocks engine acceptance rule and DB migration |

## Future review

Trigger review when: monthly Firestore cost exceeds budget threshold, analytical queries exceed Firestore suitability, or PostgreSQL pilot begins ([ADR-0006](./0006-database-strategy.md)).

**References:** [05-firebase-access-audit.md](../vexcore/05-firebase-access-audit.md), [README.md Firebase section](../../README.md)
