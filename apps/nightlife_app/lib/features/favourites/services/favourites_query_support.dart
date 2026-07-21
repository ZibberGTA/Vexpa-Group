/// Pure helpers for owner-scoped favourite queries and document identity.
class FavouritesQuerySupport {
  FavouritesQuerySupport._();

  static String docIdFor(String userId, String venueId) {
    return '${userId}_$venueId';
  }

  static bool isFavouriteInSnapshot(
    Iterable<Map<String, dynamic>> favouriteDocs,
    String venueId,
  ) {
    for (final data in favouriteDocs) {
      if (data['venueId'] == venueId) {
        return true;
      }
    }
    return false;
  }

  static String? docIdForVenue(
    Iterable<({String id, Map<String, dynamic> data})> favouriteDocs,
    String venueId,
  ) {
    for (final doc in favouriteDocs) {
      if (doc.data['venueId'] == venueId) {
        return doc.id;
      }
    }
    return null;
  }

  static Set<String> filterOwnedDocIds(
    Iterable<String> requestedDocIds,
    Iterable<String> ownedDocIds,
  ) {
    final owned = ownedDocIds.toSet();
    return requestedDocIds.where(owned.contains).toSet();
  }
}
