import '../shared/experience_drink_categories.dart';
import '../shared/experience_search_term_builder.dart';
import 'experience_scheduling_utils.dart';
import 'experience_write_preparation.dart';

/// Owner write validation and field preparation for mobile and shared surfaces.
///
/// Mobile-specific paths preserve legacy Firestore field shapes and search-term
/// algorithms used before engine adoption.
final class ExperienceOwnerWriteService {
  const ExperienceOwnerWriteService();

  // ---------------------------------------------------------------------------
  // Mobile deal defaults (legacy schema)
  // ---------------------------------------------------------------------------

  static const mobileDealType = 'drink_offer';

  static List<String> mobileDealSearchTerms({
    required String title,
    required String description,
    required String venueName,
    required String startTime,
    required String endTime,
  }) {
    return {
      title.toLowerCase(),
      description.toLowerCase(),
      venueName.toLowerCase(),
      ...title.toLowerCase().split(' '),
      ...description.toLowerCase().split(' '),
      if (startTime.isNotEmpty) startTime.toLowerCase(),
      if (endTime.isNotEmpty) endTime.toLowerCase(),
    }.where((term) => term.trim().isNotEmpty).toList();
  }

  static Map<String, dynamic> mobileDealCreateFields({
    required String venueId,
    required String venueName,
    required String title,
    required String description,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required String startTime,
    required String endTime,
  }) {
    final trimmedTitle = title.trim();
    final trimmedDescription = description.trim();
    final trimmedStartTime = startTime.trim();
    final trimmedEndTime = endTime.trim();

    return {
      'venueId': venueId,
      'venueName': venueName,
      'title': trimmedTitle,
      'description': trimmedDescription,
      'dealType': mobileDealType,
      'startTime': trimmedStartTime,
      'endTime': trimmedEndTime,
      'startDateTime': startDateTime,
      'endDateTime': endDateTime,
      'isActive': true,
      'isDeleted': false,
      'searchTerms': mobileDealSearchTerms(
        title: trimmedTitle,
        description: trimmedDescription,
        venueName: venueName,
        startTime: trimmedStartTime,
        endTime: trimmedEndTime,
      ),
    };
  }

  static Map<String, dynamic> mobileDealUpdateFields({
    required String title,
    required String description,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required String startTime,
    required String endTime,
  }) {
    return {
      'title': title.trim(),
      'description': description.trim(),
      'startTime': startTime.trim(),
      'endTime': endTime.trim(),
      'startDateTime': startDateTime,
      'endDateTime': endDateTime,
      'isActive': true,
    };
  }

  // ---------------------------------------------------------------------------
  // Mobile preset drink create (legacy schema)
  // ---------------------------------------------------------------------------

  static Map<String, dynamic> mobilePresetDrinkCreateFields({
    required String venueId,
    required String venueName,
    required String drinkName,
    required String categoryDisplayName,
    double? price,
  }) {
    final normalizedCategory = ExperienceDrinkCategories.normalize(categoryDisplayName);

    return {
      'venueId': venueId,
      'venueName': venueName,
      'name': drinkName,
      'category': normalizedCategory,
      'price': price,
      'description': '',
      'available': true,
      'isDeleted': false,
      'isPresetDrink': true,
      'searchTerms': ExperienceSearchTermBuilder.buildFromValues([
        drinkName,
        categoryDisplayName,
        venueName,
      ]),
    };
  }

  // ---------------------------------------------------------------------------
  // Mobile drink edit (legacy schema — price stored as entered string)
  // ---------------------------------------------------------------------------

  static Map<String, dynamic> mobileDrinkEditFields({
    required String name,
    required String category,
    required String price,
    required String description,
  }) {
    return {
      'name': name.trim(),
      'category': category.trim(),
      'price': price.trim(),
      'description': description.trim(),
    };
  }

  // ---------------------------------------------------------------------------
  // Mobile event create (legacy schema)
  // ---------------------------------------------------------------------------

  static Map<String, dynamic> mobileEventCreateFields({
    required String venueId,
    required String title,
    required String description,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required String category,
    required String imageUrl,
  }) {
    return {
      'venueId': venueId,
      'title': title.trim(),
      'description': description.trim(),
      'dateTime': startDateTime,
      'startDateTime': startDateTime,
      'endDateTime': endDateTime,
      'category': category,
      'imageUrl': imageUrl.trim(),
      'isDeleted': false,
      'notificationSent': false,
    };
  }

  static DateTime defaultMobileEventEnd({
    required DateTime start,
    Duration fallback = const Duration(hours: 4),
  }) =>
      start.add(fallback);

  // ---------------------------------------------------------------------------
  // Shared / web write preparation passthrough
  // ---------------------------------------------------------------------------

  static Map<String, dynamic> drinkCreateFields({
    required String venueId,
    required String venueName,
    required String name,
    required String category,
    required String description,
    required bool available,
    required bool featured,
    required String createdBy,
    double? price,
  }) =>
      ExperienceWritePreparation.drinkCreateFields(
        venueId: venueId,
        venueName: venueName,
        name: name,
        category: category,
        description: description,
        available: available,
        featured: featured,
        createdBy: createdBy,
        price: price,
      );

  static Map<String, dynamic> drinkUpdateFields({
    required String venueName,
    required String name,
    required String category,
    required String description,
    required bool available,
    required bool featured,
    required String updatedBy,
    double? price,
  }) =>
      ExperienceWritePreparation.drinkUpdateFields(
        venueName: venueName,
        name: name,
        category: category,
        description: description,
        available: available,
        featured: featured,
        updatedBy: updatedBy,
        price: price,
      );

  static Map<String, dynamic> dealCreateFields({
    required String venueId,
    required String venueName,
    required String title,
    required String description,
    required String dealType,
    required String value,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required List<String> availableDays,
    required String startTime,
    required String endTime,
    required bool isActive,
    required bool featured,
    required String createdBy,
  }) =>
      ExperienceWritePreparation.dealCreateFields(
        venueId: venueId,
        venueName: venueName,
        title: title,
        description: description,
        dealType: dealType,
        value: value,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        availableDays: availableDays,
        startTime: startTime,
        endTime: endTime,
        isActive: isActive,
        featured: featured,
        createdBy: createdBy,
      );

  static Map<String, dynamic> eventCreateFields({
    required String venueId,
    required String venueName,
    required String title,
    required String description,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required bool isActive,
    required bool featured,
    required String createdBy,
    String category = 'General',
    String imageUrl = '',
  }) =>
      ExperienceWritePreparation.eventCreateFields(
        venueId: venueId,
        venueName: venueName,
        title: title,
        description: description,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        isActive: isActive,
        featured: featured,
        createdBy: createdBy,
        category: category,
        imageUrl: imageUrl,
      );

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  static String? validateMobileDealCreate({
    required String title,
    required String description,
    required String startTime,
    required String endTime,
    required DateTime? startDate,
    required DateTime? endDate,
  }) {
    if (title.trim().isEmpty ||
        description.trim().isEmpty ||
        startTime.trim().isEmpty ||
        endTime.trim().isEmpty ||
        startDate == null ||
        endDate == null) {
      return 'Please complete title, description, dates and times.';
    }
    return validateMobileDealDateTimeRange(
      startDate: startDate,
      startTime: startTime,
      endDate: endDate,
      endTime: endTime,
    );
  }

  static String? validateMobileDealUpdate({
    required String title,
    required String description,
    required String startTime,
    required String endTime,
    required DateTime? startDate,
    required DateTime? endDate,
  }) {
    if (title.trim().isEmpty ||
        description.trim().isEmpty ||
        startTime.trim().isEmpty ||
        endTime.trim().isEmpty ||
        startDate == null ||
        endDate == null) {
      return 'Please complete all fields, dates and times.';
    }
    return validateMobileDealDateTimeRange(
      startDate: startDate,
      startTime: startTime,
      endDate: endDate,
      endTime: endTime,
    );
  }

  static String? validateMobileDealDateTimeRange({
    required DateTime startDate,
    required String startTime,
    required DateTime endDate,
    required String endTime,
  }) {
    final startDateTime = combineDateAndTime(startDate, startTime);
    final endDateTime = combineDateAndTime(endDate, endTime);
    if (startDateTime == null || endDateTime == null) {
      return 'Please use valid start/end times. End must be after start.';
    }
    if (!endDateTime.isAfter(startDateTime)) {
      return 'Please use valid start/end times. End must be after start.';
    }
    return null;
  }

  static String? validateMobileDrinkEdit({
    required String name,
    required String category,
    required String price,
    required String description,
  }) {
    if (name.trim().isEmpty ||
        category.trim().isEmpty ||
        price.trim().isEmpty ||
        description.trim().isEmpty) {
      return 'Please complete all fields.';
    }
    return null;
  }

  static String? validateMobileEventCreate({
    required String title,
    required String description,
    required DateTime? startDateTime,
    required DateTime? endDateTime,
  }) {
    if (title.trim().isEmpty ||
        description.trim().isEmpty ||
        startDateTime == null ||
        endDateTime == null) {
      return 'Please complete title, description, start time and end time';
    }
    if (!endDateTime.isAfter(startDateTime)) {
      return 'End time must be after start time';
    }
    return null;
  }

  static String? validatePresetDrinkSelection({required int selectedCount}) {
    if (selectedCount == 0) {
      return 'Select at least one drink.';
    }
    return null;
  }

  static String? validatePresetDrinkPrice({
    required String drinkName,
    required String priceText,
  }) {
    if (priceText.trim().isEmpty) return null;
    final parsed = parsePresetDrinkPrice(priceText);
    if (parsed == null) {
      return 'Please enter a valid price for $drinkName.';
    }
    return null;
  }

  static double? parsePresetDrinkPrice(String priceText) {
    final trimmed = priceText.trim();
    if (trimmed.isEmpty) return null;
    final normalized = trimmed.replaceAll('£', '').replaceAll(',', '');
    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed < 0) return null;
    return parsed;
  }

  static DateTime? combineDateAndTime(DateTime date, String time) {
    final parts = time.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1].replaceAll(RegExp(r'[^0-9]'), ''));
    if (hour == null || minute == null) return null;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  static DateTime combineDealDateAndTime(DateTime date, String? time) =>
      ExperienceSchedulingUtils.combineDateAndTime(date, time);
}
