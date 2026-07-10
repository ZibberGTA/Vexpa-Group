import 'package:cloud_firestore/cloud_firestore.dart';

class CrowdDecay {
  static const levels = [
    'quiet',
    'steady',
    'medium',
    'busy',
    'packed',
  ];

  /// Returns the internal crowd level after time-based decay.
  ///
  /// Decay timing:
  /// - 0 to 3 hours: no change
  /// - 3 to 5 hours: drop 1 level
  /// - 5 to 7 hours: drop 2 levels
  /// - 7+ hours: relaxed/quiet
  static String displayLevel({
    required String level,
    required dynamic updatedAt,
  }) {
    final cleanLevel = _normaliseLevel(level);

    final originalIndex = levels.indexOf(cleanLevel);

    if (originalIndex <= 0) {
      return cleanLevel.isEmpty ? 'quiet' : cleanLevel;
    }

    if (updatedAt is! Timestamp) {
      return cleanLevel;
    }

    final updatedTime = updatedAt.toDate();
    final ageMinutes = DateTime.now().difference(updatedTime).inMinutes;

    int drop = 0;

    if (ageMinutes >= 420) {
      return 'quiet';
    } else if (ageMinutes >= 300) {
      drop = 2;
    } else if (ageMinutes >= 180) {
      drop = 1;
    }

    final newIndex = (originalIndex - drop).clamp(0, levels.length - 1);

    return levels[newIndex];
  }

  /// Converts an internal crowd level into customer-friendly wording.
  static String labelForLevel(String level) {
    switch (_normaliseLevel(level)) {
      case 'quiet':
        return 'Relaxed';
      case 'steady':
      case 'medium':
        return 'Steady';
      case 'busy':
        return 'Buzzing';
      case 'packed':
        return 'Lively';
      default:
        return level.trim().isEmpty ? 'Relaxed' : level;
    }
  }

  /// Returns the customer-friendly label after applying decay.
  static String displayLabel({
    required String level,
    required dynamic updatedAt,
  }) {
    return labelForLevel(
      displayLevel(
        level: level,
        updatedAt: updatedAt,
      ),
    );
  }

  static int scoreForLevel(String level) {
    switch (_normaliseLevel(level)) {
      case 'quiet':
        return 1;
      case 'steady':
        return 2;
      case 'medium':
        return 3;
      case 'busy':
        return 4;
      case 'packed':
        return 5;
      default:
        return 1;
    }
  }

  static String levelForScore(int score) {
    if (score >= 5) return 'packed';
    if (score == 4) return 'busy';
    if (score == 3) return 'medium';
    if (score == 2) return 'steady';
    return 'quiet';
  }

  static String _normaliseLevel(String level) {
    switch (level.toLowerCase().trim()) {
      case 'relaxed':
        return 'quiet';
      case 'steady':
        return 'steady';
      case 'medium':
        return 'medium';
      case 'buzzing':
        return 'busy';
      case 'busy':
        return 'busy';
      case 'lively':
        return 'packed';
      case 'packed':
        return 'packed';
      case 'quiet':
        return 'quiet';
      default:
        return level.toLowerCase().trim();
    }
  }
}
