import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_app/features/auth/services/user_role_service.dart';

void main() {
  group('UserRoleService.parseRole', () {
    test('maps venue owner aliases', () {
      expect(UserRoleService.parseRole('owner'), AppUserRole.owner);
      expect(UserRoleService.parseRole('venueOwner'), AppUserRole.owner);
      expect(UserRoleService.parseRole('venue_owner'), AppUserRole.owner);
      expect(UserRoleService.parseRole('business'), AppUserRole.owner);
      expect(UserRoleService.parseRole('businessOwner'), AppUserRole.owner);
      expect(UserRoleService.parseRole('business_owner'), AppUserRole.owner);
      expect(UserRoleService.parseRole('venue'), AppUserRole.owner);
    });

    test('maps admin aliases', () {
      expect(UserRoleService.parseRole('admin'), AppUserRole.admin);
      expect(UserRoleService.parseRole('founder'), AppUserRole.founder);
      expect(UserRoleService.parseRole('management'), AppUserRole.management);
    });

    test('maps employee role', () {
      expect(UserRoleService.parseRole('employee'), AppUserRole.employee);
    });
  });

  group('UserRoleService.resolveFromUserContext', () {
    test('grants owner when owned venues exist', () {
      expect(
        UserRoleService.resolveFromUserContext(
          data: const {'role': 'user'},
          venueIdsCount: 0,
          ownedVenuesCount: 1,
        ),
        AppUserRole.owner,
      );
      expect(
        UserRoleService.resolveFromUserContext(
          data: const {'role': 'owner'},
          venueIdsCount: 0,
          ownedVenuesCount: 0,
        ),
        AppUserRole.owner,
      );
    });
  });

  group('AppUserRole access flags', () {
    test('owner can manage venues', () {
      expect(AppUserRole.owner.canManageVenues, isTrue);
      expect(AppUserRole.owner.isBusiness, isTrue);
    });

    test('employee can manage venues', () {
      expect(AppUserRole.employee.canManageVenues, isTrue);
      expect(AppUserRole.employee.isBusiness, isTrue);
    });

    test('regular user cannot manage venues', () {
      expect(AppUserRole.user.canManageVenues, isFalse);
      expect(AppUserRole.user.isBusiness, isFalse);
    });
  });
}
