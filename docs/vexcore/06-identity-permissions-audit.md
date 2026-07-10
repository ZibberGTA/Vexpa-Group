# Identity and Permissions Audit

## Confirmed Identity Sources

| Source | Mobile | Web | Notes |
| --- | --- | --- | --- |
| Firebase Auth UID | Yes | Yes | Primary session identifier. |
| Firebase Auth email | Yes | Yes | Used for display names and staff email fallback. |
| `users/{uid}` | Yes | Yes | Stores role/account type/profile/status fields. |
| `staff/{uid}` | Yes | Yes | Staff/admin role source; rules must allow bootstrap self-read. |
| Custom claims | Yes | Yes | `staff`, `staffRole`, `role`, `roleLevel`. Risk of stale claims. |
| `role` | Yes | Yes | Free-form strings with multiple aliases. |
| `roleLevel` | Yes | Yes | Staff/admin numeric hierarchy. |
| `isAdmin` | Yes | Yes | Boolean admin shortcut in user docs. |
| `isStaff` / `staff` | Yes | Yes | Staff booleans in claims/docs. |
| `ownerId` | Yes | Yes | Venue ownership inferred by querying `venues`. |
| `venueIds` | Yes | Yes | Venue employee/staff assignment list. |
| `status` | Limited | Yes | Web registration writes `status: active`; web audit also sees suspended/deleted flags. |
| `disabled` | Yes | Yes | Used in account/admin contexts. |
| `isSuspended` | Not found in mobile search | Yes | Web has suspension checks/fields. |
| `isDeleted` | Yes | Yes | Soft-delete gating on many queries. |

## Current Role Sources of Truth

### Mobile

Mobile role resolution is centered in `lib/features/auth/services/user_role_service.dart`, with additional staff logic in `lib/features/admin/services/admin_permission_service.dart`.

Observed fallback order in `UserRoleService.resolveRoleForUser`:

1. Refresh or read Firebase Auth token.
2. Custom claims where `staff == true`, optionally using `roleLevel`, `staffRole`, or `role`.
3. `staff/{uid}` Firestore document.
4. Staff lookup by `emailLower`.
5. Legacy staff lookup by `email`.
6. `users/{uid}` role/account type.
7. `venueIds` count from `users/{uid}`.
8. Owned venue query against `venues.where('ownerId', isEqualTo: uid)`.
9. Fallback to `user`.

Mobile `AppUserRole` values: `founder`, `management`, `admin`, `owner`, `employee`, `artist`, `user`.

Mobile staff role levels: support `10`, admin `30`, management `60`, founder `100`.

### Web

Web role resolution is centered in `lib/features/auth/services/user_role_service.dart`, with admin-specific permission mapping in `lib/features/admin/permissions`.

Observed fallback order:

1. Firebase readiness check through `VexdaFirebase`.
2. Firebase Auth session.
3. Custom claims using `staff`, `staffRole`, `role`, `roleLevel`.
4. `staff/{uid}` with retries and debug transition logs.
5. Email fallback using `staff.emailLower`.
6. Legacy email fallback using `staff.email`.
7. `users/{uid}` document.
8. `venueIds` and owned venue query.
9. Cached profile and profile stream to avoid downgrade flicker.

Web `VexdaUserRole` values: `admin`, `venueOwner`, `employee`, `regularUser`.

Web admin `StaffRole` values: `supporter` `10`, `coordinator` `20`, `admin` `30`, `superAdmin` `50`, `management` `60`, `founder` `100`.

## Route Guard Logic

| Project | Guard | Logic |
| --- | --- | --- |
| Mobile | `features/auth/screens/auth_gate.dart` and router flow | Auth gate chooses login/main app; admin/business checks are more distributed across screens/services. |
| Web | `features/auth/widgets/auth_guard.dart` | `AuthGuardRequirement.admin` requires `role.canAccessAdminDashboard`; `venueStaff` allows admin, venue owner, or employee. Uses auth stream plus role profile stream. |

## Duplicated Role Checks

- Mobile `AppUserRoleX.isStaff`, `isBusiness`, `canManageVenues`.
- Web `VexdaUserRoleX.canAccessAdminDashboard`, `canAccessVenueDashboard`.
- Mobile `AdminPermissionService` role-level checks and web `PermissionService` role-to-permission mapping.
- UI/widget files in both apps still read `FirebaseAuth.instance.currentUser?.uid` to stamp `createdBy`, `updatedBy`, or reviewer fields.

## Role Strings in Use

Confirmed aliases include:

- Admin/internal: `founder`, `owner_founder`, `app_owner`, `management`, `manager`, `admin`, `staff`, `support`, `supporter`, `coordinator`, `super_admin`, `superadmin`.
- Venue/business: `owner`, `venueowner`, `venue_owner`, `business`, `businessowner`, `business_owner`, `venue`, `employee`.
- Public/artist: `artist`, `performer`, `customer`, `user`, `guest`.

## Permission-Like Booleans and Entitlements

- `isAdmin`
- `isStaff`
- `staff`
- `disabled`
- `isSuspended`
- `isDeleted`
- `isGuest`
- `searchablePublic`
- `venueIds`
- subscription and media entitlement fields in venue management/subscription services

## Venue Ownership and Tenant Isolation

Both apps infer venue ownership through `venues.ownerId == uid` and assignment through `users/{uid}.venueIds`. This must become an explicit identity/permission context before repository migrations, otherwise one venue dashboard could accidentally read or write another venue's confidential data.

## Risks

| Risk | Detail |
| --- | --- |
| Bootstrap deadlock | If `staff/{uid}` self-read is denied, admin role resolution can fail before admin pages load. This was already encountered in prior rules work. |
| Stale claims | Custom claims may lag Firestore role changes and require token refresh. |
| Email-based staff matching | Email fallback can resolve an admin in app code while Firestore Rules only recognize `staff/{uid}`. Web logs this warning explicitly. |
| Divergent role hierarchies | Mobile lacks web `coordinator`/`superAdmin`; web lacks mobile `artist` in its main role enum. |
| Hard-coded UI checks | Widgets still use role booleans or current UID directly. |
| Mixed role fields | `role`, `accountType`, `roleLevel`, `isAdmin`, `staff`, `isStaff`, `venueIds`, and ownership queries all contribute to access. |

## Recommendations Separate from Facts

- First migrate contracts, then an adapter-compatible identity resolver that preserves current fallback order.
- Keep `staff/{uid}` as the rules-recognised staff principal and treat email fallback as transitional diagnostics only.
- Normalize roles into VexCore after tests capture current mobile/web behavior.
- Keep permission decisions separate from role resolution.
