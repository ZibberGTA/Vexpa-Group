import 'package:cloud_firestore/cloud_firestore.dart';

import 'venue_management_activity_types.dart';

/// Append-only venue management activity record.
///
/// Used when recording successful owner/manager actions and when loading
/// recent activity for the venue dashboard feed.
class VenueManagementActivity {
  const VenueManagementActivity({
    this.activityId,
    required this.venueId,
    required this.sourceArea,
    required this.actionType,
    required this.entityType,
    required this.entityId,
    required this.entityName,
    required this.description,
    required this.actorUid,
    this.actorDisplayName,
    this.metadata = const {},
    this.version = VenueManagementActivityStorage.currentVersion,
    this.occurredAt,
  });

  final String? activityId;
  final String venueId;
  final String sourceArea;
  final String actionType;
  final String entityType;
  final String entityId;
  final String entityName;
  final String description;
  final String actorUid;
  final String? actorDisplayName;
  final Map<String, dynamic> metadata;
  final int version;
  final DateTime? occurredAt;

  bool get isValidForWrite =>
      venueId.trim().isNotEmpty &&
      sourceArea.trim().isNotEmpty &&
      actionType.trim().isNotEmpty &&
      entityType.trim().isNotEmpty &&
      entityId.trim().isNotEmpty &&
      entityName.trim().isNotEmpty &&
      description.trim().isNotEmpty &&
      actorUid.trim().isNotEmpty &&
      version > 0;

  Map<String, dynamic> toFirestore({FieldValue? occurredAt}) {
    return {
      'venueId': venueId.trim(),
      'sourceArea': sourceArea.trim(),
      'actionType': actionType.trim(),
      'entityType': entityType.trim(),
      'entityId': entityId.trim(),
      'entityName': entityName.trim(),
      'description': description.trim(),
      'actorUid': actorUid.trim(),
      if (actorDisplayName != null && actorDisplayName!.trim().isNotEmpty)
        'actorDisplayName': actorDisplayName!.trim(),
      'metadata': Map<String, dynamic>.from(metadata),
      'version': version,
      'occurredAt': occurredAt ?? FieldValue.serverTimestamp(),
    };
  }

  factory VenueManagementActivity.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    DateTime? occurredAt;
    final rawOccurredAt = data['occurredAt'];
    if (rawOccurredAt is Timestamp) {
      occurredAt = rawOccurredAt.toDate();
    } else if (rawOccurredAt is DateTime) {
      occurredAt = rawOccurredAt;
    }

    return VenueManagementActivity(
      activityId: id,
      venueId: data['venueId']?.toString() ?? '',
      sourceArea: data['sourceArea']?.toString() ?? '',
      actionType: data['actionType']?.toString() ?? '',
      entityType: data['entityType']?.toString() ?? '',
      entityId: data['entityId']?.toString() ?? '',
      entityName: data['entityName']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      actorUid: data['actorUid']?.toString() ?? '',
      actorDisplayName: data['actorDisplayName']?.toString(),
      metadata: data['metadata'] is Map
          ? Map<String, dynamic>.from(data['metadata'] as Map)
          : const {},
      version: data['version'] is num ? (data['version'] as num).toInt() : 1,
      occurredAt: occurredAt,
    );
  }

  VenueManagementActivity copyWith({
    String? activityId,
    DateTime? occurredAt,
  }) {
    return VenueManagementActivity(
      activityId: activityId ?? this.activityId,
      venueId: venueId,
      sourceArea: sourceArea,
      actionType: actionType,
      entityType: entityType,
      entityId: entityId,
      entityName: entityName,
      description: description,
      actorUid: actorUid,
      actorDisplayName: actorDisplayName,
      metadata: metadata,
      version: version,
      occurredAt: occurredAt ?? this.occurredAt,
    );
  }
}
