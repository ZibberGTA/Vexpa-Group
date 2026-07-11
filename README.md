# Vexda Monorepo

Single version-controlled workspace for Vexda mobile, web, shared packages, and architecture documentation.

## Layout

```text
vexda/
├── apps/
│   ├── nightlife_app/     # Flutter mobile application
│   └── nightlife_web/     # Flutter web application
├── packages/
│   ├── vex_core/          # Shared infrastructure contracts (VexCore)
│   └── vex_engines/       # Future business engine placeholders
└── docs/
    ├── master-blueprint.md   # CEO handbook — start here for platform overview
    ├── engines/              # Engine catalogue (one page per engine)
    ├── decisions/            # Architecture Decision Records (ADRs)
    └── vexcore/              # VexCore Foundation documentation
```

## Run the mobile app

```bash
cd apps/nightlife_app
flutter pub get
flutter run
```

## Run the web app

```bash
cd apps/nightlife_web
flutter pub get
flutter run -d chrome
```

## Build private-development web release

```bash
cd apps/nightlife_web
flutter build web --release --dart-define=PRIVATE_DEVELOPMENT_MODE=true
```

## Firebase configuration

| Concern | Location |
| --- | --- |
| Firestore rules (canonical) | `apps/nightlife_app/firestore.rules` |
| Storage rules (canonical) | `apps/nightlife_app/storage.rules` |
| Cloud Functions | `apps/nightlife_app/functions/` |
| Web Hosting config | `apps/nightlife_web/firebase.json` |
| Mobile Firebase config | `apps/nightlife_app/firebase.json` |

Web hosting deploys from `apps/nightlife_web`. That project's `firebase.json` references mobile rules via `../nightlife_app/firestore.rules` and `../nightlife_app/storage.rules` (sibling paths under `apps/`).

### Deploy hosting (from web app)

```bash
cd apps/nightlife_web
flutter build web --release --dart-define=PRIVATE_DEVELOPMENT_MODE=true
firebase deploy --only hosting
```

### Deploy Firestore and Storage rules

From web (rules resolve to mobile canonical files):

```bash
cd apps/nightlife_web
firebase deploy --only firestore:rules,storage
```

Or from mobile:

```bash
cd apps/nightlife_app
firebase deploy --only firestore:rules,storage
```

## Shared package paths

Applications depend on VexCore via:

```yaml
vex_core:
  path: ../../packages/vex_core
```

## Documentation

| Start here | Path |
| --- | --- |
| Master Blueprint (CEO handbook) | [docs/master-blueprint.md](docs/master-blueprint.md) |
| Documentation index | [docs/README.md](docs/README.md) |
| Engine catalogue | [docs/engines/README.md](docs/engines/README.md) |
| Architecture decisions (ADRs) | [docs/decisions/README.md](docs/decisions/README.md) |
| VexCore foundation | [docs/vexcore/README.md](docs/vexcore/README.md) |
| Web product principles | [apps/nightlife_web/docs/VEXDA_PRODUCT_PRINCIPLES.md](apps/nightlife_web/docs/VEXDA_PRODUCT_PRINCIPLES.md) |

## Validation

```bash
cd packages/vex_core && dart pub get && dart analyze && dart test
cd packages/vex_engines && dart pub get && dart analyze && dart test
cd apps/nightlife_app && flutter pub get && flutter analyze
cd apps/nightlife_web && flutter pub get && flutter analyze
```

## Git history note

The pre-monorepo `nightlife_app` Git metadata is preserved under `.backup/` (see `docs/vexcore/00-workspace-structure.md`). This repository was initialised fresh at the workspace root to avoid risky history rewriting while uncommitted mobile work existed in the source tree.
