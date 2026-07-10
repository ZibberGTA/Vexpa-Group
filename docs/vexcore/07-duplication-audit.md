# Duplication Audit

## Duplicated or Near-Duplicated Logic

| File pair or group | Responsibility | Differences | Classification | Notes |
| --- | --- | --- | --- | --- |
| `nightlife_app/lib/features/auth/services/auth_service.dart` and `nightlife_web/lib/features/auth/services/auth_service.dart` | Firebase Auth session, login/register/logout, `users/{uid}` writes. | Mobile supports anonymous guest upgrade and Google/Microsoft providers; web has `VexdaFirebase.isReady`, allowed signup account types, login audit. | Requires interface only first | Share `AuthenticationService` contract before adapters. |
| `nightlife_app/lib/features/auth/services/user_role_service.dart` and `nightlife_web/lib/features/auth/services/user_role_service.dart` | Role resolution from claims, `staff`, `users`, `venueIds`, owned venues. | Web has profile caching, transition logs, `VexdaUserRole`, stronger stream handling; mobile has `AppUserRole` including artist/founder/management. | Needs architectural decision | Best candidate for identity contract pilot after tests. |
| `nightlife_app/lib/features/admin/services/admin_permission_service.dart` and `nightlife_web/lib/features/admin/permissions/*` | Staff roles and permissions. | Mobile uses `StaffRole {support, admin, management, founder}`; web uses `supporter, coordinator, admin, superAdmin, management, founder` and typed `StaffPermission`. | Safe to share after model decision | Web permission enum is closer to target shape. |
| Mobile admin duplicated under `features/admin/services` and `features/admin/admin/services` | Admin metrics, operations, permissions. | Appears copied under nested `admin/admin`. | Replace or delete later, not now | No deletion in Foundation 1.0. |
| Mobile venue models under `features/home/models/venue_model.dart` and `features/venues/models/venue_model.dart`; web `features/home/models/venue_preview.dart`, `features/venue/models/venue_details_view.dart`, `features/search/models/venue_search_result.dart` | Venue representations. | Different fields for discovery, details, search, management. | Requires interface only | Avoid forcing one model too early. |
| Mobile `features/venues/services/venue_search_service.dart`, `features/search/services/search_service.dart`; web `features/search/data/search_venue_repository.dart`, `features/search/data/sources/venue_search_data_source.dart`, `features/search/data/unified_search_service.dart` | Public search/discovery. | Web applies `searchablePublic`; mobile has older services and search sync. | Safe to share via repository contracts | Public/private field exposure risk. |
| Mobile `features/home/services/deal_service.dart`, `drink_service.dart`, `event_service.dart`; web `features/venue/data/venue_deals_repository.dart`, `venue_drinks_repository.dart`, `venue_events_repository.dart` | Venue content reads/writes. | Mobile mixes owner/public screens; web repositories are more separated. | Platform-specific implementation behind shared contracts | Migrate after identity/permissions. |
| Mobile `features/management/services/soft_delete_service.dart`, admin delete services; web `admin_dashboard_repository.dart` delete/archive methods | Soft delete and archive. | Web uses transactions for users/venues; mobile uses service helpers and direct screen updates. | Needs architectural decision | Audit service should precede migration. |
| Mobile `features/monetisation/services/subscription_service.dart`; web `features/venue_management/services/subscription_service.dart` and admin subscription reads | Subscription entitlement. | Web tied to venue dashboard/media limits; mobile tied to owner upgrade/boost flows. | Requires interface only | Permission evaluator should consume entitlement context. |
| Mobile `features/analytics/services/analytics_service.dart`; web `features/venue_management/data/venue_analytics_service.dart` and `venue_activity_service.dart` | Analytics reads/writes. | Both use Firestore but with different dashboard needs. | Needs architectural decision | Must anonymise/aggregate for intelligence. |
| Mobile and web Firebase initialization | Firebase bootstrap. | Mobile initializes directly in `main.dart`; web uses `VexdaFirebase` readiness guard. | Platform-specific implementation | Common contract can expose readiness/config, not implementation. |
| Mobile `features/payments/services/stripe_checkout_service.dart`; web claim `FirebaseFunctions` use | External integrations. | Different providers and callable patterns. | Requires interface only | Integrations layer should wrap external APIs. |

## Duplicated Firebase Path Strings

Common path strings found across both projects:

- `users`
- `staff`
- `venues`
- `deals`
- `drinks`
- `events`
- `trails`
- `analytics`
- `favourites`
- `notifications`
- `customers`
- `subscriptions`
- `venue_claims`
- `venue_claim_directory`
- `deleted_users`
- `deleted_venues`

## Duplicated Role Mappings

Role aliases appear in both apps but map to different enums:

- `founder`, `management`, `manager`, `admin`, `staff`
- `owner`, `venueowner`, `venue_owner`, `business`, `business_owner`, `venue`
- `employee`
- `artist`, `performer`
- `customer`, `user`, `guest`

Role levels overlap but are not identical:

- Shared: `30` admin, `60` management, `100` founder.
- Mobile: support `10`; no coordinator/superAdmin main enum.
- Web: supporter `10`, coordinator `20`, superAdmin `50`.

## Error Handling Duplication

- Auth screens catch `FirebaseAuthException` directly in both apps.
- Role resolvers catch `FirebaseException` and silently degrade in both apps.
- Web has more structured timeout/retry UX for permission loading.
- Storage/media upload logging is web-specific and should feed future observability.

## Classification Summary

| Classification | Items |
| --- | --- |
| Safe to share | Permission enum/service shape after role model decision; shared result/exception primitives; clock; pagination. |
| Requires interface only | Authentication, identity resolution, public search, subscriptions, integrations. |
| Platform-specific implementation | Firebase bootstrap, web file download/map utilities, mobile navigation shell, asset/UI concerns. |
| Should remain separate | Presentation widgets, screens, feature-specific UI state, current engine workflows. |
| Needs architectural decision | Final role hierarchy, identity source precedence, venue ownership model, analytics/intelligence data boundaries. |
