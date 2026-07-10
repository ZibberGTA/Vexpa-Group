# Growth Engine

## Intended Responsibility

Growth, promotion, subscriptions, boosts, onboarding nudges, and campaign workflows.

## May Depend On

VexCore contracts for identity, permissions, configuration, integrations, events, data access, and observability.

## Must Not Contain

Flutter UI, Firebase SDK imports, raw payment provider wiring, raw Firestore paths, or analytics implementation details.

## VexCore Contract Rule

The growth engine must consume VexCore contracts and use events only for completed business actions.

Direct Firebase access is forbidden.
