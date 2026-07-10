import 'package:cloud_firestore/cloud_firestore.dart';

class TrailStopView {
  const TrailStopView({
    required this.venueId,
    required this.venueName,
    required this.address,
    required this.order,
    required this.discountLabel,
  });

  final String venueId;
  final String venueName;
  final String address;
  final int order;
  final String discountLabel;
}

class TrailDetailsView {
  const TrailDetailsView({
    required this.id,
    required this.name,
    required this.description,
    required this.bannerImageUrl,
    required this.area,
    required this.estimatedWalkingMinutes,
    required this.estimatedWalkingDistanceMeters,
    required this.stops,
  });

  final String id;
  final String name;
  final String description;
  final String bannerImageUrl;
  final String area;
  final int estimatedWalkingMinutes;
  final int estimatedWalkingDistanceMeters;
  final List<TrailStopView> stops;

  factory TrailDetailsView.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final stopsRaw = data['stops'];
    final stops = stopsRaw is List
        ? stopsRaw
            .whereType<Map>()
            .map((item) {
              final map = Map<String, dynamic>.from(item);
              return TrailStopView(
                venueId: map['venueId']?.toString() ?? '',
                venueName: map['venueName']?.toString() ?? 'Venue',
                address: map['address']?.toString() ?? '',
                order: (map['order'] as num?)?.toInt() ?? 0,
                discountLabel: map['discountLabel']?.toString() ?? '',
              );
            })
            .toList()
        : <TrailStopView>[];
    stops.sort((a, b) => a.order.compareTo(b.order));

    final durationMinutes = (data['estimatedDurationMinutes'] as num?)?.toInt();
    final walkingDistance =
        (data['estimatedWalkingDistance'] as num?)?.toInt() ?? 0;

    return TrailDetailsView(
      id: doc.id,
      name: (data['name'] ?? data['title'] ?? "Tonight's Trail").toString(),
      description: (data['description'] ?? data['subtitle'] ?? '').toString(),
      bannerImageUrl: (data['bannerImageUrl'] ?? data['bannerUrl'] ?? '').toString(),
      area: (data['area'] ?? data['city'] ?? '').toString(),
      estimatedWalkingMinutes: durationMinutes ?? (stops.length * 25),
      estimatedWalkingDistanceMeters: walkingDistance,
      stops: stops,
    );
  }
}
