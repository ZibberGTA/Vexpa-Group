import '../../home/models/venue_model.dart';

class StartupData {
  const StartupData({
    required this.venues,
    required this.nearbyVenues,
    required this.locationLoaded,
    this.warningMessage,
    this.userLatitude,
    this.userLongitude,
  });

  final List<VenueModel> venues;
  final List<VenueModel> nearbyVenues;
  final bool locationLoaded;
  final String? warningMessage;
  final double? userLatitude;
  final double? userLongitude;

  bool get hasWarning => warningMessage != null && warningMessage!.isNotEmpty;
  bool get hasUserLocation => userLatitude != null && userLongitude != null;
}
