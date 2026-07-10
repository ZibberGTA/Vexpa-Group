# Trail Engine

## Intended Responsibility

Trail composition, trail publishing, route metadata, and trail discovery business workflows.

## May Depend On

VexCore contracts for data access, identity, permissions, events, integrations, and observability.

## Must Not Contain

Flutter screens, map widgets, Firebase SDK imports, raw Firestore paths, or venue-management storage details.

## VexCore Contract Rule

The trail engine must consume VexCore contracts for all infrastructure concerns.

Direct Firebase access is forbidden.
