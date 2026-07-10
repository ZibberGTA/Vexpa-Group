class DistanceFormatter {
  const DistanceFormatter._();

  static const int _metersPerMileThreshold = 1609;
  static const double _metersPerMile = 1609.344;

  static String formatMeters(num meters) {
    final roundedMeters = meters.round();
    if (roundedMeters < _metersPerMileThreshold) {
      return '$roundedMeters m';
    }

    final miles = meters / _metersPerMile;
    return '${miles.toStringAsFixed(1)} mi';
  }
}
