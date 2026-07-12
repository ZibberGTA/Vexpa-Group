import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vex_engines/experience/application/experience_event_visibility.dart';
import 'package:vex_engines/experience/application/venue_presentation_support.dart';

const _presentation = VenuePresentationSupport();

class EventModel {
  const EventModel({
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
    this.artist = '',
    this.isActive = true,
    this.featured = false,
    this.updatedAt,
  });

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
  final String artist;
  final bool isActive;
  final bool featured;
  final DateTime? updatedAt;

  DateTime get dateTime => startDateTime;

  bool get isLiveOrUpcoming => ExperienceEventVisibility.isPublicVisible(
        isDeleted: isDeleted,
        isActive: isActive,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
      );

  String get formattedDate => _presentation.formatDateOnly(startDateTime);

  String get formattedTime => _presentation.formatTimeOnly(startDateTime);

  factory EventModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return EventModel.fromMap(doc.id, doc.data() ?? {});
  }

  factory EventModel.fromMap(String id, Map<String, dynamic> data) {
    final start =
        _dateFromValue(data['startDateTime']) ??
        _dateFromValue(data['dateTime']) ??
        DateTime.now();

    final end =
        _dateFromValue(data['endDateTime']) ??
        _presentation.defaultEventEndDateTime(start);

    return EventModel(
      id: id,
      venueId: data['venueId']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      startDateTime: start,
      endDateTime: end,
      createdAt: _dateFromValue(data['createdAt']) ?? DateTime.now(),
      category: data['category']?.toString() ?? 'General',
      imageUrl: data['imageUrl']?.toString() ?? '',
      isDeleted: data['isDeleted'] == true,
      artist: (data['artist'] ?? data['artistName'] ?? '').toString(),
      isActive: data['isActive'] != false,
      featured: data['featured'] == true,
      updatedAt: _dateFromValue(data['updatedAt']),
    );
  }

  static DateTime? _dateFromValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
