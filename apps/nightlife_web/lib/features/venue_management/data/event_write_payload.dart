import 'package:cloud_firestore/cloud_firestore.dart';

/// Builds Firestore payloads for venue event writes.
class EventWritePayload {
  EventWritePayload._();

  static Map<String, dynamic> build({
    required String venueId,
    required String venueName,
    required String title,
    required String description,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required bool isActive,
    required bool featured,
    required String createdBy,
    String category = 'General',
    String imageUrl = '',
  }) {
    final trimmedTitle = title.trim();
    final trimmedDescription = description.trim();

    return {
      'venueId': venueId,
      'venueName': venueName,
      'title': trimmedTitle,
      'description': trimmedDescription,
      'startDateTime': Timestamp.fromDate(startDateTime),
      'endDateTime': Timestamp.fromDate(endDateTime),
      'dateTime': Timestamp.fromDate(startDateTime),
      'category': category,
      'imageUrl': imageUrl,
      'isDeleted': false,
      'isActive': isActive,
      'featured': featured,
      'searchTerms': buildSearchTerms([
        trimmedTitle,
        trimmedDescription,
        venueName,
        category,
      ]),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    };
  }

  static Map<String, dynamic> buildPatch({
    required String updatedBy,
    String? title,
    DateTime? startDateTime,
    DateTime? endDateTime,
    bool? isActive,
    bool? featured,
  }) {
    final payload = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    };

    if (title != null) payload['title'] = title.trim();
    if (startDateTime != null) {
      payload['startDateTime'] = Timestamp.fromDate(startDateTime);
    }
    if (endDateTime != null) {
      payload['endDateTime'] = Timestamp.fromDate(endDateTime);
    }
    if (isActive != null) payload['isActive'] = isActive;
    if (featured != null) payload['featured'] = featured;

    return payload;
  }

  static List<String> buildSearchTerms(List<String> values) {
    final terms = <String>{};

    for (final value in values) {
      final cleanValue = value.trim().toLowerCase();
      if (cleanValue.isEmpty) continue;

      terms.add(cleanValue);

      final words = cleanValue.split(RegExp(r'[^a-z0-9]+'));
      for (final word in words) {
        if (word.isEmpty) continue;
        terms.add(word);
        for (var i = 1; i <= word.length; i++) {
          terms.add(word.substring(0, i));
        }
      }
    }

    return terms.take(100).toList();
  }
}

DateTime mergeEventDate(DateTime existing, DateTime picked) {
  return DateTime(
    picked.year,
    picked.month,
    picked.day,
    existing.hour,
    existing.minute,
  );
}

DateTime mergeEventTime(DateTime existing, String time) {
  final parts = time.trim().split(':');
  if (parts.length < 2) return existing;
  final hour = int.tryParse(parts[0]) ?? existing.hour;
  final minute =
      int.tryParse(parts[1].replaceAll(RegExp(r'[^0-9]'), '')) ?? existing.minute;
  return DateTime(
    existing.year,
    existing.month,
    existing.day,
    hour,
    minute,
  );
}
