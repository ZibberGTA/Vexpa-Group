# Current Code Audit

## Workspace Findings

| Area | Finding |
| --- | --- |
| Parent workspace | Consolidated monorepo at `C:\Users\Zibbe\vexda` (`apps/`, `packages/`, `docs/`). Legacy sibling folders may still exist outside the monorepo until manually removed. |
| Package type | Both applications are Flutter packages with independent `pubspec.yaml` files. |
| Git layout | Single Git repository at `vexda/`. Pre-monorepo `nightlife_app` history backed up under `vexda/.backup/`. |
| Monorepo tooling | No `melos.yaml` was found in either application root; Melos was not added. |
| Shared package feasibility | Applications use `path: ../../packages/vex_core` from `apps/<app>/`. |
| Docs | Mobile has `docs/feature-047-venue-claim-search-backfill.md`; web has deployment, Firebase, product, and web architecture docs. Parent `docs/vexcore` was created for shared architecture docs. |
| Tests | Mobile has `tests/` from prior Firebase rules work and Flutter defaults may exist; web has many feature tests under `test/` and `tests/` depending on branch state. |
| State management | No Bloc, Riverpod, Provider dependency in pubspecs. Both apps primarily use `StatefulWidget`, `setState`, `StreamBuilder`, `FutureBuilder`, static services, and repository instances. |
| Dependency injection | Mostly constructor overrides in repositories/services for tests plus static service access; no DI container. |
| Routing | Mobile uses `AppRouter.onGenerateRoute`; web uses `AppRouter.onGenerateRoute` plus `AuthGuard` wrappers for protected web routes. |

## Dependency Versions

| Project | Dart SDK | Firebase Auth | Firestore | Storage | Functions | Messaging |
| --- | --- | --- | --- | --- | --- | --- |
| `nightlife_app` | `^3.11.5` | `^5.5.0` | `^5.6.6` | `^12.4.5` | none | `^15.2.5` |
| `nightlife_web` | `^3.12.0` | `^5.5.0` | `^5.6.6` | `^12.4.5` | `^5.6.2` | none |

## Relevant File Catalogue

| Project | File | Current responsibility | VexCore layer | Keep/Move/Wrap/Replace | Risk | Notes |
| ------- | ---- | ---------------------- | ------------- | ---------------------- | ---- | ----- |
| Mobile | `lib/main.dart` | Initializes Firebase directly and runs app. | Configuration / adapters | Wrap later | Medium | Firebase bootstrap is app-level now; no behavior change in Foundation 1.0. |
| Mobile | `lib/firebase_options.dart` | Generated Firebase options. | Configuration adapter | Keep | Low | Generated file should stay app-specific. |
| Mobile | `lib/core/navigation/app_router.dart` | Route table for splash, auth, business login, home. | Presentation boundary | Keep | Low | No route guard abstraction yet. |
| Mobile | `lib/features/auth/screens/auth_gate.dart` | Auth-state gate between login and main app. | Authentication / presentation | Wrap later | Medium | Should eventually consume auth + identity contracts. |
| Mobile | `lib/features/auth/services/auth_service.dart` | Firebase Auth login/register/provider login, anonymous guest setup, writes `users/{uid}`. | Authentication / identity adapter | Wrap first | High | Mixes auth, user profile writes, role normalization, display name fallback. |
| Mobile | `lib/features/auth/services/user_role_service.dart` | Resolves app role from claims, `staff`, `users`, `venueIds`, owned venues. | Identity / permissions | Move logic behind contract | High | Most important mobile identity source. |
| Mobile | `lib/features/admin/services/admin_permission_service.dart` | Staff roles, role levels, staff lookup, custom-claim fallback. | Permissions / identity | Replace with shared evaluator later | High | Duplicates web staff concepts with different role set. |
| Mobile | `lib/features/admin/services/admin_metrics_service.dart` | Reads Firestore for admin dashboard metrics. | Data / observability | Wrap | Medium | Repository-like data access in service. |
| Mobile | `lib/features/admin/services/admin_operations_service.dart` | Admin writes/deletes/restores plus auth actor lookup. | Data / audit / permissions | Wrap | High | Privileged operations need centralized permission/audit model. |
| Mobile | `lib/features/admin/screens/admin_dashboard_screen.dart` | Large UI plus direct Firestore streams. | Presentation leaking data access | Replace gradually | High | UI directly uses Firestore; should be split before migration. |
| Mobile | `lib/features/analytics/services/analytics_service.dart` | Writes/reads analytics data in Firestore. | Observability / analytics engine | Wrap | Medium | Needs tenant-isolation review. |
| Mobile | `lib/features/account/services/account_self_service.dart` | Account deletion/profile self-service. | Identity / data | Wrap | Medium | Sensitive user data lifecycle. |
| Mobile | `lib/features/favourites/services/favourites_service.dart` | Auth-scoped favourites data access. | Data | Wrap | Low | Candidate after core identity. |
| Mobile | `lib/features/favourites/screens/favourites_screen.dart` | UI with direct Auth/Firestore and batch writes. | Presentation leaking data access | Replace later | Medium | Direct Firestore in screen. |
| Mobile | `lib/features/venues/services/venue_search_service.dart` | Venue search reads Firestore. | Data / discovery engine | Wrap | Medium | Public discovery needs privacy-safe model. |
| Mobile | `lib/features/search/services/search_service.dart` | Search Firestore service. | Data / discovery engine | Wrap | Medium | Similar responsibility to web search repositories. |
| Mobile | `lib/features/venues/services/venue_media_service.dart` | Firestore venue media reads. | Data / storage | Wrap | Medium | Storage itself not directly imported in mobile audit hits. |
| Mobile | `lib/features/management/services/soft_delete_service.dart` | Soft-delete operations with auth actor. | Data / audit | Wrap | Medium | Needs shared audit model. |
| Mobile | `lib/features/monetisation/services/subscription_service.dart` | Subscription reads and auth context. | Data / integrations | Wrap | Medium | Entitlement checks should become permission/config inputs. |
| Mobile | `lib/features/payments/services/stripe_checkout_service.dart` | Stripe checkout data/function-like workflow via Firestore. | Integrations / data | Wrap | High | External API boundary should not leak. |
| Mobile | `lib/features/notifications/services/notification_service.dart` | Notification data access. | Events / data | Wrap later | Medium | Future event consumer candidate. |
| Mobile | `lib/features/chat/services/chat_service.dart` | Auth-scoped chat Firestore access. | Data | Remain separate initially | Medium | Feature-specific and not Foundation 1.0. |
| Web | `lib/main.dart` | Initializes `VexdaFirebase`, configures `MaterialApp`, wraps `DevelopmentGate`. | Configuration / presentation | Keep | Low | Recently adjusted gate structure; no VexCore runtime dependency. |
| Web | `lib/core/firebase/vexda_firebase.dart` | Firebase bootstrap with readiness guard. | Configuration adapter | Wrap later | Medium | More defensive than mobile bootstrap. |
| Web | `lib/core/routing/app_router.dart` | Web route table and protected route wrapping. | Presentation boundary | Keep | Medium | Admin/venue route access tied to `AuthGuard`. |
| Web | `lib/core/widgets/development_gate.dart` | Private holding gate using auth state and approved email config. | Configuration / authentication | Keep temporary | Medium | Presentation-layer temporary gate, not VexCore. |
| Web | `lib/features/auth/services/auth_service.dart` | Firebase Auth login/register/logout, writes `users/{uid}` audit/profile. | Authentication / identity adapter | Wrap first | High | Similar to mobile but web-specific readiness and account types. |
| Web | `lib/features/auth/services/user_role_service.dart` | Cached role profile stream from claims, `staff`, `users`, `venueIds`, owned venues. | Identity / permissions | Move logic behind contract | High | Most advanced current resolver; likely informs shared resolver. |
| Web | `lib/features/auth/widgets/auth_guard.dart` | Route guard using auth stream and role profile stream. | Presentation consuming permissions | Pilot later | High | Good first migration consumer after auth/identity/permission contracts. |
| Web | `lib/features/admin/permissions/*` | Staff roles, permissions, permission gates/UI helpers. | Permissions | Wrap/merge later | High | Strongest existing permission model, but web-only. |
| Web | `lib/features/admin/data/admin_dashboard_repository.dart` | Broad admin Firestore repository, staff invites, users, venues, deletion, subscriptions. | Data / permissions / audit | Split before migration | High | Too broad for direct move; needs bounded repositories. |
| Web | `lib/features/admin/data/admin_claim_venue_repository.dart` | Admin claim search/review data. | Claim engine / data | Wrap | Medium | Related to claim engine. |
| Web | `lib/features/venue_claims/data/venue_claim_repository.dart` | Claim search, Firestore claim data, Cloud Functions submit workflow. | Claim engine / integrations | Wrap | High | Only current Functions direct access. |
| Web | `lib/features/search/data/search_venue_repository.dart` | Public venue query filtered by `searchablePublic`. | Discovery data | Wrap | Medium | Duplicates mobile venue discovery concepts. |
| Web | `lib/features/search/data/sources/venue_search_data_source.dart` | Public venue search data source. | Discovery data | Wrap | Medium | Shares public gating concerns. |
| Web | `lib/features/venue/data/*_repository.dart` | Venue details, deals, drinks, events, related content. | Data / venue engine | Wrap | Medium | Mostly repository-pattern already. |
| Web | `lib/features/venue_management/data/venue_*repository.dart` | Venue dashboard/profile/media repositories. | Data / storage / permissions | Wrap | High | Tenant confidentiality and owner access are critical. |
| Web | `lib/features/venue_management/data/venue_media_storage_service.dart` | Firebase Storage uploads/deletes/download URLs. | Storage adapter | Wrap after auth/permissions | High | Storage path tenancy must be controlled. |
| Web | `lib/features/venue_management/services/subscription_service.dart` | Venue subscription entitlement. | Permissions / configuration | Wrap | Medium | Entitlements should feed permission decisions. |
| Web | `lib/features/venue_management/data/venue_media_upload_logger.dart` | Upload diagnostic logging. | Observability | Wrap | Low | Candidate for shared logger later. |
| Web | `lib/core/firebase/firebase_storage_download_url.dart` | Parses Firebase Storage download URLs. | Storage utility | Wrap later | Medium | Firebase-specific parsing should not be pure domain. |
