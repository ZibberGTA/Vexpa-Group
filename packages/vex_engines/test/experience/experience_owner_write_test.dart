import 'package:test/test.dart';
import 'package:vex_engines/experience/application/experience_drink_import_validator.dart';
import 'package:vex_engines/experience/application/experience_owner_write_service.dart';
import 'package:vex_engines/experience/domain/experience_drink_import.dart';

void main() {
  group('ExperienceOwnerWriteService — mobile deal writes', () {
    test('create fields preserve legacy mobile deal schema', () {
      final start = DateTime(2026, 7, 10, 17);
      final end = DateTime(2026, 7, 10, 20);

      final fields = ExperienceOwnerWriteService.mobileDealCreateFields(
        venueId: 'v1',
        venueName: 'The Fox',
        title: ' 2 for 1 ',
        description: ' Before 8 ',
        startDateTime: start,
        endDateTime: end,
        startTime: '17:00',
        endTime: '20:00',
      );

      expect(fields['dealType'], 'drink_offer');
      expect(fields['title'], '2 for 1');
      expect(fields['isActive'], isTrue);
      expect(fields['isDeleted'], isFalse);
      expect(fields['searchTerms'], contains('17:00'));
      expect(fields['searchTerms'], contains('the fox'));
    });

    test('validate create rejects incomplete form', () {
      expect(
        ExperienceOwnerWriteService.validateMobileDealCreate(
          title: '',
          description: 'desc',
          startTime: '17:00',
          endTime: '20:00',
          startDate: DateTime(2026, 7, 10),
          endDate: DateTime(2026, 7, 10),
        ),
        isNotNull,
      );
    });

    test('validate create rejects end before start', () {
      expect(
        ExperienceOwnerWriteService.validateMobileDealCreate(
          title: 'Deal',
          description: 'Desc',
          startTime: '20:00',
          endTime: '17:00',
          startDate: DateTime(2026, 7, 10),
          endDate: DateTime(2026, 7, 10),
        ),
        contains('End must be after start'),
      );
    });

    test('update fields trim values and keep active', () {
      final fields = ExperienceOwnerWriteService.mobileDealUpdateFields(
        title: ' Updated ',
        description: ' New ',
        startDateTime: DateTime(2026, 7, 11, 18),
        endDateTime: DateTime(2026, 7, 11, 21),
        startTime: '18:00',
        endTime: '21:00',
      );

      expect(fields['title'], 'Updated');
      expect(fields['isActive'], isTrue);
    });
  });

  group('ExperienceOwnerWriteService — mobile drink writes', () {
    test('preset drink create normalizes category and builds search terms', () {
      final fields = ExperienceOwnerWriteService.mobilePresetDrinkCreateFields(
        venueId: 'v1',
        venueName: 'Bar',
        drinkName: 'Guinness',
        categoryDisplayName: 'Beer',
        price: 5.5,
      );

      expect(fields['category'], 'beer');
      expect(fields['isPresetDrink'], isTrue);
      expect(fields['available'], isTrue);
      expect(fields['searchTerms'], contains('guinness'));
    });

    test('edit fields preserve string price for legacy mobile schema', () {
      final fields = ExperienceOwnerWriteService.mobileDrinkEditFields(
        name: ' Guinness ',
        category: ' Beer ',
        price: ' 5.50 ',
        description: ' Pint ',
      );

      expect(fields['price'], '5.50');
      expect(fields['name'], 'Guinness');
    });

    test('validate edit requires all fields', () {
      expect(
        ExperienceOwnerWriteService.validateMobileDrinkEdit(
          name: 'Guinness',
          category: 'Beer',
          price: '',
          description: 'Pint',
        ),
        isNotNull,
      );
    });

    test('validate preset price accepts empty and rejects malformed', () {
      expect(
        ExperienceOwnerWriteService.validatePresetDrinkPrice(
          drinkName: 'Guinness',
          priceText: '',
        ),
        isNull,
      );
      expect(
        ExperienceOwnerWriteService.validatePresetDrinkPrice(
          drinkName: 'Guinness',
          priceText: 'abc',
        ),
        contains('valid price'),
      );
    });
  });

  group('ExperienceOwnerWriteService — mobile event writes', () {
    test('create fields match legacy mobile event schema', () {
      final start = DateTime(2026, 7, 12, 20);
      final end = DateTime(2026, 7, 12, 24);

      final fields = ExperienceOwnerWriteService.mobileEventCreateFields(
        venueId: 'v1',
        title: ' DJ Night ',
        description: ' Live set ',
        startDateTime: start,
        endDateTime: end,
        category: 'DJ Night',
        imageUrl: ' https://example.com/poster.jpg ',
      );

      expect(fields['notificationSent'], isFalse);
      expect(fields['isDeleted'], isFalse);
      expect(fields['imageUrl'], 'https://example.com/poster.jpg');
      expect(fields['dateTime'], start);
    });

    test('validate event create rejects end before start', () {
      final start = DateTime(2026, 7, 12, 22);
      final end = DateTime(2026, 7, 12, 20);

      expect(
        ExperienceOwnerWriteService.validateMobileEventCreate(
          title: 'Event',
          description: 'Desc',
          startDateTime: start,
          endDateTime: end,
        ),
        contains('after start'),
      );
    });

    test('default end uses 4 hour fallback', () {
      final start = DateTime(2026, 7, 12, 20);
      final end = ExperienceOwnerWriteService.defaultMobileEventEnd(start: start);
      expect(end, start.add(const Duration(hours: 4)));
    });
  });

  group('ExperienceDrinkImportValidator', () {
    test('validate ready row', () {
      final row = ExperienceDrinkImportValidator.validateRow(
        rowNumber: 2,
        name: 'Peroni',
        category: 'Beer',
        priceRaw: '5.50',
        availableRaw: 'true',
        featuredRaw: 'false',
        existingDrinkNames: const {},
        isAllowedCategory: ExperienceDrinkImportValidator.isAllowedCategory,
      );

      expect(row.status, ExperienceDrinkImportRowStatus.ready);
      expect(row.isBlocking, isFalse);
      expect(row.price, 5.50);
    });

    test('validate duplicate row is non-blocking warning', () {
      final row = ExperienceDrinkImportValidator.validateRow(
        rowNumber: 3,
        name: 'Peroni',
        category: 'Beer',
        priceRaw: '',
        availableRaw: '',
        featuredRaw: '',
        existingDrinkNames: {'peroni'},
        isAllowedCategory: ExperienceDrinkImportValidator.isAllowedCategory,
      );

      expect(row.status, ExperienceDrinkImportRowStatus.possibleDuplicate);
      expect(row.isBlocking, isFalse);
      expect(row.isDuplicateWarning, isTrue);
    });

    test('validate malformed price is blocking', () {
      final row = ExperienceDrinkImportValidator.validateRow(
        rowNumber: 4,
        name: 'Peroni',
        category: 'Beer',
        priceRaw: 'not-a-price',
        availableRaw: '',
        featuredRaw: '',
        existingDrinkNames: const {},
        isAllowedCategory: ExperienceDrinkImportValidator.isAllowedCategory,
      );

      expect(row.status, ExperienceDrinkImportRowStatus.invalidPrice);
      expect(row.isBlocking, isTrue);
    });

    test('rowsToCommit excludes blocking and respects duplicate flag', () {
      final rows = [
        ExperienceDrinkImportValidator.validateRow(
          rowNumber: 2,
          name: 'Peroni',
          category: 'Beer',
          priceRaw: '5',
          availableRaw: '',
          featuredRaw: '',
          existingDrinkNames: const {},
          isAllowedCategory: ExperienceDrinkImportValidator.isAllowedCategory,
        ),
        ExperienceDrinkImportValidator.validateRow(
          rowNumber: 3,
          name: 'Guinness',
          category: 'Beer',
          priceRaw: '',
          availableRaw: '',
          featuredRaw: '',
          existingDrinkNames: {'guinness'},
          isAllowedCategory: ExperienceDrinkImportValidator.isAllowedCategory,
        ),
        ExperienceDrinkImportValidator.validateRow(
          rowNumber: 4,
          name: '',
          category: 'Beer',
          priceRaw: '',
          availableRaw: '',
          featuredRaw: '',
          existingDrinkNames: const {},
          isAllowedCategory: ExperienceDrinkImportValidator.isAllowedCategory,
        ),
      ];

      final withoutDuplicates = ExperienceDrinkImportValidator.rowsToCommit(
        rows: rows,
        includeDuplicates: false,
      );
      expect(withoutDuplicates, hasLength(1));
      expect(withoutDuplicates.first.name, 'Peroni');

      final withDuplicates = ExperienceDrinkImportValidator.rowsToCommit(
        rows: rows,
        includeDuplicates: true,
      );
      expect(withDuplicates, hasLength(2));
    });

    test('parseOptionalBoolean handles common values', () {
      expect(ExperienceDrinkImportValidator.parseOptionalBoolean('yes'), isTrue);
      expect(ExperienceDrinkImportValidator.parseOptionalBoolean('0'), isFalse);
      expect(ExperienceDrinkImportValidator.parseOptionalBoolean('maybe'), isNull);
    });
  });
}
