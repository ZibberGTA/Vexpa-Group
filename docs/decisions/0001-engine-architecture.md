# ADR-0001: Engine Architecture

## Status

Accepted — 2026-07-11

## Context

Vexda's mobile and web applications grew with duplicated business logic — search matching, deal visibility, claim validation, analytics aggregation — implemented separately in each app. Firebase and Firestore paths were scattered across features. There was no clear ownership boundary for business capability versus infrastructure.

The platform must support multiple surfaces (mobile, web portals, future distribution platform) and eventually dozens of engineers without logic fragmentation.

## Decision

Adopt a **Vex Engines** architecture:

1. Each **business capability** is owned by one **engine** in `packages/vex_engines/lib/<engine>/`.
2. Engines are organised in layers: `domain/`, `application/`, `data/`, `shared/`, `presentation/` (phased).
3. Engines **consume VexCore contracts** for authentication, identity, permissions, data access, storage, events, integrations, configuration, and observability.
4. Engines **must not** import Firebase SDKs, Flutter UI (in domain/application/data), or another engine's private persistence.
5. **App shells** (`nightlife_app`, `nightlife_web`) own Firebase adapters, routing, widgets, and thin **compatibility facades** that delegate to engines.
6. Business logic lives in engines; infrastructure lives in VexCore; presentation lives in apps.

Dependency direction:

```text
Presentation → Engine → VexCore contracts → Adapters → Firebase
```

## Consequences

### Positive

- Single home for each business rule; web/mobile parity through shared engines.
- Teams can own engines independently.
- Backend migration possible without rewriting business rules.
- Failures trace to a named engine.

### Negative

- Migration cost from legacy inline logic to engines.
- Requires discipline to avoid "just one Firebase call" in engines.
- Temporary duplication during phased migration (facades + old paths).

## Alternatives considered

| Alternative | Why rejected |
| --- | --- |
| Shared `lib/` copied between apps | Duplication guaranteed; no test boundary |
| One monolithic `business_logic` package | Becomes god object; no team ownership |
| Firebase-only with no engine layer | Blocks migration; logic stays duplicated in apps |
| Microservices per engine at launch | Operational overhead disproportionate for current scale |

## Future review

Revisit when: (a) first engine needs independent deployment, (b) team exceeds ~15 engineers, or (c) a new surface (Distribution) requires different runtime constraints.

**References:** [master-blueprint.md §4–5](../master-blueprint.md), [03-dependency-rules.md](../vexcore/03-dependency-rules.md), [packages/vex_engines/README.md](../../packages/vex_engines/README.md)
