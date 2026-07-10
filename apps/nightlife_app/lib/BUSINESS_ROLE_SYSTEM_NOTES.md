# Business Login + Role System

## What was added

### 1. Role-based app routing
`AuthGate` now checks the signed-in user's Firestore role from:

```text
users/{uid}.role
```

Supported roles:

```text
user   -> customer app / MainNavigationScreen
owner  -> BusinessDashboardScreen
admin  -> AdminDashboardScreen
```

Legacy role names such as `customer`, `business`, and `venue_owner` are normalized safely.

### 2. Business login screen
New file:

```text
lib/features/auth/screens/business_login_screen.dart
```

This screen only allows accounts with `owner` or `admin` roles to continue. If a normal customer tries to use the business login, they are signed out and shown a message.

### 3. Register role selector fixed
`RegisterScreen` now stores roles as:

```text
user
owner
```

instead of mixing `customer` and `owner`.

### 4. Login routing fixed
Normal login now sends users to `AuthGate`, not directly to the customer home screen. This means business accounts correctly land on the business dashboard.

### 5. New route
Added:

```dart
AppRoutes.businessLogin
```

## Firestore user document example

```json
{
  "uid": "firebase-user-id",
  "name": "Venue Owner Name",
  "email": "owner@example.com",
  "role": "owner",
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp"
}
```

## Next recommended step
Add Firestore security rules so only owners can edit their own venues, drinks, deals, and events.
