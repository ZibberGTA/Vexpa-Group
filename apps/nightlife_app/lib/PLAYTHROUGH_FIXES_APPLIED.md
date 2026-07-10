# Playthrough fixes applied

- Added Google and Microsoft sign-in methods to `features/auth/services/auth_service.dart`.
- Added Google and Microsoft buttons to the login screen.
- Default social sign-ins create/merge a Firestore `users/{uid}` document with role `user` unless an existing role already exists.
- Expanded role parsing to include founder, management, admin, owner, artist, and user.
- Staff/admin dashboard routing now only triggers for staff roles.
- Removed the map `Recommended now` bottom strip.
- Removed the map `Live map` venue-count badge.
- Moved `Best Now` to the top-left map position.
- Replaced the horizontal scrolling search filter pills with compact wrapping chips.
- Removed `My Bookings` and `Messages` from the normal account screen.
- Added `Messages` into the Artist Dashboard next to existing artist booking/profile tools.

Note: Social provider login requires Google and Microsoft providers to be enabled in Firebase Authentication.
