/// Prepared venue profile fields ready for persistence.
final class VenueProfileUpdate {
  const VenueProfileUpdate({
    required this.fields,
    this.serverTimestampFields = const ['updatedAt'],
  });

  final Map<String, dynamic> fields;
  final List<String> serverTimestampFields;
}
