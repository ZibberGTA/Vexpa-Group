/// Route stop in normalized domain form (no persistence aliases).
final class TrailStop {
  const TrailStop({
    required this.venueId,
    required this.venueName,
    required this.address,
    required this.bannerImageUrl,
    required this.logoUrl,
    required this.order,
    required this.score,
    required this.arriveAt,
    required this.leaveAt,
    this.discountLabel = '',
  });

  final String venueId;
  final String venueName;
  final String address;
  final String bannerImageUrl;
  final String logoUrl;
  final int order;
  final int score;
  final DateTime arriveAt;
  final DateTime leaveAt;
  final String discountLabel;

  TrailStop copyWith({
    String? venueId,
    String? venueName,
    String? address,
    String? bannerImageUrl,
    String? logoUrl,
    int? order,
    int? score,
    DateTime? arriveAt,
    DateTime? leaveAt,
    String? discountLabel,
  }) {
    return TrailStop(
      venueId: venueId ?? this.venueId,
      venueName: venueName ?? this.venueName,
      address: address ?? this.address,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      order: order ?? this.order,
      score: score ?? this.score,
      arriveAt: arriveAt ?? this.arriveAt,
      leaveAt: leaveAt ?? this.leaveAt,
      discountLabel: discountLabel ?? this.discountLabel,
    );
  }
}
