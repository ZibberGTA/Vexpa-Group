import 'package:cloud_firestore/cloud_firestore.dart';

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

  bool get isLiveOrUpcoming =>
      !isDeleted && isActive && endDateTime.isAfter(DateTime.now());

  String get formattedDate {
    final day = startDateTime.day.toString().padLeft(2, '0');
    final month = startDateTime.month.toString().padLeft(2, '0');
    return '$day/$month/${startDateTime.year}';
  }

  String get formattedTime {
    final hour = startDateTime.hour.toString().padLeft(2, '0');
    final minute = startDateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  factory EventModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    final start = (data['startDateTime'] as Timestamp?)?.toDate() ??
        (data['dateTime'] as Timestamp?)?.toDate() ??
        DateTime.now();

    final end = (data['endDateTime'] as Timestamp?)?.toDate() ??
        start.add(const Duration(hours: 4));

    return EventModel(
      id: doc.id,
      venueId: data['venueId']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      startDateTime: start,
      endDateTime: end,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      category: data['category']?.toString() ?? 'General',
      imageUrl: data['imageUrl']?.toString() ?? '',
      isDeleted: data['isDeleted'] == true,
      artist: (data['artist'] ?? data['artistName'] ?? '').toString(),
      isActive: data['isActive'] != false,
      featured: data['featured'] == true,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
