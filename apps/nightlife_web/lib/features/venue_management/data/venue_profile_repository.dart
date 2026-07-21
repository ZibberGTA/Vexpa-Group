import 'package:vex_core/vex_core.dart';
import 'package:vex_engines/venue/application/venue_profile_update.dart';
import 'package:vex_engines/venue/application/venue_profile_update_service.dart';
import 'package:vex_engines/venue/data/venue_profile_write_repository.dart';
import 'package:vex_engines/venue/domain/venue_profile_search_context.dart';

import '../../../core/vexcore/web_vexcore.dart';
import '../../auth/services/user_role_service.dart';
import '../models/venue_management_activity.dart';
import '../models/venue_management_activity_types.dart';
import '../services/venue_media_access_service.dart';
import 'venue_management_activity_service.dart';

/// Writes venue profile fields for the owner dashboard.
class VenueProfileRepository {
  VenueProfileRepository({
    VenueProfileUpdateService? updateService,
    VenueProfileWriteRepository? writeRepository,
    VenueManagementActivityService? activityService,
  }) : _updateService = updateService ?? WebVexCore.venueProfileUpdateService,
       _writeRepository =
           writeRepository ?? WebVexCore.venueProfileWriteRepository,
       _activityService =
           activityService ?? WebVexCore.venueManagementActivityService;

  final VenueProfileUpdateService _updateService;
  final VenueProfileWriteRepository _writeRepository;
  final VenueManagementActivityService _activityService;

  Future<void> updateVenueName({
    required String venueId,
    required String name,
    required VenueModelSnapshot context,
  }) {
    return _savePreparedUpdate(
      venueId: venueId,
      context: context,
      prepared: _updateService.prepareNameUpdate(
        venueId: venueId,
        name: name,
        context: _searchContext(context),
      ),
      actionType: VenueManagementActivityActionTypes.updated,
      description: 'Venue name updated',
    );
  }

  Future<void> updateVenueCategory({
    required String venueId,
    required String category,
    required VenueModelSnapshot context,
  }) {
    return _savePreparedUpdate(
      venueId: venueId,
      context: context,
      prepared: _updateService.prepareCategoryUpdate(
        venueId: venueId,
        category: category,
        context: _searchContext(context),
      ),
      actionType: VenueManagementActivityActionTypes.updated,
      description: 'Venue category updated',
    );
  }

  Future<void> updateVenueAddress({
    required String venueId,
    required String address,
    required VenueModelSnapshot context,
  }) {
    return _savePreparedUpdate(
      venueId: venueId,
      context: context,
      prepared: _updateService.prepareAddressUpdate(
        venueId: venueId,
        address: address,
        context: _searchContext(context),
      ),
      actionType: VenueManagementActivityActionTypes.contactUpdated,
      description: 'Venue address updated',
    );
  }

  Future<void> updateVenueDescription({
    required String venueId,
    required String description,
    required VenueModelSnapshot context,
  }) {
    return _savePreparedUpdate(
      venueId: venueId,
      context: context,
      prepared: _updateService.prepareDescriptionUpdate(
        venueId: venueId,
        description: description,
        context: _searchContext(context),
      ),
      actionType: VenueManagementActivityActionTypes.updated,
      description: 'Venue description updated',
    );
  }

  Future<void> updateVenueWebsite({
    required String venueId,
    required String website,
    required VenueModelSnapshot context,
  }) {
    return _savePreparedUpdate(
      venueId: venueId,
      context: context,
      prepared: _updateService.prepareWebsiteUpdate(
        venueId: venueId,
        website: website,
      ),
      actionType: VenueManagementActivityActionTypes.contactUpdated,
      description: 'Venue contact details updated',
    );
  }

  Future<void> updateVenueContactDetails({
    required String venueId,
    required String phone,
    required String email,
    required VenueModelSnapshot context,
  }) {
    return _savePreparedUpdate(
      venueId: venueId,
      context: context,
      prepared: _updateService.prepareContactDetailsUpdate(
        venueId: venueId,
        phone: phone,
        email: email,
      ),
      actionType: VenueManagementActivityActionTypes.contactUpdated,
      description: 'Venue contact details updated',
    );
  }

  Future<void> updateOpeningHours({
    required String venueId,
    required Map<String, Map<String, dynamic>> openingHours,
    required VenueModelSnapshot context,
  }) {
    return _savePreparedUpdate(
      venueId: venueId,
      context: context,
      prepared: _updateService.prepareOpeningHoursUpdate(
        venueId: venueId,
        openingHours: openingHours,
      ),
      actionType: VenueManagementActivityActionTypes.openingHoursUpdated,
      description: 'Venue opening hours updated',
    );
  }

  Future<void> updateFeatureTags({
    required String venueId,
    required Set<String> selectedKeys,
    required bool ageRestricted,
    required VenueModelSnapshot context,
  }) {
    return _savePreparedUpdate(
      venueId: venueId,
      context: context,
      prepared: _updateService.prepareFeatureTagsUpdate(
        venueId: venueId,
        selectedKeys: selectedKeys,
        ageRestricted: ageRestricted,
      ),
      actionType: VenueManagementActivityActionTypes.updated,
      description: 'Venue profile updated',
    );
  }

  Future<void> updateCrowdLevel({
    required String venueId,
    required String crowdLevel,
    required VenueModelSnapshot context,
  }) {
    return _savePreparedUpdate(
      venueId: venueId,
      context: context,
      prepared: _updateService.prepareCrowdLevelUpdate(
        venueId: venueId,
        crowdLevel: crowdLevel,
        context: _searchContext(context),
      ),
      actionType: VenueManagementActivityActionTypes.updated,
      description: 'Venue crowd level updated',
    );
  }

  Future<void> updateAgeRestriction({
    required String venueId,
    required bool ageRestricted,
    required VenueModelSnapshot context,
    required Set<String> selectedFeatureKeys,
  }) {
    return updateFeatureTags(
      venueId: venueId,
      selectedKeys: selectedFeatureKeys,
      ageRestricted: ageRestricted,
      context: context,
    );
  }

  Future<void> _savePreparedUpdate({
    required String venueId,
    required VenueModelSnapshot context,
    required DataResult<VenueProfileUpdate> prepared,
    required String actionType,
    required String description,
  }) async {
    if (!VenueMediaAccessService.canManageMediaForVenue(
      userId: context.userId,
      venueId: venueId,
      profile: context.profile,
      venueOwnerId: context.venueOwnerId,
      accessibleVenueIds: context.accessibleVenueIds,
    )) {
      throw VenueMediaAccessDeniedException(
        'You do not have permission to edit this venue.',
      );
    }

    final update = switch (prepared) {
      DataSuccess(:final value) => value,
      DataFailure(:final error) => throw error,
    };

    final result = await _writeRepository.applyVenueProfileUpdate(
      venueId: venueId,
      update: update,
    );

    switch (result) {
      case DataSuccess():
        await _activityService.recordActivity(
          VenueManagementActivity(
            venueId: venueId,
            sourceArea: VenueManagementActivitySourceAreas.venueProfile,
            actionType: actionType,
            entityType: VenueManagementActivityEntityTypes.venue,
            entityId: venueId,
            entityName: context.name.trim().isEmpty ? 'Venue profile' : context.name,
            description: description,
            actorUid: context.userId,
          ),
        );
        return;
      case DataFailure(:final error):
        throw error;
    }
  }

  VenueProfileSearchContext _searchContext(VenueModelSnapshot context) {
    return VenueProfileSearchContext(
      name: context.name,
      description: context.description,
      address: context.address,
      category: context.category,
      crowdLevel: context.crowdLevel,
    );
  }
}

/// Snapshot of venue text fields used when rebuilding search terms.
class VenueModelSnapshot {
  const VenueModelSnapshot({
    required this.userId,
    required this.profile,
    required this.venueOwnerId,
    required this.accessibleVenueIds,
    required this.name,
    required this.description,
    required this.address,
    required this.category,
    required this.crowdLevel,
  });

  final String userId;
  final UserRoleProfile profile;
  final String? venueOwnerId;
  final Iterable<String> accessibleVenueIds;
  final String name;
  final String description;
  final String address;
  final String category;
  final String crowdLevel;
}
