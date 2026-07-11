import 'package:vex_core/vex_core.dart';
import 'package:vex_engines/discovery/shared/discovery_venue_search_term_builder.dart';

import '../domain/venue_profile_constants.dart';
import '../domain/venue_profile_field_codec.dart';
import 'venue_profile_update.dart';

/// Input for owner venue create and update forms on mobile.
final class VenueOwnerProfileDraft {
  const VenueOwnerProfileDraft({
    required this.name,
    required this.description,
    required this.address,
    required this.category,
    required this.crowdLevel,
    this.bannerImageUrl = '',
    this.logoUrl = '',
    this.websiteUrl = '',
    required this.openingHours,
    this.latitude,
    this.longitude,
  });

  final String name;
  final String description;
  final String address;
  final String category;
  final String crowdLevel;
  final String bannerImageUrl;
  final String logoUrl;
  final String websiteUrl;
  final Map<String, Map<String, dynamic>> openingHours;
  final double? latitude;
  final double? longitude;
}

/// Prepared owner venue write with engine validation applied.
final class VenueOwnerProfilePreparedWrite {
  const VenueOwnerProfilePreparedWrite({
    required this.update,
    this.latitude,
    this.longitude,
  });

  final VenueProfileUpdate update;
  final double? latitude;
  final double? longitude;
}

/// Prepares validated owner venue create/update payloads for mobile.
final class VenueOwnerProfileService {
  const VenueOwnerProfileService();

  DataResult<VenueOwnerProfilePreparedWrite> prepareCreate({
    required String ownerId,
    required VenueOwnerProfileDraft draft,
  }) {
    final ownerValidation = _validateOwnerId(ownerId);
    if (ownerValidation != null) {
      return DataFailure(ownerValidation);
    }

    return _prepareDraft(
      draft: draft,
      buildSearchTerms: (normalised) =>
          DiscoveryVenueSearchTermBuilder.buildMinimalVenueTerms(
            name: normalised.name,
            description: normalised.description,
            address: normalised.address,
            category: normalised.category,
            crowdLevel: normalised.crowdLevel,
          ),
      extraFields: {
        'ownerId': ownerId.trim(),
        'hasDeals': false,
        'isDeleted': false,
        'activePresenceCount': 0,
        'presenceRadiusMeters': 75,
      },
      serverTimestampFields: const ['createdAt'],
    );
  }

  DataResult<VenueOwnerProfilePreparedWrite> prepareUpdate({
    required String venueId,
    required VenueOwnerProfileDraft draft,
  }) {
    if (venueId.trim().isEmpty) {
      return const DataFailure(
        VexException('Venue ID is required.', code: 'venue-id-required'),
      );
    }

    return _prepareDraft(
      draft: draft,
      buildSearchTerms: (normalised) =>
          DiscoveryVenueSearchTermBuilder.buildVenueFormTerms(
            name: normalised.name,
            description: normalised.description,
            address: normalised.address,
            category: normalised.category,
            crowdLevel: normalised.crowdLevel,
          ),
      extraFields: const {
        'presenceRadiusMeters': 75,
      },
      serverTimestampFields: const ['updatedAt', 'crowdUpdatedAt'],
    );
  }

  DataResult<VenueOwnerProfilePreparedWrite> _prepareDraft({
    required VenueOwnerProfileDraft draft,
    required List<String> Function(_NormalisedDraft normalised) buildSearchTerms,
    required Map<String, Object?> extraFields,
    required List<String> serverTimestampFields,
  }) {
    try {
      final requiredError = _validateRequiredFields(draft);
      if (requiredError != null) {
        throw _ValidationException(requiredError);
      }

      final openingHoursError = VenueProfileFieldCodec.validateOpeningHours(
        draft.openingHours,
      );
      if (openingHoursError != null) {
        throw _ValidationException(openingHoursError);
      }

      final websiteUrl = _normaliseWebsiteUrl(draft.websiteUrl);

      final normalised = _NormalisedDraft(
        name: draft.name.trim(),
        description: draft.description.trim(),
        address: draft.address.trim(),
        category: draft.category.trim(),
        crowdLevel: draft.crowdLevel.trim(),
        bannerImageUrl: draft.bannerImageUrl.trim(),
        logoUrl: draft.logoUrl.trim(),
        websiteUrl: websiteUrl,
      );

      final fields = <String, Object?>{
        ...extraFields,
        'name': normalised.name,
        'description': normalised.description,
        'address': normalised.address,
        'category': normalised.category,
        'bannerImageUrl': normalised.bannerImageUrl,
        'logoUrl': normalised.logoUrl,
        'websiteUrl': normalised.websiteUrl,
        'crowdLevel': normalised.crowdLevel,
        'currentCrowdLevel': normalised.crowdLevel,
        'currentCrowdScore': VenueProfileConstants.crowdScoreForLevel(
          normalised.crowdLevel,
        ),
        'crowdSource': 'owner',
        'openingHours': VenueProfileFieldCodec.buildOpeningHoursMap(
          draft.openingHours,
        ),
        'searchTerms': buildSearchTerms(normalised),
      };

      return DataSuccess(
        VenueOwnerProfilePreparedWrite(
          update: VenueProfileUpdate(
            fields: fields,
            serverTimestampFields: serverTimestampFields,
          ),
          latitude: draft.latitude,
          longitude: draft.longitude,
        ),
      );
    } on _ValidationException catch (error) {
      return DataFailure(
        VexException(error.message, code: 'venue-profile-validation-failed'),
      );
    }
  }

  VexException? _validateOwnerId(String ownerId) {
    if (ownerId.trim().isEmpty) {
      return const VexException(
        'Owner ID is required.',
        code: 'owner-id-required',
      );
    }
    return null;
  }

  String? _validateRequiredFields(VenueOwnerProfileDraft draft) {
    if (draft.name.trim().isEmpty ||
        draft.description.trim().isEmpty ||
        draft.address.trim().isEmpty ||
        draft.category.trim().isEmpty) {
      return 'Please complete all fields.';
    }
    return null;
  }

  String _normaliseWebsiteUrl(String websiteUrl) {
    final trimmed = websiteUrl.trim();
    if (trimmed.isEmpty) return '';

    final validationError = VenueProfileFieldCodec.validateWebsite(trimmed);
    if (validationError != null) {
      throw _ValidationException(validationError);
    }

    return VenueProfileFieldCodec.normaliseWebsite(trimmed);
  }
}

final class _NormalisedDraft {
  const _NormalisedDraft({
    required this.name,
    required this.description,
    required this.address,
    required this.category,
    required this.crowdLevel,
    required this.bannerImageUrl,
    required this.logoUrl,
    required this.websiteUrl,
  });

  final String name;
  final String description;
  final String address;
  final String category;
  final String crowdLevel;
  final String bannerImageUrl;
  final String logoUrl;
  final String websiteUrl;
}

final class _ValidationException implements Exception {
  _ValidationException(this.message);

  final String message;
}

VenueWritePayload venueWritePayloadFromPreparedWrite(
  VenueOwnerProfilePreparedWrite prepared,
) {
  final coordinates = prepared.latitude != null && prepared.longitude != null
      ? VenueWriteCoordinates(
          latitude: prepared.latitude!,
          longitude: prepared.longitude!,
        )
      : null;

  return VenueWritePayload(
    fields: Map<String, Object?>.from(prepared.update.fields),
    coordinates: coordinates,
    serverTimestampFields: prepared.update.serverTimestampFields,
  );
}
