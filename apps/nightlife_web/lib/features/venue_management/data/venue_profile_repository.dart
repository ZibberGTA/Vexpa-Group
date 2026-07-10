import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/vexda_firebase.dart';
import '../../auth/services/user_role_service.dart';
import '../services/venue_media_access_service.dart';
import 'venue_profile_constants.dart';
import 'venue_profile_field_codec.dart';

/// Writes venue profile fields for the owner dashboard.
class VenueProfileRepository {
  VenueProfileRepository({FirebaseFirestore? firestore})
      : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  FirebaseFirestore? _resolveFirestore() {
    if (_firestoreOverride != null) return _firestoreOverride;
    if (!VexdaFirebase.isReady) return null;
    return FirebaseFirestore.instance;
  }

  Future<void> updateVenueProfile({
    required String venueId,
    required Map<String, dynamic> updates,
    required String userId,
    required UserRoleProfile profile,
    String? venueOwnerId,
    Iterable<String> accessibleVenueIds = const [],
  }) async {
    if (!VenueMediaAccessService.canManageMediaForVenue(
      userId: userId,
      venueId: venueId,
      profile: profile,
      venueOwnerId: venueOwnerId,
      accessibleVenueIds: accessibleVenueIds,
    )) {
      throw VenueMediaAccessDeniedException(
        'You do not have permission to edit this venue.',
      );
    }

    final firestore = _resolveFirestore();
    if (firestore == null) {
      throw StateError('Firestore is not available.');
    }

    final payload = Map<String, dynamic>.from(updates)
      ..['updatedAt'] = FieldValue.serverTimestamp();

    try {
      await firestore.collection('venues').doc(venueId).set(
            payload,
            SetOptions(merge: true),
          );
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint('[VenueProfileRepository] update failed (${error.code})');
      }
      rethrow;
    }
  }

  Future<void> updateVenueName({
    required String venueId,
    required String name,
    required VenueModelSnapshot context,
  }) async {
    await updateVenueProfile(
      venueId: venueId,
      userId: context.userId,
      profile: context.profile,
      venueOwnerId: context.venueOwnerId,
      accessibleVenueIds: context.accessibleVenueIds,
      updates: {
        'name': name,
        'searchTerms': VenueProfileFieldCodec.buildSearchTerms(
          name: name,
          description: context.description,
          address: context.address,
          category: context.category,
          crowdLevel: context.crowdLevel,
        ),
      },
    );
  }

  Future<void> updateVenueCategory({
    required String venueId,
    required String category,
    required VenueModelSnapshot context,
  }) async {
    await updateVenueProfile(
      venueId: venueId,
      userId: context.userId,
      profile: context.profile,
      venueOwnerId: context.venueOwnerId,
      accessibleVenueIds: context.accessibleVenueIds,
      updates: {
        'category': category,
        'venueType': category,
        'searchTerms': VenueProfileFieldCodec.buildSearchTerms(
          name: context.name,
          description: context.description,
          address: context.address,
          category: category,
          crowdLevel: context.crowdLevel,
        ),
      },
    );
  }

  Future<void> updateVenueAddress({
    required String venueId,
    required String address,
    required VenueModelSnapshot context,
  }) async {
    await updateVenueProfile(
      venueId: venueId,
      userId: context.userId,
      profile: context.profile,
      venueOwnerId: context.venueOwnerId,
      accessibleVenueIds: context.accessibleVenueIds,
      updates: {
        'address': address,
        'searchTerms': VenueProfileFieldCodec.buildSearchTerms(
          name: context.name,
          description: context.description,
          address: address,
          category: context.category,
          crowdLevel: context.crowdLevel,
        ),
      },
    );
  }

  Future<void> updateVenueDescription({
    required String venueId,
    required String description,
    required VenueModelSnapshot context,
  }) async {
    await updateVenueProfile(
      venueId: venueId,
      userId: context.userId,
      profile: context.profile,
      venueOwnerId: context.venueOwnerId,
      accessibleVenueIds: context.accessibleVenueIds,
      updates: {
        'description': description,
        'searchTerms': VenueProfileFieldCodec.buildSearchTerms(
          name: context.name,
          description: description,
          address: context.address,
          category: context.category,
          crowdLevel: context.crowdLevel,
        ),
      },
    );
  }

  Future<void> updateVenueWebsite({
    required String venueId,
    required String website,
    required VenueModelSnapshot context,
  }) async {
    final normalised = VenueProfileFieldCodec.normaliseWebsite(website);
    await updateVenueProfile(
      venueId: venueId,
      userId: context.userId,
      profile: context.profile,
      venueOwnerId: context.venueOwnerId,
      accessibleVenueIds: context.accessibleVenueIds,
      updates: {
        'website': normalised,
        'websiteUrl': normalised,
      },
    );
  }

  Future<void> updateOpeningHours({
    required String venueId,
    required Map<String, Map<String, dynamic>> openingHours,
    required VenueModelSnapshot context,
  }) async {
    await updateVenueProfile(
      venueId: venueId,
      userId: context.userId,
      profile: context.profile,
      venueOwnerId: context.venueOwnerId,
      accessibleVenueIds: context.accessibleVenueIds,
      updates: {
        'openingHours': VenueProfileFieldCodec.buildOpeningHoursMap(openingHours),
      },
    );
  }

  Future<void> updateFeatureTags({
    required String venueId,
    required Set<String> selectedKeys,
    required bool ageRestricted,
    required VenueModelSnapshot context,
  }) async {
    await updateVenueProfile(
      venueId: venueId,
      userId: context.userId,
      profile: context.profile,
      venueOwnerId: context.venueOwnerId,
      accessibleVenueIds: context.accessibleVenueIds,
      updates: VenueProfileFieldCodec.buildFeatureTagsUpdate(
        selectedKeys: selectedKeys,
        ageRestricted: ageRestricted,
      ),
    );
  }

  Future<void> updateCrowdLevel({
    required String venueId,
    required String crowdLevel,
    required VenueModelSnapshot context,
  }) async {
    await updateVenueProfile(
      venueId: venueId,
      userId: context.userId,
      profile: context.profile,
      venueOwnerId: context.venueOwnerId,
      accessibleVenueIds: context.accessibleVenueIds,
      updates: {
        'crowdLevel': crowdLevel,
        'currentCrowdLevel': crowdLevel,
        'currentCrowdScore': VenueProfileConstants.crowdScoreForLevel(crowdLevel),
        'crowdSource': 'owner',
        'crowdUpdatedAt': FieldValue.serverTimestamp(),
        'searchTerms': VenueProfileFieldCodec.buildSearchTerms(
          name: context.name,
          description: context.description,
          address: context.address,
          category: context.category,
          crowdLevel: crowdLevel,
        ),
      },
    );
  }

  Future<void> updateAgeRestriction({
    required String venueId,
    required bool ageRestricted,
    required VenueModelSnapshot context,
    required Set<String> selectedFeatureKeys,
  }) async {
    await updateFeatureTags(
      venueId: venueId,
      selectedKeys: selectedFeatureKeys,
      ageRestricted: ageRestricted,
      context: context,
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
