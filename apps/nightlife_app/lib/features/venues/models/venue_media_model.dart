import 'package:cloud_firestore/cloud_firestore.dart';

enum VenueMediaType { logo, banner, gallery, deal, event }

VenueMediaType venueMediaTypeFromFirestore(String? value) {
  switch (value) {
    case 'logo':
      return VenueMediaType.logo;
    case 'banner':
      return VenueMediaType.banner;
    case 'gallery':
      return VenueMediaType.gallery;
    case 'deal':
      return VenueMediaType.deal;
    case 'event':
      return VenueMediaType.event;
    default:
      return VenueMediaType.gallery;
  }
}

class VenueMediaModel {
  final String id;
  final String venueId;
  final VenueMediaType mediaType;
  final String imageUrl;
  final bool visible;
  final bool featured;
  final bool isCurrent;
  final int sortOrder;
  final String? linkedDealId;
  final String? linkedEventId;
  final DateTime? uploadedAt;

  const VenueMediaModel({
    required this.id,
    required this.venueId,
    required this.mediaType,
    required this.imageUrl,
    this.visible = true,
    this.featured = false,
    this.isCurrent = false,
    this.sortOrder = 0,
    this.linkedDealId,
    this.linkedEventId,
    this.uploadedAt,
  });

  factory VenueMediaModel.fromMap(String id, Map<String, dynamic> map) {
    return VenueMediaModel(
      id: id,
      venueId: (map['venueId'] ?? '').toString(),
      mediaType: venueMediaTypeFromFirestore(map['mediaType']?.toString()),
      imageUrl: (map['imageUrl'] ?? '').toString(),
      visible: map['visible'] != false,
      featured: map['featured'] == true || map['isCover'] == true,
      isCurrent: map['isCurrent'] == true,
      sortOrder: map['sortOrder'] is num ? (map['sortOrder'] as num).toInt() : 0,
      linkedDealId: map['linkedDealId']?.toString(),
      linkedEventId: map['linkedEventId']?.toString(),
      uploadedAt: _parseDate(map['uploadedAt']),
    );
  }

  factory VenueMediaModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return VenueMediaModel.fromMap(doc.id, doc.data() ?? const {});
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

class VenueMediaBundle {
  final VenueMediaModel? currentLogo;
  final VenueMediaModel? currentBanner;
  final List<VenueMediaModel> galleryItems;
  final List<VenueMediaModel> dealImages;
  final List<VenueMediaModel> eventImages;

  const VenueMediaBundle({
    this.currentLogo,
    this.currentBanner,
    this.galleryItems = const [],
    this.dealImages = const [],
    this.eventImages = const [],
  });

  factory VenueMediaBundle.empty() => const VenueMediaBundle();

  factory VenueMediaBundle.fromItems(List<VenueMediaModel> items) {
    VenueMediaModel? currentLogo;
    VenueMediaModel? currentBanner;
    final gallery = <VenueMediaModel>[];
    final deals = <VenueMediaModel>[];
    final events = <VenueMediaModel>[];

    for (final item in items) {
      if (!item.visible) continue;
      switch (item.mediaType) {
        case VenueMediaType.logo:
          if (item.isCurrent) currentLogo = item;
          break;
        case VenueMediaType.banner:
          if (item.isCurrent) currentBanner = item;
          break;
        case VenueMediaType.gallery:
          gallery.add(item);
          break;
        case VenueMediaType.deal:
          deals.add(item);
          break;
        case VenueMediaType.event:
          events.add(item);
          break;
      }
    }

    gallery.sort(_gallerySort);
    deals.sort(_gallerySort);
    events.sort(_gallerySort);

    return VenueMediaBundle(
      currentLogo: currentLogo,
      currentBanner: currentBanner,
      galleryItems: gallery,
      dealImages: deals,
      eventImages: events,
    );
  }

  static int _gallerySort(VenueMediaModel a, VenueMediaModel b) {
    if (a.featured != b.featured) return a.featured ? -1 : 1;
    final order = a.sortOrder.compareTo(b.sortOrder);
    if (order != 0) return order;
    final aTime = a.uploadedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime = b.uploadedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return aTime.compareTo(bTime);
  }
}
