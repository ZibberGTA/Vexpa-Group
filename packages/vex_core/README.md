# VexCore

VexCore is the shared infrastructure contract layer for Vexda applications and future business engines.

Foundation 1.0 intentionally contains only Firebase-free contracts, value objects, enums, result wrappers, and barrel exports. Firebase adapters and feature migrations will be added in later phases after the current mobile and web access patterns have been validated.

## Rules

- VexCore contracts must not import Flutter UI or Firebase packages.
- Engines consume VexCore contracts instead of Firebase implementations.
- UI screens and feature-specific workflows stay outside VexCore.
- Firebase adapters will live behind these contracts in a later infrastructure layer.
