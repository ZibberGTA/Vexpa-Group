# Analytics Engine

## Intended Responsibility

Venue, content, subscription, and product analytics workflows using aggregated or anonymised data where appropriate.

## May Depend On

VexCore contracts for data access, events, integrations, configuration, and observability.

## Must Not Contain

Flutter UI, Firebase SDK imports, raw analytics collection paths, or confidential per-venue data exposure across tenants.

## VexCore Contract Rule

The analytics engine must consume VexCore contracts and respect tenant isolation.

Direct Firebase access is forbidden.
