import '../shared/experience_gallery_categories.dart';
import 'experience_deal_scheduling.dart';

/// Engine-neutral formatting and labels for web and mobile presentation.
final class VenuePresentationSupport {
  const VenuePresentationSupport();

  static const _weekdayLabels = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const _monthLabels = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  bool hasValidPrice(double price) {
    if (price.isNaN || !price.isFinite) return false;
    return price > 0;
  }

  String formatPrice(double price) =>
      hasValidPrice(price) ? '£${price.toStringAsFixed(2)}' : '—';

  String exportPriceValue(double price) =>
      hasValidPrice(price) ? price.toStringAsFixed(2) : '';

  String formatDateOnly(DateTime? date) {
    if (date == null) return '—';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String formatTimeOnly(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String formatDateTimeCompact(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }

  String formatDisplayValue(String value) =>
      value.trim().isEmpty ? '—' : value.trim();

  String dealExpiryLabel({
    required DateTime? endDateTime,
    required String endTime,
    required DateTime? effectiveEndDateTime,
    required bool isFutureStart,
    DateTime? now,
  }) {
    final end = effectiveEndDateTime ??
        ExperienceDealScheduling.resolveEffectiveEndDateTime(
          endDateTime: endDateTime,
          endTime: endTime,
          now: now,
        );
    if (end == null) {
      if (endTime.isNotEmpty) return 'Until $endTime';
      return 'Active now';
    }
    if (isFutureStart) return 'Starts ${formatDateTimeCompact(end)}';
    return 'Ends ${formatDateTimeCompact(end)}';
  }

  /// Customer-facing start label for upcoming deals/events.
  String formatUpcomingStartLabel(DateTime start, {DateTime? now}) {
    final clock = now ?? DateTime.now();
    final weekday = _weekdayLabels[start.weekday - 1];
    final hour = start.hour % 12 == 0 ? 12 : start.hour % 12;
    final minute = start.minute.toString().padLeft(2, '0');
    final period = start.hour >= 12 ? 'PM' : 'AM';
    final timeLabel = '$hour:$minute $period';

    final daysUntil = DateTime(start.year, start.month, start.day)
        .difference(DateTime(clock.year, clock.month, clock.day))
        .inDays;

    if (daysUntil >= 0 && daysUntil <= 6) {
      return 'Starts $weekday at $timeLabel';
    }

    return 'Available from ${start.day} ${_monthLabels[start.month - 1]}';
  }

  String galleryCategoryLabel(String category) =>
      ExperienceGalleryCategories.label(category);

  String relativeTimeLabel(DateTime timestamp, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatDateOnly(timestamp);
  }

  /// Management table timestamps — long-form labels preserved for owner UI.
  String managementRelativeTimeLabel(DateTime timestamp, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return formatDateOnly(timestamp);
  }

  double? parsePriceValue(dynamic rawPrice) {
    if (rawPrice == null) return null;
    if (rawPrice is num) return rawPrice.toDouble();
    return double.tryParse(rawPrice.toString().trim());
  }

  /// Plain price text without currency symbol (mobile list rows).
  String formatPricePlainFromRaw(dynamic rawPrice) {
    final parsed = parsePriceValue(rawPrice);
    if (parsed == null || !hasValidPrice(parsed)) return '';
    return parsed.toStringAsFixed(2);
  }

  /// Normalises venue feature tag labels for map cards and previews.
  String formatVenueTagLabel(String tag) {
    final cleaned = tag.trim();
    if (cleaned.isEmpty) return '';

    final normalized = cleaned
        .replaceAll('-', '')
        .replaceAll('_', '')
        .replaceAll(' ', '')
        .toLowerCase();

    return switch (normalized) {
      '18+' || '18plus' || 'age18' || 'age18plus' => '18+',
      '21+' || '21plus' || 'age21' || 'age21plus' => '21+',
      'livemusic' => 'Live Music',
      'dj' => 'DJ',
      'sports' => 'Sports',
      'karaoke' => 'Karaoke',
      'quiz' || 'quiznight' => 'Quiz Night',
      'dancefloor' => 'Dance Floor',
      'foodserved' => 'Food Served',
      'outdoor' || 'outdoorseating' => 'Outdoor Seating',
      _ => _titleCaseTag(cleaned),
    };
  }

  String _titleCaseTag(String cleaned) {
    final withSpaces = cleaned
        .replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])'), (_) => ' ')
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .trim();
    return withSpaces
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) => part.length == 1
              ? part.toUpperCase()
              : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String formatEventDateTimeLabel(DateTime dateTime) {
    return '${formatDateOnly(dateTime)} ${formatTimeOnly(dateTime)}';
  }

  /// Default event end when Firestore document omits endDateTime.
  DateTime defaultEventEndDateTime(DateTime start) =>
      start.add(const Duration(hours: 4));

  /// Public gallery cap and non-empty URL filter.
  List<T> publicGalleryImages<T>({
    required Iterable<T> images,
    required String Function(T image) imageUrl,
    int limit = ExperienceGalleryCategories.publicDisplayLimit,
  }) {
    return images
        .where((image) => imageUrl(image).trim().isNotEmpty)
        .take(limit)
        .toList();
  }

  /// Builds legacy gallery rows from plain URL list when rich metadata absent.
  List<ExperienceLegacyGalleryImage> legacyGalleryFromUrls(List<String> urls) {
    return urls
        .where((url) => url.trim().isNotEmpty)
        .toList()
        .asMap()
        .entries
        .map(
          (entry) => ExperienceLegacyGalleryImage(
            id: 'legacy-${entry.key}',
            imageUrl: entry.value,
            thumbnailUrl: entry.value,
            category: entry.key == 0 ? 'cover' : 'other',
            isCover: entry.key == 0,
            sortOrder: entry.key,
          ),
        )
        .toList();
  }
}

final class ExperienceLegacyGalleryImage {
  const ExperienceLegacyGalleryImage({
    required this.id,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.category,
    required this.isCover,
    required this.sortOrder,
  });

  final String id;
  final String imageUrl;
  final String thumbnailUrl;
  final String category;
  final bool isCover;
  final int sortOrder;
}
