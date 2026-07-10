# Dependency Rules

## Allowed Direction

```text
Presentation
    ↓
Application or Engine
    ↓
VexCore contracts
    ↓
VexCore infrastructure adapters
    ↓
Firebase and external services
```

Dependencies must flow downward. Higher layers may depend on lower contracts. Lower layers must not import application screens, widgets, or feature workflows.

## Prohibited Patterns

- UI directly using Firebase.
- Engines directly using Firebase.
- Hard-coded role checks inside widgets.
- One engine directly reading another engine's internal persistence.
- Firebase document paths scattered across applications.
- Duplicated identity resolution in mobile and web.
- Importing Firebase packages into pure VexCore domain folders.
- Using the event bus as a replacement for normal request-response calls.
- Exposing another venue's confidential data.
- Future intelligence workflows using identifiable tenant data where anonymised or aggregated data is appropriate.

## Firebase Boundary

Pure VexCore contracts must not import:

- `firebase_auth`
- `cloud_firestore`
- `firebase_storage`
- `cloud_functions`
- `firebase_messaging`
- `firebase_analytics`
- `firebase_remote_config`
- `firebase_crashlytics`
- `firebase_performance`
- `firebase_app_check`

Firebase imports belong only in future infrastructure adapter packages or adapter folders.

## Engine Boundary

Engines may depend on VexCore contracts and shared engine-neutral primitives. Engines must not contain Flutter UI, direct Firebase access, raw document paths, or another engine's private persistence model.

## Event Boundary

Commands and queries needing immediate responses should call services or repositories. Events are for completed business actions and eventual reaction, not for reads, access checks, or synchronous command outcomes.
