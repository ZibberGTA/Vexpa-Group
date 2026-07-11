# Intelligence Engine

## Overview

Recommendation, ranking, insight, and decision-support workflows built from **appropriate anonymised or aggregated data** — beyond Version 1 trending/recommendation scorers in Discovery and Analytics.

## Purpose

Provide deeper insight and decision support without exposing confidential tenant data or duplicating Analytics aggregation.

## Responsibilities

(planned)

- Advanced ranking models using aggregated signals
- Market-level insights (anonymised)
- Decision-support outputs for venue owners and Vexda operations
- Explicit separation from raw tenant identifiable joins

## Version

**Version 2** — not Version 1.

## Dependencies

- VexCore: aggregated data contracts, approved integrations, observability
- Analytics Engine: aggregated metrics outputs — not raw event stores
- Discovery Engine: may consume intelligence **scores** as inputs — via public interfaces only

## Uses VexCore Layers

| Layer | Usage (planned) |
| --- | --- |
| Vex Data Engine | Aggregated/anonymised read contracts |
| Integrations | Optional external ML services |
| Observability | Model versioning and audit |

## Owns

(planned) Intelligence models, insight DTOs, ranking enhancement rules.

## Consumes

(planned) Anonymised aggregates from Analytics adapters; never another engine's private persistence.

## Provides

(planned) Insight APIs for portal dashboards and optional Discovery ranking inputs.

## Current Status

**Placeholder** — README at `packages/vex_engines/lib/intelligence/`. Version 1 uses Discovery trending/recommendation scorers and Analytics engagement calculations.

## Future Features

- Market intelligence (listed as future-only in Analytics README)
- Predictive analytics with privacy review
- AI insights with tenant confidentiality guarantees

## Technical Notes

- Intelligence must preserve tenant confidentiality ([03-dependency-rules.md](../vexcore/03-dependency-rules.md)).
- Direct Firebase access forbidden.

## Known Risks

- Analytics/intelligence privacy violations if identifiable data joined ([09-risk-register.md](../vexcore/09-risk-register.md)).
- Overlap with Discovery scorers during migration — boundaries must stay explicit.

## Outstanding Work

- Privacy model ADR before implementation
- Define aggregate input contracts from Analytics
- Package structure beyond README placeholder

**Deep dive:** [packages/vex_engines/lib/intelligence/README.md](../../packages/vex_engines/lib/intelligence/README.md)
