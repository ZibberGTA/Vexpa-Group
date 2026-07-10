import 'package:cloud_firestore/cloud_firestore.dart';

import '../../venues/models/image_position_metadata.dart';
import 'media_library_tab.dart';
import 'venue_media_type.dart';

/// Firestore media document for venues/{venueId}/media/{mediaId}.
class VenueMediaItem {
  const VenueMediaItem({
    required this.id,
    required this.venueId,
    required this.mediaType,
    required this.imageUrl,
    this.thumbnailUrl,
    this.fileName = '',
    this.contentType = '',
    this.sizeBytes = 0,
    this.uploadedByUid = '',
    this.linkedDealId,
    this.linkedEventId,
    this.linkedLabel,
    this.category = 'other',
    this.caption = '',
    this.status = 'active',
    this.visible = true,
    this.featured = false,
    this.isCurrent = false,
    this.sortOrder = 0,
    this.crop,
    this.uploadedAt,
    this.updatedAt,
    this.storagePath,
    this.isLegacy = false,
  });

  final String id;
  final String venueId;
  final VenueMediaType mediaType;
  final String imageUrl;
  final String? thumbnailUrl;
  final String fileName;
  final String contentType;
  final int sizeBytes;
  final String uploadedByUid;
  final String? linkedDealId;
  final String? linkedEventId;
  final String? linkedLabel;
  final String category;
  final String caption;
  final String status;
  final bool visible;
  final bool featured;
  final bool isCurrent;
  final int sortOrder;
  final VenueMediaCropMetadata? crop;
  final DateTime? uploadedAt;
  final DateTime? updatedAt;
  final String? storagePath;
  final bool isLegacy;

  /// Backward-compatible alias used by existing gallery UI.
  String get url => imageUrl;

  MediaLibraryTab? get libraryTab => mediaType.libraryTab;

  ImagePositionMetadata? get position => crop?.toPositionMetadata();

  bool get isCover => featured && mediaType == VenueMediaType.gallery;

  bool get isActive => status == 'active' && visible;

  String get displayName {
    if (fileName.trim().isNotEmpty) return fileName;
    if (linkedLabel != null && linkedLabel!.trim().isNotEmpty) {
      return linkedLabel!;
    }
    return '${mediaType.label} ${id.substring(0, id.length.clamp(0, 8))}';
  }

  String get previewUrl {
    final thumb = thumbnailUrl?.trim();
    if (thumb != null && thumb.isNotEmpty) return thumb;
    return imageUrl;
  }

  bool get hasLoadableUrl => previewUrl.trim().isNotEmpty;

  VenueMediaItem copyWith({
    String? imageUrl,
    String? thumbnailUrl,
    String? fileName,
    String? contentType,
    int? sizeBytes,
    String? uploadedByUid,
    String? linkedLabel,
    String? category,
    String? caption,
    String? status,
    bool? visible,
    bool? featured,
    bool? isCurrent,
    int? sortOrder,
    VenueMediaCropMetadata? crop,
    DateTime? uploadedAt,
    DateTime? updatedAt,
    String? storagePath,
  }) {
    return VenueMediaItem(
      id: id,
      venueId: venueId,
      mediaType: mediaType,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      fileName: fileName ?? this.fileName,
      contentType: contentType ?? this.contentType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      uploadedByUid: uploadedByUid ?? this.uploadedByUid,
      linkedDealId: linkedDealId,
      linkedEventId: linkedEventId,
      linkedLabel: linkedLabel ?? this.linkedLabel,
      category: category ?? this.category,
      caption: caption ?? this.caption,
      status: status ?? this.status,
      visible: visible ?? this.visible,
      featured: featured ?? this.featured,
      isCurrent: isCurrent ?? this.isCurrent,
      sortOrder: sortOrder ?? this.sortOrder,
      crop: crop ?? this.crop,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      storagePath: storagePath ?? this.storagePath,
      isLegacy: isLegacy,
    );
  }

  Map<String, dynamic> toMap({
    FieldValue? uploadedAtField,
    FieldValue? updatedAtField,
  }) {
    return {
      'venueId': venueId,
      'mediaId': id,
      'mediaType': mediaType.firestoreValue,
      'imageUrl': imageUrl,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      if (fileName.isNotEmpty) 'fileName': fileName,
      if (contentType.isNotEmpty) 'contentType': contentType,
      if (sizeBytes > 0) 'sizeBytes': sizeBytes,
      if (uploadedByUid.isNotEmpty) 'uploadedByUid': uploadedByUid,
      if (linkedDealId != null) 'linkedDealId': linkedDealId,
      if (linkedEventId != null) 'linkedEventId': linkedEventId,
      if (linkedLabel != null) 'linkedLabel': linkedLabel,
      if (category.isNotEmpty) 'category': category,
      if (caption.isNotEmpty) 'caption': caption,
      'status': status,
      'visible': visible,
      'featured': featured,
      if (mediaType == VenueMediaType.logo ||
          mediaType == VenueMediaType.banner)
        'isCurrent': isCurrent,
      'sortOrder': sortOrder,
      if (crop != null) ...crop!.toMap(),
      if (storagePath != null) 'storagePath': storagePath,
      'uploadedAt':
          uploadedAtField ??
          (uploadedAt != null
              ? Timestamp.fromDate(uploadedAt!)
              : FieldValue.serverTimestamp()),
      'updatedAt': updatedAtField ?? FieldValue.serverTimestamp(),
    };
  }

  factory VenueMediaItem.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    final mediaType =
        VenueMediaTypeX.fromFirestore(map['mediaType']?.toString()) ??
        _legacyMediaType(map);

    return VenueMediaItem(
      id: id,
      venueId: map['venueId']?.toString() ?? '',
      mediaType: mediaType,
      imageUrl: map['imageUrl']?.toString() ?? map['url']?.toString() ?? '',
      thumbnailUrl: map['thumbnailUrl']?.toString(),
      fileName: map['fileName']?.toString() ?? '',
      contentType: map['contentType']?.toString() ?? '',
      sizeBytes: map['sizeBytes'] is num
          ? (map['sizeBytes'] as num).toInt()
          : 0,
      uploadedByUid: map['uploadedByUid']?.toString() ?? '',
      linkedDealId: map['linkedDealId']?.toString(),
      linkedEventId: map['linkedEventId']?.toString(),
      linkedLabel: map['linkedLabel']?.toString(),
      category: _normalizeCategory(map['category']?.toString()),
      caption: map['caption']?.toString() ?? '',
      status: _normalizeStatus(map['status']?.toString()),
      visible:
          map['visible'] != false &&
          _normalizeStatus(map['status']?.toString()) == 'active',
      featured: map['featured'] == true || map['isCover'] == true,
      isCurrent: map['isCurrent'] == true,
      sortOrder: map['sortOrder'] is num
          ? (map['sortOrder'] as num).toInt()
          : int.tryParse(map['sortOrder']?.toString() ?? '') ?? 0,
      crop: _readCrop(map),
      uploadedAt: _dateFromValue(map['uploadedAt']),
      updatedAt: _dateFromValue(map['updatedAt']),
      storagePath: map['storagePath']?.toString(),
    );
  }

  static String _normalizeCategory(String? value) {
    final normalized = value?.trim().toLowerCase().replaceAll(' ', '_') ?? '';
    return switch (normalized) {
      'cover' || 'hero' || 'hero_image' => 'cover',
      'interior' => 'interior',
      'drinks' || 'drink' => 'drinks',
      'food' => 'food',
      'events' || 'event' => 'events',
      'atmosphere' || 'ambience' || 'ambiance' => 'atmosphere',
      _ => 'other',
    };
  }

  static String _normalizeStatus(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';
    return switch (normalized) {
      'hidden' => 'hidden',
      'deleted' => 'deleted',
      _ => 'active',
    };
  }

  static VenueMediaType _legacyMediaType(Map<String, dynamic> map) {
    final libraryType = map['libraryType']?.toString() ?? '';
    return switch (libraryType) {
      'dealImages' => VenueMediaType.deal,
      'eventImages' => VenueMediaType.event,
      'venueGallery' => VenueMediaType.gallery,
      _ => VenueMediaType.gallery,
    };
  }

  static VenueMediaCropMetadata? _readCrop(Map<String, dynamic> map) {
    final position = map['position'];
    if (position is Map) {
      return VenueMediaCropMetadata.fromMap(
        Map<String, dynamic>.from(position),
      );
    }
    if (map.containsKey('focalPointX') || map.containsKey('cropX')) {
      return VenueMediaCropMetadata.fromMap(map);
    }
    return null;
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
