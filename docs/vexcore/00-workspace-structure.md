# Workspace Structure

## Why the monorepo exists

Vexda previously lived as sibling folders under `C:\Users\Zibbe` with only `nightlife_app` under Git. Shared packages (`vex_core`, `vex_engines`) and `docs/vexcore` were outside version control, which blocked safe CI, collaboration, and VexCore runtime migrations.

Foundation Phase 0 created the shared structure. This monorepo consolidates applications, packages, and documentation under one Git repository at `vexda/`.

## Directory layout

```text
vexda/
├── apps/                 # Flutter applications (UI + app-specific wiring)
│   ├── nightlife_app/
│   └── nightlife_web/
├── packages/             # Shared Dart packages
│   ├── vex_core/         # Infrastructure contracts
│   └── vex_engines/      # Future business engines
├── docs/
│   └── vexcore/          # Architecture and migration documentation
├── .backup/              # Pre-monorepo Git backups (not for runtime use)
├── README.md
└── .gitignore
```

## Dependency direction

```text
apps (UI, routing, platform)
    ↓
packages/vex_engines (future business capabilities)
    ↓
packages/vex_core (contracts and shared primitives)
```

Applications may depend on `vex_core` via path dependency. They must not depend on Firebase implementations inside `vex_core` contract folders.

## Package path rules

From an application under `apps/<app_name>/`:

```yaml
vex_core:
  path: ../../packages/vex_core
```

`vex_engines` is not an application dependency during Foundation 1.0.

Packages under `packages/` must not import application code.

## Git ownership

- **Repository root:** `C:\Users\Zibbe\vexda\.git`
- **No nested repositories** under `apps/` or `packages/`
- **No Git submodules** in this phase
- **Parent directory** `C:\Users\Zibbe` is not a Git repository

### History preservation

The original `nightlife_app` repository had uncommitted working-tree changes at consolidation time. Destructive history rewriting was not performed.

Backups created before consolidation:

| Artifact | Purpose |
| --- | --- |
| `.backup/nightlife_app-dotgit/` | Full copy of original `.git` directory |
| `.backup/nightlife_app.bundle` | `git bundle` of all refs from original repo |

**Approach used:** fresh `git init` at `vexda/` including the full working tree (committed + uncommitted files copied from disk).

**Optional future history graft** (manual, not applied automatically):

1. `git clone .backup/nightlife_app.bundle nightlife_app-legacy`
2. Use `git subtree` or filter-repo to place `apps/nightlife_app` history into the monorepo
3. Verify no duplicate nested `.git` remains

## Where code belongs

| Kind of code | Location |
| --- | --- |
| Flutter screens, widgets, routing | `apps/*/lib/features`, `apps/*/lib/core` (presentation) |
| App Firebase bootstrap, platform config | `apps/*` |
| VexCore contracts | `packages/vex_core/lib/` |
| Firebase adapters (future) | New adapter package or `packages/vex_core` infrastructure layer — not in apps long-term |
| Business engines | `packages/vex_engines/lib/<engine>/` |
| Architecture docs | `docs/vexcore/` |
| Canonical Firestore/Storage rules | `apps/nightlife_app/` |
| Web Hosting | `apps/nightlife_web/` |

## Firebase layout in the monorepo

- Canonical **Firestore** and **Storage** rules: `apps/nightlife_app/`
- **Cloud Functions**: `apps/nightlife_app/functions/`
- **Hosting**: `apps/nightlife_web/firebase.json` with `public: build/web`
- Web `firebase.json` references rules via `../nightlife_app/firestore.rules` and `../nightlife_app/storage.rules` (unchanged relative semantics under `apps/`)

Deploy commands run from the relevant app directory unless a workspace-level Firebase config is introduced later.

## Source folders outside the monorepo

The original sibling folders at `C:\Users\Zibbe\nightlife_app`, `nightlife_web`, `packages`, and `docs` were **not deleted**. They remain as manual cleanup candidates after verifying the monorepo copy.
