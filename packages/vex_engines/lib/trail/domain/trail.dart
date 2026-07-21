import 'trail_status.dart';
import 'trail_stop.dart';
import 'trail_type.dart';
import 'participation/trail_participation_settings.dart';

/// Normalized trail aggregate used by VexTrail policies.
final class Trail {
  const Trail({
    required this.id,
    required this.name,
    required this.description,
    required this.bannerImageUrl,
    required this.status,
    required this.published,
    required this.area,
    required this.availabilityStart,
    required this.availabilityEnd,
    required this.estimatedDurationMinutes,
    required this.estimatedWalkingDistance,
    required this.averageRating,
    required this.venueCount,
    required this.trailType,
    required this.generatedAt,
    required this.stops,
    this.participationSettings = const TrailParticipationSettings(),
  });

  final String id;
  final String name;
  final String description;
  final String bannerImageUrl;
  final TrailStatus status;
  final bool published;
  final String area;
  final DateTime availabilityStart;
  final DateTime availabilityEnd;
  final int estimatedDurationMinutes;
  final int estimatedWalkingDistance;
  final double averageRating;
  final int venueCount;
  final TrailType trailType;
  final DateTime generatedAt;
  final List<TrailStop> stops;
  final TrailParticipationSettings participationSettings;

  bool get isPublishedLike => status == TrailStatus.published || published;

  int get effectiveVenueCount => stops.isNotEmpty ? stops.length : venueCount;

  Trail copyWith({
    String? id,
    String? name,
    String? description,
    String? bannerImageUrl,
    TrailStatus? status,
    bool? published,
    String? area,
    DateTime? availabilityStart,
    DateTime? availabilityEnd,
    int? estimatedDurationMinutes,
    int? estimatedWalkingDistance,
    double? averageRating,
    int? venueCount,
    TrailType? trailType,
    DateTime? generatedAt,
    List<TrailStop>? stops,
    TrailParticipationSettings? participationSettings,
  }) {
    return Trail(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      status: status ?? this.status,
      published: published ?? this.published,
      area: area ?? this.area,
      availabilityStart: availabilityStart ?? this.availabilityStart,
      availabilityEnd: availabilityEnd ?? this.availabilityEnd,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      estimatedWalkingDistance:
          estimatedWalkingDistance ?? this.estimatedWalkingDistance,
      averageRating: averageRating ?? this.averageRating,
      venueCount: venueCount ?? this.venueCount,
      trailType: trailType ?? this.trailType,
      generatedAt: generatedAt ?? this.generatedAt,
      stops: stops ?? this.stops,
      participationSettings:
          participationSettings ?? this.participationSettings,
    );
  }
}
