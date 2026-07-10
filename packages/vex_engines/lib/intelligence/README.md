# Intelligence Engine

## Intended Responsibility

Recommendation, ranking, insight, and decision-support workflows built from appropriate anonymised or aggregated data.

## May Depend On

VexCore contracts, aggregated analytics outputs, and explicitly approved integrations.

## Must Not Contain

Flutter UI, Firebase SDK imports, raw tenant data exposure, direct reads of another engine's private persistence, or confidential venue data leakage.

## VexCore Contract Rule

The intelligence engine must consume VexCore contracts and preserve tenant confidentiality.

Direct Firebase access is forbidden.
