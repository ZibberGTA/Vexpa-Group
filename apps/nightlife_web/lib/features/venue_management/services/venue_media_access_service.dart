import '../../auth/services/user_role_service.dart';

/// Venue-scoped media access checks — media belongs to the venue, not the user.
class VenueMediaAccessService {
  VenueMediaAccessService._();

  static bool canManageMediaForVenue({
    required String userId,
    required String venueId,
    required UserRoleProfile profile,
    String? venueOwnerId,
    Iterable<String> accessibleVenueIds = const [],
  }) {
    if (venueId.trim().isEmpty || userId.trim().isEmpty) return false;

    if (profile.role == VexdaUserRole.admin) return true;

    if (venueOwnerId != null &&
        venueOwnerId.trim().isNotEmpty &&
        venueOwnerId == userId) {
      return true;
    }

    if (profile.venueIds.contains(venueId)) return true;

    if (accessibleVenueIds.contains(venueId)) return true;

    return false;
  }
}

/// Thrown when a user attempts to manage media for an inaccessible venue.
class VenueMediaAccessDeniedException implements Exception {
  VenueMediaAccessDeniedException(this.message);

  final String message;

  @override
  String toString() => message;
}
