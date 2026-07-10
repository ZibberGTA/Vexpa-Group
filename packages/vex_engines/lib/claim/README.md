# Claim Engine

## Intended Responsibility

Venue claim submission, review coordination, ownership assignment, and claim audit workflows.

## May Depend On

VexCore contracts for identity, permissions, data access, events, integrations, and audit.

## Must Not Contain

Flutter UI, Firebase SDK imports, raw callable-function wiring, hard-coded admin role checks, or public discovery presentation logic.

## VexCore Contract Rule

The claim engine must consume VexCore contracts and publish events only after completed business actions.

Direct Firebase access is forbidden.
