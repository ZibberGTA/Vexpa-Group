# Architecture Decision Records (ADRs)

Locked decisions for Vexda. Read relevant ADRs **before** changing engine boundaries, VexCore contracts, version scope, database strategy, or portal architecture.

## Index

| ADR | Title | Status |
| --- | --- | --- |
| [0001](./0001-engine-architecture.md) | Engine Architecture | Accepted |
| [0002](./0002-version-1-scope.md) | Version 1 Scope | Accepted |
| [0003](./0003-vexcore-layers.md) | VexCore Layers | Accepted |
| [0004](./0004-firebase-launch-strategy.md) | Firebase Launch Strategy | Accepted |
| [0005](./0005-engine-acceptance-rule.md) | Engine Acceptance Rule | Accepted |
| [0006](./0006-database-strategy.md) | Database Strategy | Accepted |
| [0007](./0007-admin-portal.md) | Admin Portal Architecture | Accepted |
| [0008](./0008-distribution-platform.md) | Distribution Platform Strategy | Accepted |
| [0009](./0009-documentation-policy.md) | Documentation Policy | Accepted |

## How to add a decision

1. Copy the nearest existing ADR as a template.
2. Assign the next sequential number (`0010-…`).
3. Set status to **Proposed** until reviewed.
4. Link from [master-blueprint.md](../master-blueprint.md) §13 Locked Decisions.
5. Update affected engine docs if engine boundaries change.

## ADR format

Each record includes:

- **Status** — Proposed | Accepted | Superseded | Deprecated
- **Context** — forces and constraints
- **Decision** — what was chosen
- **Consequences** — positive and negative outcomes
- **Alternatives considered** — options rejected and why
