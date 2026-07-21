import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_app/core/utils/public_venue_visibility.dart';
import 'package:nightlife_app/core/vexcore/mobile_venue_document_mapper.dart';

void main() {
  group('venue catalog visibility regression', () {
    test('includes venue when searchablePublic is true', () {
      final data = {
        'isDeleted': false,
        'searchablePublic': true,
        'status': 'active',
      };

      expect(PublicVenueVisibility.isPublicMap(data), isTrue);
      expect(MobileVenueDocumentMapper.isCatalogVisible(data), isTrue);
      expect(
        MobileVenueDocumentMapper.parseHomeVenueModel('legacy-1', {
          ...data,
          'name': 'Visible Pub',
          'category': 'Bar',
        }),
        isNotNull,
      );
    });

    test('includes venue when searchablePublic is missing', () {
      final data = {
        'isDeleted': false,
        'status': 'active',
      };

      expect(PublicVenueVisibility.isPublicMap(data), isTrue);
      expect(MobileVenueDocumentMapper.isCatalogVisible(data), isTrue);
      expect(
        MobileVenueDocumentMapper.parseHomeVenueModel('legacy-2', {
          ...data,
          'name': 'Legacy Pub',
          'category': 'Bar',
        }),
        isNotNull,
      );
    });

    test('excludes venue when searchablePublic is false via adapter filtering', () {
      final data = {
        'isDeleted': false,
        'searchablePublic': false,
        'status': 'active',
      };

      expect(PublicVenueVisibility.isPublicMap(data), isFalse);
      expect(MobileVenueDocumentMapper.isCatalogVisible(data), isFalse);
      expect(
        MobileVenueDocumentMapper.parseHomeVenueModel('hidden-1', {
          ...data,
          'name': 'Hidden Pub',
          'category': 'Bar',
        }),
        isNull,
      );
    });

    test('excludes venue when isDeleted is true', () {
      final data = {
        'isDeleted': true,
        'searchablePublic': true,
        'status': 'active',
      };

      expect(PublicVenueVisibility.isPublicMap(data), isFalse);
      expect(MobileVenueDocumentMapper.isCatalogVisible(data), isFalse);
      expect(
        MobileVenueDocumentMapper.parseHomeVenueModel('deleted-1', {
          ...data,
          'name': 'Deleted Pub',
          'category': 'Bar',
        }),
        isNull,
      );
    });
  });
}
