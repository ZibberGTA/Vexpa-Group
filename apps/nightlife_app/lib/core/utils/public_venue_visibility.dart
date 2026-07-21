/// Client-side checks aligned with Firestore `isPublicVenue` rules.
final class PublicVenueVisibility {
  PublicVenueVisibility._();

  static bool isPublicMap(Map<String, dynamic>? data) {
    if (data == null || data['isDeleted'] == true) return false;
    if (data['searchablePublic'] == false) return false;
    if (data['isHidden'] == true) return false;
    if (data['publicVisible'] == false) return false;
    if (data['isVisible'] == false) return false;

    final status = (data['status'] ?? 'active').toString();
    if (status == 'deleted' || status == 'hidden' || status == 'suspended') {
      return false;
    }

    return true;
  }
}
