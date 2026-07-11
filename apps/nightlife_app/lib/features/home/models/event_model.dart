import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vex_engines/experience/application/experience_event_visibility.dart';

class EventModel {
  final String id;
  final String venueId;
  final String title;
  final String description;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final DateTime createdAt;
  final String category;
  final String imageUrl;
  final bool isDeleted;
  final bool isActive;

  EventModel({
    required this.id,
    required this.venueId,
    required this.title,
    required this.description,
    required this.startDateTime,
    required this.endDateTime,
    required this.createdAt,
    required this.category,
    required this.imageUrl,
    required this.isDeleted,
    this.isActive = true,
  });

  /// Existing app screens still read `dateTime`; keep it as the event start.
  DateTime get dateTime => startDateTime;

  bool get isLiveOrUpcoming => ExperienceEventVisibility.isPublicVisible(
        isDeleted: isDeleted,
        isActive: isActive,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
      );

  factory EventModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final start = (data['startDateTime'] as Timestamp?)?.toDate() ??
        (data['dateTime'] as Timestamp?)?.toDate() ??
        DateTime.now();

    final end = (data['endDateTime'] as Timestamp?)?.toDate() ??
        start.add(const Duration(hours: 24));

    return EventModel(
      id: doc.id,
      venueId: data['venueId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startDateTime: start,
      endDateTime: end,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      category: data['category'] ?? 'General',
      imageUrl: data['imageUrl'] ?? '',
      isDeleted: data['isDeleted'] ?? false,
      isActive: data['isActive'] != false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'venueId': venueId,
      'title': title,
      'description': description,
      'dateTime': Timestamp.fromDate(startDateTime),
      'startDateTime': Timestamp.fromDate(startDateTime),
      'endDateTime': Timestamp.fromDate(endDateTime),
      'createdAt': Timestamp.fromDate(createdAt),
      'category': category,
      'imageUrl': imageUrl,
      'isDeleted': isDeleted,
      'isActive': isActive,
    };
  }
}
