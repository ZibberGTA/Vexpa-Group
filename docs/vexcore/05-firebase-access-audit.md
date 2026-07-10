# Firebase Access Audit

## Search Terms

The audit searched both application `lib/` trees for:

`FirebaseAuth`, `FirebaseFirestore`, `FirebaseStorage`, `FirebaseFunctions`, `FirebaseMessaging`, `FirebaseAnalytics`, `FirebaseRemoteConfig`, `FirebaseCrashlytics`, `FirebasePerformance`, `FirebaseAppCheck`, `collection(`, `doc(`, `snapshots(`, `.get(`, `.set(`, `.update(`, `.delete(`, `runTransaction(`, `WriteBatch`, `putFile(`, `putData(`, `getDownloadURL(`.

## Totals by Product

| Project | Firebase Auth files | Firestore files | Storage files | Functions files | Messaging files | Analytics/Remote/Crash/Perf/AppCheck files |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `nightlife_app` | 29 | 62 | 0 | 0 | 0 direct references | 0 |
| `nightlife_web` | 22 | 22 | 3 | 1 | 0 | 0 |

`nightlife_app` declares `firebase_messaging` in `pubspec.yaml`, but no direct `FirebaseMessaging` reference was found under `lib/`.

## Totals by Operation

| Project | `collection(` | `doc(` | `snapshots(` | `.get(` | `.set(` | `.update(` | `.delete(` | `runTransaction(` | `WriteBatch` | `putData(` | `getDownloadURL(` |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `nightlife_app` | 62 | 41 | 36 | 42 | 17 | 19 | 10 | 3 | 0 | 0 | 0 |
| `nightlife_web` | 22 | 14 | 9 | 16 | 9 | 4 | 4 | 1 | 0 | 1 | 1 |

## Direct Firebase Auth Files

| Project | Files |
| --- | --- |
| Mobile | `nightlife_app\lib\features\account\services\account_self_service.dart`; `nightlife_app\lib\features\account\screens\account_management_screen.dart`; `nightlife_app\lib\features\admin\services\admin_permission_service.dart`; `nightlife_app\lib\features\admin\services\admin_operations_service.dart`; `nightlife_app\lib\features\admin\admin\services\admin_permission_service.dart`; `nightlife_app\lib\features\admin\admin\services\admin_operations_service.dart`; `nightlife_app\lib\features\chat\services\chat_service.dart`; `nightlife_app\lib\features\navigation\main_navigation_screen.dart`; `nightlife_app\lib\features\artists\services\artist_service.dart`; `nightlife_app\lib\features\artists\screens\artist_dashboard_screen.dart`; `nightlife_app\lib\features\auth\services\user_role_service.dart`; `nightlife_app\lib\features\auth\services\auth_service.dart`; `nightlife_app\lib\features\monetisation\services\subscription_service.dart`; `nightlife_app\lib\features\venues\screens\apply_to_perform_screen.dart`; `nightlife_app\lib\features\monetisation\services\boost_service.dart`; `nightlife_app\lib\features\management\services\soft_delete_service.dart`; `nightlife_app\lib\features\bookings\services\booking_service.dart`; `nightlife_app\lib\features\auth\screens\register_screen.dart`; `nightlife_app\lib\features\auth\screens\login_screen.dart`; `nightlife_app\lib\features\auth\screens\business_login_screen.dart`; `nightlife_app\lib\features\monetisation\screens\boost_venue_screen.dart`; `nightlife_app\lib\features\favourites\screens\favourites_screen.dart`; `nightlife_app\lib\features\favourites\services\favourites_service.dart`; `nightlife_app\lib\features\payments\services\stripe_checkout_service.dart`; `nightlife_app\lib\features\trails\services\trail_service.dart`; `nightlife_app\lib\features\owner\screens\edit_deal_screen.dart`; `nightlife_app\lib\features\owner\screens\edit_drink_screen.dart`; `nightlife_app\lib\features\owner\screens\edit_venue_screen.dart`; `nightlife_app\lib\features\splash\screens\splash_screen.dart`. |
| Web | `nightlife_web\lib\core\widgets\development_preview_sign_in_dialog.dart`; `nightlife_web\lib\features\admin\widgets\claims\admin_venue_claims_page.dart`; `nightlife_web\lib\features\business\screens\claim_venue_page.dart`; `nightlife_web\lib\features\venue_management\widgets\drinks\venue_drinks_management_page.dart`; `nightlife_web\lib\features\venue_management\widgets\drinks\edit_drink_dialog.dart`; `nightlife_web\lib\features\auth\services\user_role_service.dart`; `nightlife_web\lib\features\auth\services\auth_service.dart`; `nightlife_web\lib\features\auth\screens\register_screen.dart`; `nightlife_web\lib\features\auth\screens\login_screen.dart`; `nightlife_web\lib\features\auth\screens\forgot_password_screen.dart`; `nightlife_web\lib\features\venue_management\widgets\drinks\bulk_import_drinks_dialog.dart`; `nightlife_web\lib\features\venue_management\widgets\drinks\bulk_edit_drinks_dialog.dart`; `nightlife_web\lib\features\venue_management\widgets\drinks\add_drink_dialog.dart`; `nightlife_web\lib\features\venue_management\widgets\deals\add_deal_dialog.dart`; `nightlife_web\lib\features\venue_management\widgets\deals\bulk_edit_deals_dialog.dart`; `nightlife_web\lib\features\venue_management\widgets\profile\venue_profile_management_page.dart`; `nightlife_web\lib\features\venue_management\widgets\deals\venue_deals_management_page.dart`; `nightlife_web\lib\features\venue_management\widgets\events\add_event_dialog.dart`; `nightlife_web\lib\features\venue_management\widgets\deals\edit_deal_dialog.dart`; `nightlife_web\lib\features\venue_management\widgets\profile\edits\venue_profile_edit_dialog.dart`; `nightlife_web\lib\features\venue_management\widgets\gallery\venue_gallery_management_page.dart`; `nightlife_web\lib\features\venue_management\widgets\events\venue_events_management_page.dart`. |

## Direct Firestore Files

| Project | Files |
| --- | --- |
| Mobile | 62 files, concentrated in `features/*/services`, several `features/*/screens`, and duplicated `features/admin/admin`. Highest-risk files are `features/auth/services/auth_service.dart`, `features/auth/services/user_role_service.dart`, `features/admin/services/admin_permission_service.dart`, `features/admin/services/admin_operations_service.dart`, `features/admin/screens/admin_dashboard_screen.dart`, `features/favourites/screens/favourites_screen.dart`, `features/map/screens/venue_map_screen.dart`, and owner/venue edit screens. |
| Web | `nightlife_web\lib\features\auth\services\auth_service.dart`; `nightlife_web\lib\features\auth\services\user_role_service.dart`; `nightlife_web\lib\features\admin\data\admin_dashboard_repository.dart`; `nightlife_web\lib\features\admin\data\admin_claim_venue_repository.dart`; `nightlife_web\lib\features\deals\data\deals_repository.dart`; `nightlife_web\lib\features\trail\data\trail_details_repository.dart`; `nightlife_web\lib\features\event\data\event_details_repository.dart`; `nightlife_web\lib\features\venue\data\venue_details_repository.dart`; `nightlife_web\lib\features\venue\data\venue_deals_repository.dart`; `nightlife_web\lib\features\venue\data\venue_events_repository.dart`; `nightlife_web\lib\features\venue\data\venue_drinks_repository.dart`; `nightlife_web\lib\features\venue_management\widgets\profile\venue_profile_activity_counts.dart`; `nightlife_web\lib\features\search\data\search_venue_repository.dart`; `nightlife_web\lib\features\venue_management\data\venue_analytics_service.dart`; `nightlife_web\lib\features\venue_management\data\venue_images_repository.dart`; `nightlife_web\lib\features\venue_management\data\venue_activity_service.dart`; `nightlife_web\lib\features\venue_management\data\venue_dashboard_repository.dart`; `nightlife_web\lib\features\venue_claims\data\venue_claim_repository.dart`; `nightlife_web\lib\features\search\data\unified_search_service.dart`; `nightlife_web\lib\features\venue_management\data\venue_profile_repository.dart`; `nightlife_web\lib\features\venue_management\data\venue_media_repository.dart`; `nightlife_web\lib\features\search\data\sources\venue_search_data_source.dart`. |

## Storage and Functions

| Project | File | Product | Path/operation | Code type | Proposed VexCore destination | Priority |
| --- | --- | --- | --- | --- | --- | --- |
| Web | `lib/features/venue_management/data/venue_media_storage_service.dart` | Storage | `ref(storagePath).putData`, `delete`, `getMetadata`, `getDownloadURL` | Service | Storage adapter | High |
| Web | `lib/core/map/venue_marker_image_loader_web.dart` | Storage | Parses download URL then loads bytes from storage | Utility | Storage utility / adapter | Medium |
| Web | `lib/core/firebase/firebase_storage_download_url.dart` | Storage | Firebase download URL parsing | Utility | Storage utility | Medium |
| Web | `lib/features/venue_claims/data/venue_claim_repository.dart` | Functions | `FirebaseFunctions.instance` and `FirebaseFunctionsException` for claim flow | Repository | Integrations / Claim Engine | High |

## Identifiable Collections and Operations

| Collection or path | Seen in | Operations | Proposed destination |
| --- | --- | --- | --- |
| `users/{uid}` | Mobile and web auth/role/admin repositories | read, set, update, stream, transaction/archive | Identity adapter / admin data contracts |
| `staff/{uid}` and staff email queries | Mobile and web role/permission services | read, stream, query by email/emailLower | Identity resolver / permissions |
| `venues` | Both apps, many services/screens/repositories | read, stream, add, update, query by owner/search/public flags | Data engine + discovery/venue engines |
| `deals`, `drinks`, `events`, `trails` | Both apps | read, stream, add, update, batch set in web drinks | Domain repositories behind data contracts |
| `venue_claims`, `venue_claim_directory` | Web claim repositories/admin | read, stream, set, audit subcollection | Claim engine + data/integration contracts |
| `analytics` | Mobile analytics, web venue management | read, count, query | Observability/analytics engine |
| `customers`, `subscriptions`, `payment_events` | Web admin, mobile monetisation/payments | read and entitlement checks | Integrations + permissions |
| `favourites`, `notifications`, `bookings`, `chat` | Mobile features | read/write/stream | Feature repositories after foundation |
| `deleted_users`, `deleted_venues`, soft-delete fields | Admin/management | transaction archive, update `isDeleted` | Data + audit |

## Migration Priority

1. Authentication service contract and adapters.
2. Identity resolver for Firebase Auth + `users` + `staff` + claims + venue ownership.
3. Permission evaluator for admin and venue staff access.
4. Admin route guard pilot.
5. Storage adapter for venue media after permission context is stable.
6. Claim repository integration boundary for Cloud Functions.
