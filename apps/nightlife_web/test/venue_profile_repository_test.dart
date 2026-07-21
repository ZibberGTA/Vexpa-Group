import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/features/auth/services/user_role_service.dart';
import 'package:nightlife_web/features/venue_management/data/venue_profile_repository.dart';
import 'package:nightlife_web/features/venue_management/services/venue_media_access_service.dart';
import 'package:vex_core/vex_core.dart';
import 'package:vex_engines/venue/application/venue_profile_update.dart';
import 'package:vex_engines/venue/application/venue_profile_update_service.dart';
import 'package:vex_engines/venue/data/venue_profile_write_repository.dart';

import 'venue_management_activity_test_support.dart';

final class MockVenueProfileWriteRepository
    implements VenueProfileWriteRepository {
  MockVenueProfileWriteRepository({this.result = const DataSuccess(null)});

  DataResult<void> result;
  int callCount = 0;
  String? lastVenueId;
  VenueProfileUpdate? lastUpdate;

  @override
  Future<DataResult<void>> applyVenueProfileUpdate({
    required String venueId,
    required VenueProfileUpdate update,
  }) async {
    callCount++;
    lastVenueId = venueId;
    lastUpdate = update;
    return result;
  }
}

VenueModelSnapshot _ownerContext({String venueId = 'venue-1'}) {
  return VenueModelSnapshot(
    userId: 'owner-1',
    profile: UserRoleProfile(
      role: VexdaUserRole.venueOwner,
      venueIds: [venueId],
    ),
    venueOwnerId: 'owner-1',
    accessibleVenueIds: const [],
    name: 'Copper Lantern',
    description: 'A neighbourhood bar.',
    address: '12 High Street',
    category: 'Bar',
    crowdLevel: 'moderate',
  );
}

void main() {
  registerDefaultVenueManagementActivityTestIsolation();

  group('VenueProfileRepository via Venue Engine', () {
    test('delegates name update to write repository once', () async {
      final writeRepository = MockVenueProfileWriteRepository();
      final repository = VenueProfileRepository(
        updateService: const VenueProfileUpdateService(),
        writeRepository: writeRepository,
      );

      await repository.updateVenueName(
        venueId: 'venue-1',
        name: 'New Name',
        context: _ownerContext(),
      );

      expect(writeRepository.callCount, 1);
      expect(writeRepository.lastVenueId, 'venue-1');
      expect(writeRepository.lastUpdate?.fields['name'], 'New Name');
    });

    test('does not call write repository when validation fails', () async {
      final writeRepository = MockVenueProfileWriteRepository();
      final repository = VenueProfileRepository(
        updateService: const VenueProfileUpdateService(),
        writeRepository: writeRepository,
      );

      expect(
        () => repository.updateVenueWebsite(
          venueId: 'venue-1',
          website: 'not a url',
          context: _ownerContext(),
        ),
        throwsA(isA<VexException>()),
      );
      expect(writeRepository.callCount, 0);
    });

    test('delegates contact details update to write repository once', () async {
      final writeRepository = MockVenueProfileWriteRepository();
      final repository = VenueProfileRepository(
        updateService: const VenueProfileUpdateService(),
        writeRepository: writeRepository,
      );

      await repository.updateVenueContactDetails(
        venueId: 'venue-1',
        phone: '020 7946 0958',
        email: 'hello@example.com',
        context: _ownerContext(),
      );

      expect(writeRepository.callCount, 1);
      expect(writeRepository.lastUpdate?.fields['phone'], '020 7946 0958');
      expect(writeRepository.lastUpdate?.fields['email'], 'hello@example.com');
    });

    test('does not call write repository when permission is denied', () async {
      final writeRepository = MockVenueProfileWriteRepository();
      final repository = VenueProfileRepository(
        updateService: const VenueProfileUpdateService(),
        writeRepository: writeRepository,
      );

      expect(
        () => repository.updateVenueName(
          venueId: 'venue-1',
          name: 'New Name',
          context: VenueModelSnapshot(
            userId: 'other-user',
            profile: const UserRoleProfile(role: VexdaUserRole.regularUser),
            venueOwnerId: 'owner-1',
            accessibleVenueIds: const [],
            name: 'Copper Lantern',
            description: '',
            address: '',
            category: 'Bar',
            crowdLevel: 'moderate',
          ),
        ),
        throwsA(isA<VenueMediaAccessDeniedException>()),
      );
      expect(writeRepository.callCount, 0);
    });

    test('preserves repository failure', () async {
      final writeRepository = MockVenueProfileWriteRepository(
        result: DataFailure(
          const VexException('denied', code: 'permission-denied'),
        ),
      );
      final repository = VenueProfileRepository(
        updateService: const VenueProfileUpdateService(),
        writeRepository: writeRepository,
      );

      expect(
        () => repository.updateVenueName(
          venueId: 'venue-1',
          name: 'New Name',
          context: _ownerContext(),
        ),
        throwsA(isA<VexException>()),
      );
      expect(writeRepository.callCount, 1);
    });
  });
}
