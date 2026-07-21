import 'package:vex_core/vex_core.dart';

import '../domain/venue_profile_constants.dart';
import '../domain/venue_profile_field_codec.dart';
import '../domain/venue_profile_search_context.dart';
import 'venue_profile_update.dart';

/// Prepares validated venue profile update payloads for persistence.
final class VenueProfileUpdateService {
  const VenueProfileUpdateService();

  DataResult<VenueProfileUpdate> prepareNameUpdate({
    required String venueId,
    required String name,
    required VenueProfileSearchContext context,
  }) {
    return _withVenueId(venueId, () {
      final trimmedName = name.trim();
      return VenueProfileUpdate(
        fields: {
          'name': trimmedName,
          'searchTerms': _searchTerms(context.copyWith(name: trimmedName)),
        },
      );
    });
  }

  DataResult<VenueProfileUpdate> prepareCategoryUpdate({
    required String venueId,
    required String category,
    required VenueProfileSearchContext context,
  }) {
    return _withVenueId(venueId, () {
      final trimmedCategory = category.trim();
      return VenueProfileUpdate(
        fields: {
          'category': trimmedCategory,
          'venueType': trimmedCategory,
          'searchTerms': _searchTerms(
            context.copyWith(category: trimmedCategory),
          ),
        },
      );
    });
  }

  DataResult<VenueProfileUpdate> prepareAddressUpdate({
    required String venueId,
    required String address,
    required VenueProfileSearchContext context,
  }) {
    return _withVenueId(venueId, () {
      final trimmedAddress = address.trim();
      return VenueProfileUpdate(
        fields: {
          'address': trimmedAddress,
          'searchTerms': _searchTerms(
            context.copyWith(address: trimmedAddress),
          ),
        },
      );
    });
  }

  DataResult<VenueProfileUpdate> prepareDescriptionUpdate({
    required String venueId,
    required String description,
    required VenueProfileSearchContext context,
  }) {
    return _withVenueId(venueId, () {
      final trimmedDescription = description.trim();
      return VenueProfileUpdate(
        fields: {
          'description': trimmedDescription,
          'searchTerms': _searchTerms(
            context.copyWith(description: trimmedDescription),
          ),
        },
      );
    });
  }

  DataResult<VenueProfileUpdate> prepareWebsiteUpdate({
    required String venueId,
    required String website,
  }) {
    return _withVenueId(venueId, () {
      final trimmedWebsite = website.trim();
      if (trimmedWebsite.isNotEmpty) {
        final validationError = VenueProfileFieldCodec.validateWebsite(
          trimmedWebsite,
        );
        if (validationError != null) {
          throw _ValidationException(validationError);
        }
      }

      final normalised = VenueProfileFieldCodec.normaliseWebsite(
        trimmedWebsite,
      );
      return VenueProfileUpdate(
        fields: {'website': normalised, 'websiteUrl': normalised},
      );
    });
  }

  DataResult<VenueProfileUpdate> prepareContactDetailsUpdate({
    required String venueId,
    required String phone,
    required String email,
  }) {
    return _withVenueId(venueId, () {
      final trimmedEmail = email.trim();
      final validationError = VenueProfileFieldCodec.validateEmail(trimmedEmail);
      if (validationError != null) {
        throw _ValidationException(validationError);
      }

      return VenueProfileUpdate(
        fields: {
          'phone': phone.trim(),
          'email': trimmedEmail,
        },
      );
    });
  }

  DataResult<VenueProfileUpdate> prepareOpeningHoursUpdate({
    required String venueId,
    required Map<String, Map<String, dynamic>> openingHours,
  }) {
    return _withVenueId(venueId, () {
      final validationError = VenueProfileFieldCodec.validateOpeningHours(
        openingHours,
      );
      if (validationError != null) {
        throw _ValidationException(validationError);
      }

      return VenueProfileUpdate(
        fields: {
          'openingHours': VenueProfileFieldCodec.buildOpeningHoursMap(
            openingHours,
          ),
        },
      );
    });
  }

  DataResult<VenueProfileUpdate> prepareFeatureTagsUpdate({
    required String venueId,
    required Set<String> selectedKeys,
    required bool ageRestricted,
  }) {
    return _withVenueId(venueId, () {
      return VenueProfileUpdate(
        fields: VenueProfileFieldCodec.buildFeatureTagsUpdate(
          selectedKeys: selectedKeys,
          ageRestricted: ageRestricted,
        ),
      );
    });
  }

  DataResult<VenueProfileUpdate> prepareCrowdLevelUpdate({
    required String venueId,
    required String crowdLevel,
    required VenueProfileSearchContext context,
  }) {
    return _withVenueId(venueId, () {
      final trimmedLevel = crowdLevel.trim();
      return VenueProfileUpdate(
        fields: {
          'crowdLevel': trimmedLevel,
          'currentCrowdLevel': trimmedLevel,
          'currentCrowdScore': VenueProfileConstants.crowdScoreForLevel(
            trimmedLevel,
          ),
          'crowdSource': 'owner',
          'searchTerms': _searchTerms(
            context.copyWith(crowdLevel: trimmedLevel),
          ),
        },
        serverTimestampFields: const ['updatedAt', 'crowdUpdatedAt'],
      );
    });
  }

  DataResult<VenueProfileUpdate> _withVenueId(
    String venueId,
    VenueProfileUpdate Function() build,
  ) {
    if (venueId.trim().isEmpty) {
      return const DataFailure(
        VexException('Venue ID is required.', code: 'venue-id-required'),
      );
    }

    try {
      return DataSuccess(build());
    } on _ValidationException catch (error) {
      return DataFailure(
        VexException(error.message, code: 'venue-profile-validation-failed'),
      );
    }
  }

  List<String> _searchTerms(VenueProfileSearchContext context) {
    return VenueProfileFieldCodec.buildSearchTerms(
      name: context.name,
      description: context.description,
      address: context.address,
      category: context.category,
      crowdLevel: context.crowdLevel,
    );
  }
}

final class _ValidationException implements Exception {
  _ValidationException(this.message);

  final String message;
}

extension on VenueProfileSearchContext {
  VenueProfileSearchContext copyWith({
    String? name,
    String? description,
    String? address,
    String? category,
    String? crowdLevel,
  }) {
    return VenueProfileSearchContext(
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      category: category ?? this.category,
      crowdLevel: crowdLevel ?? this.crowdLevel,
    );
  }
}
