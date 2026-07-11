import 'package:test/test.dart';
import 'package:vex_core/vex_core.dart';
import 'package:vex_engines/venue/application/venue_owner_profile_service.dart';

void main() {
  const service = VenueOwnerProfileService();

  Map<String, Map<String, dynamic>> defaultOpeningHours() {
    return {
      for (final day in const [
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday',
      ])
        day: {'closed': false, 'open': '18:00', 'close': '02:00'},
    };
  }

  VenueOwnerProfileDraft draft({
    String websiteUrl = '',
    Map<String, Map<String, dynamic>>? openingHours,
  }) {
    return VenueOwnerProfileDraft(
      name: 'Neon Room',
      description: 'Late-night cocktails',
      address: '1 Brick Lane',
      category: 'Bar',
      crowdLevel: 'busy',
      bannerImageUrl: 'https://cdn.example.com/banner.jpg',
      logoUrl: 'https://cdn.example.com/logo.jpg',
      websiteUrl: websiteUrl,
      openingHours: openingHours ?? defaultOpeningHours(),
    );
  }

  group('VenueOwnerProfileService.prepareCreate', () {
    test('builds valid create payload with branding and search terms', () {
      final result = service.prepareCreate(
        ownerId: 'owner-1',
        draft: draft(websiteUrl: 'winecentral.co.uk'),
      );

      expect(result, isA<DataSuccess<VenueOwnerProfilePreparedWrite>>());
      final prepared = (result as DataSuccess).value as VenueOwnerProfilePreparedWrite;
      expect(prepared.update.fields['ownerId'], 'owner-1');
      expect(prepared.update.fields['bannerImageUrl'], isNotEmpty);
      expect(prepared.update.fields['logoUrl'], isNotEmpty);
      expect(prepared.update.fields['websiteUrl'], 'https://winecentral.co.uk');
      expect(prepared.update.serverTimestampFields, ['createdAt']);
    });

    test('rejects blank owner id', () {
      final result = service.prepareCreate(
        ownerId: ' ',
        draft: draft(),
      );

      expect(result, isA<DataFailure>());
    });

    test('rejects invalid website', () {
      final result = service.prepareCreate(
        ownerId: 'owner-1',
        draft: draft(websiteUrl: 'not a url'),
      );

      expect(result, isA<DataFailure>());
    });

    test('rejects invalid opening hours', () {
      final result = service.prepareCreate(
        ownerId: 'owner-1',
        draft: draft(
          openingHours: {
            ...defaultOpeningHours(),
            'monday': {'closed': false, 'open': '99:00', 'close': '02:00'},
          },
        ),
      );

      expect(result, isA<DataFailure>());
    });
  });

  group('VenueOwnerProfileService.prepareUpdate', () {
    test('builds valid update payload with server timestamps', () {
      final result = service.prepareUpdate(
        venueId: 'venue-1',
        draft: draft(),
      );

      expect(result, isA<DataSuccess<VenueOwnerProfilePreparedWrite>>());
      final prepared = (result as DataSuccess).value as VenueOwnerProfilePreparedWrite;
      expect(
        prepared.update.serverTimestampFields,
        ['updatedAt', 'crowdUpdatedAt'],
      );
    });

    test('rejects blank venue id', () {
      final result = service.prepareUpdate(
        venueId: '',
        draft: draft(),
      );

      expect(result, isA<DataFailure>());
    });
  });

  group('venueWritePayloadFromPreparedWrite', () {
    test('preserves coordinates separately from field map', () {
      final prepared = service.prepareCreate(
        ownerId: 'owner-1',
        draft: VenueOwnerProfileDraft(
          name: 'Neon Room',
          description: 'Late-night cocktails',
          address: '1 Brick Lane',
          category: 'Bar',
          crowdLevel: 'busy',
          openingHours: defaultOpeningHours(),
          latitude: 51.52,
          longitude: -0.08,
        ),
      );

      final payload = venueWritePayloadFromPreparedWrite(
        (prepared as DataSuccess).value as VenueOwnerProfilePreparedWrite,
      );

      expect(payload.coordinates?.latitude, 51.52);
      expect(payload.coordinates?.longitude, -0.08);
    });
  });
}
