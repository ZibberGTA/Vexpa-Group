# Messaging Engine

## Overview

Future engine for **in-app and platform messaging** between users, venues, artists, and support. Not part of Version 1 launch scope.

## Purpose

Centralise messaging business rules (threads, eligibility, notifications handoff) when product prioritises communication features.

## Responsibilities

(planned)

- Conversation and thread models
- Message send eligibility and permission rules
- Notification preparation (delivery via VexCore integrations)
- Support queue message semantics

## Version

**Version 3** — **NOT Version 1**.

## Dependencies

- VexCore: authentication, identity, permissions, events, integrations, observability
- Messaging must not bypass VexCore for identity or storage contracts

## Uses VexCore Layers

| Layer | Usage (planned) |
| --- | --- |
| Identity & permissions | Participant eligibility |
| Integrations | Push/email notification adapters |
| Events | Message sent, thread created |

## Owns

(planned) Messaging domain rules and orchestration.

## Consumes

(planned) User and venue identity context; notification channels via adapters.

## Provides

(planned) Messaging services for mobile, web portal, and artist surfaces.

## Current Status

**Not implemented.** Mobile contains chat-related services (`chat_service.dart`) and artist dashboard references to Messages — **precursor only**, not engine-backed.

## Future Features

- Consumer ↔ venue messaging
- Artist messaging
- Support-integrated threads

## Technical Notes

- No package folder yet — create under `packages/vex_engines/lib/messaging/` when Version 3 begins.
- Firebase/other realtime transport stays in adapters.

## Known Risks

- Implementing messaging in app shells without engine — would duplicate mobile/web logic.

## Outstanding Work

- Product ADR for messaging scope and moderation
- Engine folder creation and migration inventory from `chat_service.dart`

**References:** [ADR-0002 Version 1 Scope](../decisions/0002-version-1-scope.md)
