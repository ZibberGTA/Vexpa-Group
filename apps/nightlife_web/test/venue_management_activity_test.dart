import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nightlife_web/features/auth/services/user_role_service.dart';
import 'package:nightlife_web/features/venue_management/data/venue_management_activity_action_inference.dart';
import 'package:nightlife_web/features/venue_management/data/venue_management_activity_repository.dart';
import 'package:nightlife_web/features/venue_management/data/venue_management_activity_service.dart';
import 'package:nightlife_web/features/venue_management/data/venue_profile_repository.dart';
import 'package:nightlife_web/features/venue_management/models/bulk_deal_patch.dart';
import 'package:nightlife_web/features/venue_management/models/bulk_drink_patch.dart';
import 'package:nightlife_web/features/venue_management/models/bulk_event_patch.dart';
import 'package:nightlife_web/features/venue_management/models/venue_management_activity.dart';
import 'package:nightlife_web/features/venue_management/models/venue_management_activity_types.dart';
import 'package:vex_core/vex_core.dart';
import 'package:vex_engines/venue/application/venue_profile_update.dart';
import 'package:vex_engines/venue/data/venue_profile_write_repository.dart';

void main() {
  group('VenueManagementActivity model', () {
    test('serializes required fields for Firestore append', () {
      const activity = VenueManagementActivity(
        venueId: 'venue-1',
        sourceArea: VenueManagementActivitySourceAreas.drinks,
        actionType: VenueManagementActivityActionTypes.created,
        entityType: VenueManagementActivityEntityTypes.drink,
        entityId: 'drink-1',
        entityName: 'Negroni',
        description: 'Drink created',
        actorUid: 'owner-1',
        actorDisplayName: 'Alex Owner',
        metadata: {'featured': true},
      );

      final payload = activity.toFirestore();
      expect(payload['venueId'], 'venue-1');
      expect(payload['sourceArea'], 'drinks');
      expect(payload['actionType'], 'created');
      expect(payload['entityType'], 'drink');
      expect(payload['entityId'], 'drink-1');
      expect(payload['entityName'], 'Negroni');
      expect(payload['description'], 'Drink created');
      expect(payload['actorUid'], 'owner-1');
      expect(payload['actorDisplayName'], 'Alex Owner');
      expect(payload['metadata'], {'featured': true});
      expect(payload['version'], 1);
      expect(payload['occurredAt'], isNotNull);
    });

    test('round-trips from Firestore map', () {
      final activity = VenueManagementActivity.fromFirestore('activity-1', {
        'venueId': 'venue-1',
        'sourceArea': 'gallery',
        'actionType': 'photo_uploaded',
        'entityType': 'media',
        'entityId': 'media-1',
        'entityName': 'Front bar',
        'description': 'Photo uploaded',
        'actorUid': 'owner-1',
        'metadata': {'tab': 'venue_gallery'},
        'version': 1,
      });

      expect(activity.activityId, 'activity-1');
      expect(activity.sourceArea, 'gallery');
      expect(activity.metadata['tab'], 'venue_gallery');
    });

    test('rejects invalid records for write', () {
      const invalid = VenueManagementActivity(
        venueId: '',
        sourceArea: VenueManagementActivitySourceAreas.drinks,
        actionType: VenueManagementActivityActionTypes.created,
        entityType: VenueManagementActivityEntityTypes.drink,
        entityId: 'drink-1',
        entityName: 'Negroni',
        description: 'Drink created',
        actorUid: 'owner-1',
      );

      expect(invalid.isValidForWrite, isFalse);
    });
  });

  group('VenueManagementActivityActionInference', () {
    test('maps drink availability patch to availability_changed', () {
      expect(
        VenueManagementActivityActionInference.drinkPatchActionType(
          const BulkDrinkPatch(available: false),
        ),
        VenueManagementActivityActionTypes.availabilityChanged,
      );
    });

    test('maps deal activation patch to activated/deactivated', () {
      expect(
        VenueManagementActivityActionInference.dealPatchActionType(
          const BulkDealPatch(isActive: true),
        ),
        VenueManagementActivityActionTypes.activated,
      );
      expect(
        VenueManagementActivityActionInference.dealPatchActionType(
          const BulkDealPatch(isActive: false),
        ),
        VenueManagementActivityActionTypes.deactivated,
      );
    });

    test('maps event publication patch to published/unpublished', () {
      expect(
        VenueManagementActivityActionInference.eventPatchActionType(
          const BulkEventPatch(isActive: true),
        ),
        VenueManagementActivityActionTypes.published,
      );
      expect(
        VenueManagementActivityActionInference.eventPatchActionType(
          const BulkEventPatch(isActive: false),
        ),
        VenueManagementActivityActionTypes.unpublished,
      );
    });
  });

  group('VenueManagementActivityRepository', () {
    test('append stores append-only records in memory', () async {
      final repository = InMemoryVenueManagementActivityRepository();
      const activity = VenueManagementActivity(
        venueId: 'venue-1',
        sourceArea: VenueManagementActivitySourceAreas.deals,
        actionType: VenueManagementActivityActionTypes.created,
        entityType: VenueManagementActivityEntityTypes.deal,
        entityId: 'deal-1',
        entityName: 'Happy hour',
        description: 'Deal created',
        actorUid: 'owner-1',
      );

      final id = await repository.append(activity);

      expect(id, isNotEmpty);
      expect(repository.records, hasLength(1));
      expect(repository.records.single.venueId, 'venue-1');
      expect(repository.records.single.actorUid, 'owner-1');
    });

    test('fetchRecentForVenue returns newest-first limited venue-scoped records', () async {
      final repository = InMemoryVenueManagementActivityRepository();
      const venueA = 'venue-a';
      const venueB = 'venue-b';

      Future<void> append({
        required String venueId,
        required DateTime occurredAt,
        required String entityName,
      }) async {
        await repository.append(
          VenueManagementActivity(
            venueId: venueId,
            sourceArea: VenueManagementActivitySourceAreas.drinks,
            actionType: VenueManagementActivityActionTypes.created,
            entityType: VenueManagementActivityEntityTypes.drink,
            entityId: '$venueId-$entityName',
            entityName: entityName,
            description: 'Drink created',
            actorUid: 'owner-1',
            occurredAt: occurredAt,
          ),
        );
      }

      await append(
        venueId: venueA,
        occurredAt: DateTime(2026, 7, 10),
        entityName: 'Old drink',
      );
      await append(
        venueId: venueA,
        occurredAt: DateTime(2026, 7, 18),
        entityName: 'New drink',
      );
      await append(
        venueId: venueB,
        occurredAt: DateTime(2026, 7, 19),
        entityName: 'Other venue drink',
      );

      for (var i = 0; i < 11; i++) {
        await append(
          venueId: venueA,
          occurredAt: DateTime(2026, 7, 1, i),
          entityName: 'Bulk drink $i',
        );
      }

      final recent = await repository.fetchRecentForVenue(
        venueId: venueA,
        limit: 10,
      );

      expect(recent, hasLength(10));
      expect(recent.first.entityName, 'New drink');
      expect(recent.any((record) => record.venueId == venueB), isFalse);
      expect(recent.every((record) => record.venueId == venueA), isTrue);
    });

    test('fetchRecentForSourceArea scopes and orders newest first', () async {
      final repository = InMemoryVenueManagementActivityRepository();

      Future<void> append({
        required String venueId,
        required String sourceArea,
        required DateTime occurredAt,
        required String entityName,
      }) async {
        await repository.append(
          VenueManagementActivity(
            venueId: venueId,
            sourceArea: sourceArea,
            actionType: VenueManagementActivityActionTypes.created,
            entityType: VenueManagementActivityEntityTypes.deal,
            entityId: '$venueId-$entityName',
            entityName: entityName,
            description: 'Deal created',
            actorUid: 'owner-1',
            occurredAt: occurredAt,
          ),
        );
      }

      await append(
        venueId: 'venue-a',
        sourceArea: VenueManagementActivitySourceAreas.deals,
        occurredAt: DateTime(2026, 7, 10),
        entityName: 'Old deal',
      );
      await append(
        venueId: 'venue-a',
        sourceArea: VenueManagementActivitySourceAreas.deals,
        occurredAt: DateTime(2026, 7, 18),
        entityName: 'New deal',
      );
      await append(
        venueId: 'venue-a',
        sourceArea: VenueManagementActivitySourceAreas.events,
        occurredAt: DateTime(2026, 7, 19),
        entityName: 'Event only',
      );
      await append(
        venueId: 'venue-b',
        sourceArea: VenueManagementActivitySourceAreas.deals,
        occurredAt: DateTime(2026, 7, 19),
        entityName: 'Other venue deal',
      );

      final recent = await repository.fetchRecentForSourceArea(
        venueId: 'venue-a',
        sourceArea: VenueManagementActivitySourceAreas.deals,
        limit: 10,
      );

      expect(recent, hasLength(2));
      expect(recent.first.entityName, 'New deal');
      expect(recent.every((record) => record.sourceArea == 'deals'), isTrue);
      expect(recent.every((record) => record.venueId == 'venue-a'), isTrue);
    });

    test('fetchRecentForEntity scopes to venue entity and enforces limit', () async {
      final repository = InMemoryVenueManagementActivityRepository();

      for (var i = 0; i < 3; i++) {
        await repository.append(
          VenueManagementActivity(
            venueId: 'venue-a',
            sourceArea: VenueManagementActivitySourceAreas.drinks,
            actionType: VenueManagementActivityActionTypes.updated,
            entityType: VenueManagementActivityEntityTypes.drink,
            entityId: 'drink-1',
            entityName: 'Negroni',
            description: 'Drink updated',
            actorUid: 'owner-1',
            occurredAt: DateTime(2026, 7, 1, i),
          ),
        );
      }

      await repository.append(
        VenueManagementActivity(
          venueId: 'venue-a',
          sourceArea: VenueManagementActivitySourceAreas.drinks,
          actionType: VenueManagementActivityActionTypes.updated,
          entityType: VenueManagementActivityEntityTypes.drink,
          entityId: 'drink-2',
          entityName: 'Martini',
          description: 'Drink updated',
          actorUid: 'owner-1',
          occurredAt: DateTime(2026, 7, 18),
        ),
      );

      final recent = await repository.fetchRecentForEntity(
        venueId: 'venue-a',
        entityType: VenueManagementActivityEntityTypes.drink,
        entityId: 'drink-1',
        limit: 2,
      );

      expect(recent, hasLength(2));
      expect(recent.every((record) => record.entityId == 'drink-1'), isTrue);
    });
  });

  group('VenueManagementActivityService', () {
    test('recordActivity appends one valid record', () async {
      final repository = InMemoryVenueManagementActivityRepository();
      final service = DefaultVenueManagementActivityService(
        repository: repository,
      );

      await service.recordActivity(
        const VenueManagementActivity(
          venueId: 'venue-1',
          sourceArea: VenueManagementActivitySourceAreas.events,
          actionType: VenueManagementActivityActionTypes.created,
          entityType: VenueManagementActivityEntityTypes.event,
          entityId: 'event-1',
          entityName: 'DJ Night',
          description: 'Event created',
          actorUid: 'owner-1',
        ),
      );

      expect(repository.records, hasLength(1));
      expect(repository.records.single.entityName, 'DJ Night');
    });

    test('skips invalid activity without throwing', () async {
      final repository = InMemoryVenueManagementActivityRepository();
      final service = DefaultVenueManagementActivityService(
        repository: repository,
      );

      await service.recordActivity(
        const VenueManagementActivity(
          venueId: '',
          sourceArea: VenueManagementActivitySourceAreas.events,
          actionType: VenueManagementActivityActionTypes.created,
          entityType: VenueManagementActivityEntityTypes.event,
          entityId: 'event-1',
          entityName: 'DJ Night',
          description: 'Event created',
          actorUid: 'owner-1',
        ),
      );

      expect(repository.records, isEmpty);
    });

    test('loadRecentActivity delegates to repository with venue scope', () async {
      final repository = InMemoryVenueManagementActivityRepository();
      final service = DefaultVenueManagementActivityService(
        repository: repository,
      );

      await repository.append(
        VenueManagementActivity(
          venueId: 'venue-1',
          sourceArea: VenueManagementActivitySourceAreas.drinks,
          actionType: VenueManagementActivityActionTypes.created,
          entityType: VenueManagementActivityEntityTypes.drink,
          entityId: 'drink-1',
          entityName: 'Negroni',
          description: 'Drink created',
          actorUid: 'owner-1',
          occurredAt: DateTime(2026, 7, 18),
        ),
      );

      final recent = await service.loadRecentActivity(
        venueId: 'venue-1',
        limit: 10,
      );

      expect(recent, hasLength(1));
      expect(recent.single.entityName, 'Negroni');
    });

    test('loadRecentActivityForSourceArea delegates with venue and source scope', () async {
      final repository = InMemoryVenueManagementActivityRepository();
      final service = DefaultVenueManagementActivityService(
        repository: repository,
      );

      await repository.append(
        VenueManagementActivity(
          venueId: 'venue-1',
          sourceArea: VenueManagementActivitySourceAreas.gallery,
          actionType: VenueManagementActivityActionTypes.photoUploaded,
          entityType: VenueManagementActivityEntityTypes.media,
          entityId: 'media-1',
          entityName: 'Bar photo',
          description: 'Photo uploaded',
          actorUid: 'owner-1',
          occurredAt: DateTime(2026, 7, 18),
        ),
      );

      final recent = await service.loadRecentActivityForSourceArea(
        venueId: 'venue-1',
        sourceArea: VenueManagementActivitySourceAreas.gallery,
        limit: 5,
      );

      expect(recent, hasLength(1));
      expect(recent.single.sourceArea, 'gallery');
    });

    test('repository failure does not propagate to caller', () async {
      final service = DefaultVenueManagementActivityService(
        repository: _ThrowingActivityRepository(),
      );

      await expectLater(
        service.recordActivity(
          const VenueManagementActivity(
            venueId: 'venue-1',
            sourceArea: VenueManagementActivitySourceAreas.gallery,
            actionType: VenueManagementActivityActionTypes.photoUploaded,
            entityType: VenueManagementActivityEntityTypes.media,
            entityId: 'media-1',
            entityName: 'Bar photo',
            description: 'Photo uploaded',
            actorUid: 'owner-1',
          ),
        ),
        completes,
      );
    });

    test('firebase permission failures are logged without throwing', () async {
      final service = DefaultVenueManagementActivityService(
        repository: _FirebaseDeniedActivityRepository(),
      );

      await expectLater(
        service.recordActivity(
          const VenueManagementActivity(
            venueId: 'venue-1',
            sourceArea: VenueManagementActivitySourceAreas.gallery,
            actionType: VenueManagementActivityActionTypes.photoUploaded,
            entityType: VenueManagementActivityEntityTypes.media,
            entityId: 'media-1',
            entityName: 'Bar photo',
            description: 'Photo uploaded',
            actorUid: 'owner-1',
          ),
        ),
        completes,
      );
    });
  });

  group('VenueProfileRepository activity integration', () {
    test('records one profile activity after successful write', () async {
      final repository = InMemoryVenueManagementActivityRepository();
      final profileRepository = VenueProfileRepository(
        writeRepository: _SuccessfulProfileWriteRepository(),
        activityService: DefaultVenueManagementActivityService(
          repository: repository,
        ),
      );

      await profileRepository.updateVenueDescription(
        venueId: 'venue-1',
        description: 'Updated venue copy',
        context: _profileContext(userId: 'owner-1'),
      );

      expect(repository.records, hasLength(1));
      expect(repository.records.single.sourceArea, 'venue_profile');
      expect(repository.records.single.actionType, 'updated');
      expect(repository.records.single.description, 'Venue description updated');
      expect(repository.records.single.venueId, 'venue-1');
      expect(repository.records.single.actorUid, 'owner-1');
    });

    test('failed profile write records no activity', () async {
      final repository = InMemoryVenueManagementActivityRepository();
      final profileRepository = VenueProfileRepository(
        writeRepository: _FailingProfileWriteRepository(),
        activityService: DefaultVenueManagementActivityService(
          repository: repository,
        ),
      );

      await expectLater(
        profileRepository.updateVenueDescription(
          venueId: 'venue-1',
          description: 'Updated copy',
          context: _profileContext(userId: 'owner-1'),
        ),
        throwsA(isA<VexException>()),
      );

      expect(repository.records, isEmpty);
    });
  });
}

VenueModelSnapshot _profileContext({required String userId}) {
  return VenueModelSnapshot(
    userId: userId,
    profile: const UserRoleProfile(
      role: VexdaUserRole.venueOwner,
      venueIds: ['venue-1'],
    ),
    venueOwnerId: 'owner-1',
    accessibleVenueIds: const ['venue-1'],
    name: 'Test Venue',
    description: 'Description',
    address: '1 Test Street',
    category: 'bar',
    crowdLevel: 'moderate',
  );
}

class _SuccessfulProfileWriteRepository implements VenueProfileWriteRepository {
  @override
  Future<DataResult<void>> applyVenueProfileUpdate({
    required String venueId,
    required VenueProfileUpdate update,
  }) async {
    return const DataSuccess(null);
  }
}

class _FailingProfileWriteRepository implements VenueProfileWriteRepository {
  @override
  Future<DataResult<void>> applyVenueProfileUpdate({
    required String venueId,
    required VenueProfileUpdate update,
  }) async {
    return const DataFailure(
      VexException('Write failed.', code: 'write-failed'),
    );
  }
}

class _ThrowingActivityRepository extends InMemoryVenueManagementActivityRepository {
  @override
  Future<String> append(VenueManagementActivity activity) {
    throw StateError('append failed');
  }
}

class _FirebaseDeniedActivityRepository
    extends InMemoryVenueManagementActivityRepository {
  @override
  Future<String> append(VenueManagementActivity activity) {
    throw FirebaseException(plugin: 'firestore', code: 'permission-denied');
  }
}
