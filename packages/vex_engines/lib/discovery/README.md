# Discovery Engine

## Intended Responsibility

Public and personalized venue, event, deal, drink, and trail discovery workflows.

## May Depend On

VexCore contracts, shared engine-neutral value objects, and anonymised or aggregated intelligence outputs.

## Must Not Contain

Flutter UI, Firebase SDK imports, raw Firestore document paths, private venue-management workflows, or direct reads of another engine's internal persistence.

## VexCore Contract Rule

The discovery engine must consume VexCore contracts for authentication context, identity, permissions, data access, storage, configuration, events, and observability.

Direct Firebase access is forbidden.
