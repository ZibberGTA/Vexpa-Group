import '../shared/experience_deal_types.dart';
import '../shared/experience_drink_categories.dart';
import 'experience_update_preparation.dart';

/// Prepares Firebase-free write field maps for venue-published content.
final class ExperienceWritePreparation {
  ExperienceWritePreparation._();

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
  }) {
    final normalizedCategory = ExperienceDrinkCategories.normalize(category);
    final trimmedName = name.trim();
    final trimmedDescription = description.trim();

    return {
      'venueId': venueId,
      'venueName': venueName,
      'name': trimmedName,
      'category': normalizedCategory,
      'price': price,
      'description': trimmedDescription,
      'available': available,
      'featured': featured,
      'isDeleted': false,
      'searchTerms': drinkSearchTerms(
        name: trimmedName,
        category: normalizedCategory,
        venueName: venueName,
      ),
      'createdBy': createdBy,
    };
  }

  static Map<String, dynamic> drinkUpdateFields({
    required String venueName,
    required String name,
    required String category,
    required String description,
    required bool available,
    required bool featured,
    required String updatedBy,
    double? price,
  }) {
    final normalizedCategory = ExperienceDrinkCategories.normalize(category);
    final trimmedName = name.trim();
    final trimmedDescription = description.trim();

    return {
      'name': trimmedName,
      'category': normalizedCategory,
      'price': price,
      'description': trimmedDescription,
      'available': available,
      'featured': featured,
      'searchTerms': drinkSearchTerms(
        name: trimmedName,
        category: normalizedCategory,
        venueName: venueName,
      ),
      'updatedBy': updatedBy,
    };
  }

  static Map<String, dynamic> drinkPatchFields({
    required String venueName,
    required String drinkName,
    required String category,
    required String updatedBy,
    String? name,
    String? categoryPatch,
    double? price,
    bool? available,
    bool? featured,
  }) {
    final payload = <String, dynamic>{'updatedBy': updatedBy};

    final effectiveName = name?.trim() ?? drinkName.trim();
    final effectiveCategory = categoryPatch == null
        ? category
        : ExperienceDrinkCategories.normalize(categoryPatch);

    if (name != null) payload['name'] = effectiveName;
    if (categoryPatch != null) payload['category'] = effectiveCategory;
    if (price != null) payload['price'] = price;
    if (available != null) payload['available'] = available;
    if (featured != null) payload['featured'] = featured;

    if (name != null || categoryPatch != null) {
      payload['searchTerms'] = drinkSearchTerms(
        name: effectiveName,
        category: effectiveCategory,
        venueName: venueName,
      );
    }

    return payload;
  }

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
  }) {
    final normalizedType = ExperienceDealTypes.normalize(dealType);
    final trimmedTitle = title.trim();
    final trimmedDescription = description.trim();
    final trimmedValue = value.trim();

    return {
      'venueId': venueId,
      'venueName': venueName,
      'title': trimmedTitle,
      'description': trimmedDescription,
      'dealType': normalizedType,
      'value': trimmedValue,
      'startDateTime': startDateTime,
      'endDateTime': endDateTime,
      'startTime': startTime.trim(),
      'endTime': endTime.trim(),
      'availableDays': availableDays,
      'isActive': isActive,
      'featured': featured,
      'isDeleted': false,
      'searchTerms': dealSearchTerms(
        title: trimmedTitle,
        description: trimmedDescription,
        dealType: normalizedType,
        value: trimmedValue,
        venueName: venueName,
      ),
      'createdBy': createdBy,
    };
  }

  static Map<String, dynamic> dealUpdateFields({
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
    required String updatedBy,
  }) {
    final normalizedType = ExperienceDealTypes.normalize(dealType);
    final trimmedTitle = title.trim();
    final trimmedDescription = description.trim();
    final trimmedValue = value.trim();

    return {
      'title': trimmedTitle,
      'description': trimmedDescription,
      'dealType': normalizedType,
      'value': trimmedValue,
      'startDateTime': startDateTime,
      'endDateTime': endDateTime,
      'startTime': startTime.trim(),
      'endTime': endTime.trim(),
      'availableDays': availableDays,
      'isActive': isActive,
      'featured': featured,
      'searchTerms': dealSearchTerms(
        title: trimmedTitle,
        description: trimmedDescription,
        dealType: normalizedType,
        value: trimmedValue,
        venueName: venueName,
      ),
      'updatedBy': updatedBy,
    };
  }

  static Map<String, dynamic> dealPatchFields({
    required String venueName,
    required String title,
    required String description,
    required String dealType,
    required String value,
    required String updatedBy,
    String? titlePatch,
    String? dealTypePatch,
    String? valuePatch,
    DateTime? startDateTime,
    DateTime? endDateTime,
    bool? isActive,
    bool? featured,
  }) {
    final payload = <String, dynamic>{'updatedBy': updatedBy};

    final effectiveTitle = titlePatch?.trim() ?? title.trim();
    final effectiveType =
        dealTypePatch == null ? dealType : ExperienceDealTypes.normalize(dealTypePatch);
    final effectiveValue = valuePatch?.trim() ?? value.trim();

    if (titlePatch != null) payload['title'] = effectiveTitle;
    if (dealTypePatch != null) payload['dealType'] = effectiveType;
    if (valuePatch != null) payload['value'] = effectiveValue;
    if (startDateTime != null) payload['startDateTime'] = startDateTime;
    if (endDateTime != null) payload['endDateTime'] = endDateTime;
    if (isActive != null) payload['isActive'] = isActive;
    if (featured != null) payload['featured'] = featured;

    if (titlePatch != null || dealTypePatch != null || valuePatch != null) {
      payload['searchTerms'] = dealSearchTerms(
        title: effectiveTitle,
        description: description,
        dealType: effectiveType,
        value: effectiveValue,
        venueName: venueName,
      );
    }

    return payload;
  }

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
  }) {
    final trimmedTitle = title.trim();
    final trimmedDescription = description.trim();

    return {
      'venueId': venueId,
      'venueName': venueName,
      'title': trimmedTitle,
      'description': trimmedDescription,
      'startDateTime': startDateTime,
      'endDateTime': endDateTime,
      'dateTime': startDateTime,
      'category': category,
      'imageUrl': imageUrl,
      'isDeleted': false,
      'isActive': isActive,
      'featured': featured,
      'searchTerms': eventSearchTerms(
        title: trimmedTitle,
        description: trimmedDescription,
        venueName: venueName,
        category: category,
      ),
      'createdBy': createdBy,
    };
  }

  static Map<String, dynamic> eventPatchFields({
    required String updatedBy,
    String? title,
    DateTime? startDateTime,
    DateTime? endDateTime,
    bool? isActive,
    bool? featured,
  }) {
    final payload = <String, dynamic>{'updatedBy': updatedBy};

    if (title != null) payload['title'] = title.trim();
    if (startDateTime != null) {
      payload['startDateTime'] = startDateTime;
      payload['dateTime'] = startDateTime;
    }
    if (endDateTime != null) payload['endDateTime'] = endDateTime;
    if (isActive != null) payload['isActive'] = isActive;
    if (featured != null) payload['featured'] = featured;

    return payload;
  }

  static List<String> drinkSearchTerms({
    required String name,
    required String category,
    required String venueName,
  }) =>
      ExperienceUpdatePreparation.searchTermsForValues([
        name,
        ExperienceDrinkCategories.displayName(category),
        venueName,
      ]);

  static List<String> dealSearchTerms({
    required String title,
    required String description,
    required String dealType,
    required String value,
    required String venueName,
  }) =>
      ExperienceUpdatePreparation.searchTermsForValues([
        title,
        description,
        ExperienceDealTypes.displayName(dealType),
        value,
        venueName,
      ]);

  static List<String> eventSearchTerms({
    required String title,
    required String description,
    required String venueName,
    required String category,
  }) =>
      ExperienceUpdatePreparation.searchTermsForValues([
        title,
        description,
        venueName,
        category,
      ]);
}
