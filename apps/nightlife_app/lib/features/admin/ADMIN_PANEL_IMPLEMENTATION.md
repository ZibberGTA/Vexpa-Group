# Staff Admin Panel Implementation

Implemented in Flutter/Firebase under `lib/features/admin`.

## Staff roles

- `support` / level 10: account support, venue name/image edits, reports, recovery centre.
- `admin` / level 30: full venue/drink/deal/event/user moderation.
- `management` / level 60: staff management, audit logs, app settings view, no financials.
- `founder` / level 100: full access, financials, subscriptions, hard delete, critical settings.

## Main files

- `lib/features/admin/screens/admin_dashboard_screen.dart`
- `lib/features/admin/services/admin_permission_service.dart`
- `lib/features/admin/services/admin_operations_service.dart`
- `lib/features/account/screens/account_management_screen.dart`
- `lib/features/account/services/account_self_service.dart`
- `firestore.rules`

## Firebase custom claims expected

```json
{
  "staff": true,
  "staffRole": "management",
  "roleLevel": 60
}
```

The app also falls back to `staff/{uid}` with `role` and `roleLevel` fields for development.

## Collections used

- `staff`
- `staff_invites`
- `users`
- `venues`
- `drinks`
- `deals`
- `events`
- `artists`
- `reports`
- `deleted_items`
- `audit_logs`
- `account_deletion_requests`
- `financials`
- `subscriptions`
- `app_settings`

## User self-service

Users can now open **Account > Manage My Account** to:

- edit display name, phone and city
- change email with verification
- change password
- manage notification preferences
- request account deletion

Venue and artist account self-service areas are represented in the admin panel so staff can support those account types clearly.
