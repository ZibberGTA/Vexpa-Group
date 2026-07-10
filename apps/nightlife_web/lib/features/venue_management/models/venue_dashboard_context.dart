import '../../auth/services/auth_service.dart';
import '../../venues/data/venue_image_field_parser.dart';

/// Active venue and owner context shown in the dashboard shell.
class VenueDashboardContext {
  const VenueDashboardContext({
    required this.ownerName,
    required this.ownerFirstName,
    required this.venueName,
    required this.venueId,
    this.logoUrl,
    this.bannerImageUrl,
    this.unreadNotifications = 0,
    this.availableVenueIds = const [],
  });

  final String ownerName;
  final String? ownerFirstName;
  final String venueName;
  final String venueId;
  final String? logoUrl;
  final String? bannerImageUrl;
  final int unreadNotifications;
  final List<String> availableVenueIds;

  String get initials {
    final words = venueName.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words.first[0]}${words[1][0]}'.toUpperCase();
    }
    if (words.isNotEmpty && words.first.isNotEmpty) {
      return words.first.substring(0, 1).toUpperCase();
    }
    return 'V';
  }

  /// Test-only placeholder — do not use in production screens.
  factory VenueDashboardContext.placeholder() {
    final user = AuthService.currentUser;
    final ownerName = user == null
        ? 'Alex Morgan'
        : AuthService.getDisplayName(user);

    return VenueDashboardContext(
      ownerName: ownerName,
      ownerFirstName: 'Alex',
      venueName: 'The Copper Lantern',
      venueId: 'demo-venue-copper-lantern',
      unreadNotifications: 0,
    );
  }

  VenueDashboardContext copyWith({
    String? ownerName,
    String? ownerFirstName,
    String? venueName,
    String? venueId,
    String? logoUrl,
    bool clearLogoUrl = false,
    String? bannerImageUrl,
    bool clearBannerImageUrl = false,
    int? unreadNotifications,
    List<String>? availableVenueIds,
  }) {
    return VenueDashboardContext(
      ownerName: ownerName ?? this.ownerName,
      ownerFirstName: ownerFirstName ?? this.ownerFirstName,
      venueName: venueName ?? this.venueName,
      venueId: venueId ?? this.venueId,
      logoUrl: clearLogoUrl ? null : (logoUrl ?? this.logoUrl),
      bannerImageUrl: clearBannerImageUrl
          ? null
          : (bannerImageUrl ?? this.bannerImageUrl),
      unreadNotifications: unreadNotifications ?? this.unreadNotifications,
      availableVenueIds: availableVenueIds ?? this.availableVenueIds,
    );
  }

  /// Merges live venue document branding fields for sidebar and shell UI.
  VenueDashboardContext withVenueDocument(Map<String, dynamic>? data) {
    if (data == null) return this;

    final logo = VenueImageFieldParser.resolveVenueLogoUrl(data);
    final banner = VenueImageFieldParser.resolveVenueBannerUrl(data);
    final name = (data['name'] ?? '').toString().trim();

    return copyWith(
      venueName: name.isNotEmpty ? name : venueName,
      logoUrl: logo.isEmpty ? null : logo,
      clearLogoUrl: logo.isEmpty,
      bannerImageUrl: banner.isEmpty ? null : banner,
      clearBannerImageUrl: banner.isEmpty,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is VenueDashboardContext &&
        other.ownerName == ownerName &&
        other.ownerFirstName == ownerFirstName &&
        other.venueName == venueName &&
        other.venueId == venueId &&
        other.logoUrl == logoUrl &&
        other.bannerImageUrl == bannerImageUrl &&
        other.unreadNotifications == unreadNotifications &&
        _listEquals(other.availableVenueIds, availableVenueIds);
  }

  @override
  int get hashCode => Object.hash(
    ownerName,
    ownerFirstName,
    venueName,
    venueId,
    logoUrl,
    bannerImageUrl,
    unreadNotifications,
    Object.hashAll(availableVenueIds),
  );
}

bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
