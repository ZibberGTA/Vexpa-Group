import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/features/venue/data/models/drink_model.dart';
import 'package:nightlife_web/features/venue/data/venue_drinks_repository.dart';
import 'package:nightlife_web/features/venue_management/data/drink_spreadsheet_service.dart';
import 'package:nightlife_web/features/venue_management/models/bulk_drink_patch.dart';
import 'package:nightlife_web/features/venue_management/models/drink_categories.dart';
import 'package:nightlife_web/features/venue_management/models/drink_import_row.dart';
import 'package:nightlife_web/features/venue_management/models/featured_drinks_limit.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_context.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_tab.dart';
import 'package:nightlife_web/features/venue_management/widgets/drinks/add_drink_dialog.dart';
import 'package:nightlife_web/features/venue_management/widgets/drinks/bulk_edit_drinks_table.dart';
import 'package:nightlife_web/features/venue_management/widgets/drinks/drink_selection_checkbox.dart';
import 'package:nightlife_web/features/venue_management/widgets/drinks/drink_table_sort.dart';
import 'package:nightlife_web/features/venue_management/widgets/drinks/edit_drink_dialog.dart';
import 'package:nightlife_web/features/venue_management/widgets/drinks/venue_drinks_management_page.dart';
import 'package:nightlife_web/features/venue_management/widgets/venue_dashboard_controller.dart';
import 'package:nightlife_web/features/venue_management/widgets/venue_dashboard_shell.dart';

import 'venue_dashboard_test_data.dart';
import 'venue_management_activity_test_support.dart';

Uint8List buildDrinksImportCsv(List<List<String>> rows) {
  final content = csv.encode(rows);
  return Uint8List.fromList(utf8.encode(content));
}

void seedSortableDrinks(FakeVenueDrinksRepository repository) {
  repository.seedDrink(
    id: 'sort-a',
    name: 'Zulu Ale',
    category: 'Beer',
    price: 8.0,
    available: false,
    featured: false,
  );
  repository.seedDrink(
    id: 'sort-b',
    name: 'Alpha Gin',
    category: 'Gin',
    price: 4.0,
    available: true,
    featured: true,
  );
  repository.seedDrink(
    id: 'sort-c',
    name: 'Mid Lager',
    category: 'Cocktails',
    price: 6.0,
    available: true,
    featured: false,
  );
}

double drinkNameTop(WidgetTester tester, String name) {
  return tester.getRect(find.text(name).first).top;
}

Future<void> doubleTapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  registerDefaultVenueManagementActivityTestIsolation();

  group('Venue dashboard Support tab', () {
    testWidgets('Support tab appears in sidebar before Settings', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: VenueDashboardShell(
            contextData: VenueDashboardContext.placeholder(),
            homeData: VenueDashboardTestData.sampleHomeData(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(VenueDashboardTab.support.label), findsOneWidget);
      expect(
        VenueDashboardTab.values.indexOf(VenueDashboardTab.support),
        lessThan(VenueDashboardTab.values.indexOf(VenueDashboardTab.settings)),
      );
    });

    testWidgets('Support page loads in dashboard shell', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: VenueDashboardShell(
            contextData: VenueDashboardContext.placeholder(),
            homeData: VenueDashboardTestData.sampleHomeData(),
            initialTab: VenueDashboardTab.support,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Support'), findsWidgets);
      expect(
        find.text('Raise tickets and get help from the Vexda team.'),
        findsOneWidget,
      );
      expect(find.text('Open Tickets'), findsWidgets);
      expect(find.text('Create Support Ticket'), findsOneWidget);
      expect(find.text('Ticket History'), findsWidgets);
      expect(find.text('Create Ticket'), findsWidgets);
    });
  });

  group('VenueDrinksManagementPage', () {
    late FakeVenueDrinksRepository repository;

    setUp(() {
      repository = FakeVenueDrinksRepository();
    });

    tearDown(() {
      repository.dispose();
    });

    Future<void> pumpDrinksPage(
      WidgetTester tester, {
      Future<({Uint8List bytes, String filename})?> Function()? testPickFile,
      void Function(Uint8List bytes, String filename)? testDownloadBytes,
    }) async {
      tester.view.physicalSize = const Size(1440, 1100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: VenueDashboardController(
              selectTab: (_, {pendingActionKey}) {},
              contextData: const VenueDashboardContext(
                ownerName: 'Alex Morgan',
                ownerFirstName: 'Alex',
                venueName: 'Copper Lantern',
                venueId: 'venue-test',
              ),
              child: VenueDrinksManagementPage(
                repository: repository,
                testCreatedBy: 'owner-test',
                testPickFile: testPickFile,
                testDownloadBytes: testDownloadBytes,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows empty state when venue has no drinks', (
      WidgetTester tester,
    ) async {
      await pumpDrinksPage(tester);

      expect(find.text('No drinks added yet.'), findsOneWidget);
      expect(
        find.text('Add your first drink to start building your menu.'),
        findsOneWidget,
      );
    });

    testWidgets('Add Drink quick action opens modal', (WidgetTester tester) async {
      await pumpDrinksPage(tester);

      await tester.tap(find.text('Add Drink').last);
      await tester.pumpAndSettle();

      expect(find.text('Add a drink to your venue menu.'), findsOneWidget);
      expect(find.widgetWithText(DropdownButtonFormField<String>, 'Category'), findsOneWidget);
    });

    testWidgets('validates drink name and category in modal', (
      WidgetTester tester,
    ) async {
      await pumpDrinksPage(tester);

      await tester.tap(find.text('Add Drink').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Drink').last);
      await tester.pumpAndSettle();

      expect(find.text('Enter a drink name.'), findsOneWidget);
      expect(find.text('Select a category.'), findsOneWidget);
    });

    testWidgets('category dropdown only offers fixed categories', (
      WidgetTester tester,
    ) async {
      await pumpDrinksPage(tester);

      await tester.tap(find.text('Add Drink').last);
      await tester.pumpAndSettle();

      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      expect(DrinkCategories.all, hasLength(21));
      expect(DrinkCategories.isAllowed('Custom Category'), isFalse);
    });

    testWidgets('saving drink updates drinks list without reload', (
      WidgetTester tester,
    ) async {
      await pumpDrinksPage(tester);

      await tester.tap(find.text('Add Drink').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Espresso Martini');
      await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Category'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cocktails').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Drink').last);
      await tester.pumpAndSettle();

      expect(find.text('Drink added to your menu.'), findsOneWidget);
      expect(find.text('Espresso Martini'), findsOneWidget);
      expect(find.text('No drinks added yet.'), findsNothing);
      expect(repository.lastAddedDrink?.name, 'Espresso Martini');
      expect(repository.lastAddedDrink?.category, 'cocktails');
    });

    testWidgets('search clear X appears only when search has text', (
      WidgetTester tester,
    ) async {
      repository.seedDrink(name: 'House Lager', category: 'Beer');
      await pumpDrinksPage(tester);

      expect(find.byIcon(Icons.close_rounded), findsNothing);

      await tester.enterText(find.byType(TextField), 'House');
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('search clear X clears search and resets list', (
      WidgetTester tester,
    ) async {
      repository.seedDrink(name: 'House Lager', category: 'Beer');
      repository.seedDrink(name: 'Espresso Martini', category: 'Cocktails');
      await pumpDrinksPage(tester);

      await tester.enterText(find.byType(TextField), 'Espresso');
      await tester.pumpAndSettle();

      expect(find.text('Espresso Martini'), findsOneWidget);
      expect(find.text('House Lager'), findsNothing);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('House Lager'), findsOneWidget);
      expect(find.text('Espresso Martini'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('shows All and Categories dropdown instead of category chips', (
      WidgetTester tester,
    ) async {
      repository.seedDrink(id: 'drink-a', name: 'House Lager', category: 'Beer');
      repository.seedDrink(id: 'drink-b', name: 'Gin Fizz', category: 'Cocktails');
      await pumpDrinksPage(tester);

      expect(find.text('All'), findsOneWidget);
      expect(find.byKey(const Key('drinks_categories_filter_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('drinks_categories_filter_button')));
      await tester.pumpAndSettle();

      for (final category in DrinkCategories.all) {
        expect(find.byKey(Key('drinks_category_filter_$category')), findsOneWidget);
      }
    });

    testWidgets('multi-select category filter shows drinks matching any category', (
      WidgetTester tester,
    ) async {
      repository.seedDrink(id: 'drink-a', name: 'House Lager', category: 'Beer');
      repository.seedDrink(id: 'drink-b', name: 'Gin Fizz', category: 'Cocktails');
      repository.seedDrink(id: 'drink-c', name: 'Merlot Glass', category: 'Wine');
      await pumpDrinksPage(tester);

      await tester.tap(find.byKey(const Key('drinks_categories_filter_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('drinks_category_filter_Beer')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('drinks_category_filter_Cocktails')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(find.text('Categories (2)'), findsOneWidget);
      expect(find.text('House Lager'), findsOneWidget);
      expect(find.text('Gin Fizz'), findsOneWidget);
      expect(find.text('Merlot Glass'), findsNothing);
    });

    testWidgets('All filter clears selected categories and shows every drink', (
      WidgetTester tester,
    ) async {
      repository.seedDrink(id: 'drink-a', name: 'House Lager', category: 'Beer');
      repository.seedDrink(id: 'drink-b', name: 'Gin Fizz', category: 'Cocktails');
      repository.seedDrink(id: 'drink-c', name: 'Merlot Glass', category: 'Wine');
      await pumpDrinksPage(tester);

      await tester.tap(find.byKey(const Key('drinks_categories_filter_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('drinks_category_filter_Beer')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(find.text('Categories (1)'), findsOneWidget);
      expect(find.text('Merlot Glass'), findsNothing);

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(find.text('Categories (1)'), findsNothing);
      expect(find.byKey(const Key('drinks_categories_filter_button')), findsOneWidget);
      expect(find.text('House Lager'), findsOneWidget);
      expect(find.text('Gin Fizz'), findsOneWidget);
      expect(find.text('Merlot Glass'), findsOneWidget);
    });

    testWidgets('search and category filters work together', (
      WidgetTester tester,
    ) async {
      repository.seedDrink(id: 'drink-a', name: 'Premium Lager', category: 'Beer');
      repository.seedDrink(id: 'drink-b', name: 'House Lager', category: 'Beer');
      repository.seedDrink(id: 'drink-c', name: 'Gin Fizz', category: 'Cocktails');
      await pumpDrinksPage(tester);

      await tester.tap(find.byKey(const Key('drinks_categories_filter_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('drinks_category_filter_Beer')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Premium');
      await tester.pumpAndSettle();

      expect(find.text('Premium Lager'), findsOneWidget);
      expect(find.text('House Lager'), findsNothing);
      expect(find.text('Gin Fizz'), findsNothing);
    });

    testWidgets('Bulk Import quick action opens import modal', (WidgetTester tester) async {
      await pumpDrinksPage(tester);

      await tester.tap(find.text('Bulk Import').last);
      await tester.pumpAndSettle();

      expect(find.text('Bulk Import Drinks'), findsOneWidget);
      expect(
        find.text('Upload an Excel file to add multiple drinks to your venue menu.'),
        findsOneWidget,
      );
      expect(find.text('Upload Excel File'), findsOneWidget);
      expect(find.text('Download Template'), findsOneWidget);
    });

    testWidgets('Download Template generates spreadsheet with required columns', (
      WidgetTester tester,
    ) async {
      ({Uint8List bytes, String filename})? download;

      await pumpDrinksPage(
        tester,
        testDownloadBytes: (bytes, filename) => download = (bytes: bytes, filename: filename),
      );

      await tester.tap(find.text('Bulk Import').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Download Template'));
      await tester.pumpAndSettle();

      expect(download, isNotNull);
      expect(download!.filename, DrinkSpreadsheetService.templateFilename);

      final parsed = DrinkSpreadsheetService.parseFile(
        bytes: download!.bytes,
        filename: download!.filename,
        existingDrinkNames: const {},
      );
      expect(parsed.fileError, isNull);
      expect(parsed.rows, hasLength(2));
    });

    testWidgets('uploaded valid file shows preview and imports drinks', (
      WidgetTester tester,
    ) async {
      await pumpDrinksPage(
        tester,
        testPickFile: () async => (
          bytes: buildDrinksImportCsv([
            DrinkSpreadsheetService.requiredColumns,
            ['Negroni', 'Cocktails', '12.00', 'true', 'false'],
          ]),
          filename: 'drinks.csv',
        ),
      );

      await tester.tap(find.text('Bulk Import').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Upload Excel File'));
      await tester.pumpAndSettle();

      expect(find.text('Ready'), findsOneWidget);
      expect(find.text('Import preview'), findsOneWidget);

      await tester.tap(find.text('Import Drinks'));
      await tester.pumpAndSettle();

      expect(find.text('Drinks imported successfully.'), findsOneWidget);
      expect(find.text('Negroni'), findsOneWidget);
      expect(repository.lastImportedDrinks, hasLength(1));
      expect(repository.lastImportedDrinks.single.name, 'Negroni');
    });

    testWidgets('Import Drinks button stays disabled when validation errors exist', (
      WidgetTester tester,
    ) async {
      await pumpDrinksPage(
        tester,
        testPickFile: () async => (
          bytes: buildDrinksImportCsv([
            DrinkSpreadsheetService.requiredColumns,
            ['', 'Beer', '6.20', 'true', 'false'],
          ]),
          filename: 'drinks.csv',
        ),
      );

      await tester.tap(find.text('Bulk Import').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Upload Excel File'));
      await tester.pumpAndSettle();

      expect(find.text('Missing name'), findsOneWidget);
      expect(
        find.text('Fix the highlighted rows before importing drinks.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Import Drinks'));
      await tester.pumpAndSettle();

      expect(find.text('Drinks imported successfully.'), findsNothing);
      expect(repository.lastImportedDrinks, isEmpty);
    });

    testWidgets('Export Drinks downloads spreadsheet with current venue drinks', (
      WidgetTester tester,
    ) async {
      repository.seedDrink(id: 'drink-a', name: 'House Lager', category: 'Beer', price: 5.5);
      repository.seedDrink(id: 'drink-b', name: 'Gin Fizz', category: 'Cocktails', price: 9.0);

      ({Uint8List bytes, String filename})? download;

      await pumpDrinksPage(
        tester,
        testDownloadBytes: (bytes, filename) => download = (bytes: bytes, filename: filename),
      );

      await tester.tap(find.text('Export Drinks').last);
      await tester.pumpAndSettle();

      expect(download, isNotNull);
      expect(download!.filename, startsWith('vexda-drinks-copper-lantern-'));

      final parsed = DrinkSpreadsheetService.parseFile(
        bytes: download!.bytes,
        filename: download!.filename,
        existingDrinkNames: const {},
      );
      expect(parsed.fileError, isNull);
      expect(parsed.rows, hasLength(2));
      expect(parsed.rows.map((row) => row.name), ['House Lager', 'Gin Fizz']);
    });

    testWidgets('clicking drink opens Edit Drink modal with prefilled data', (
      WidgetTester tester,
    ) async {
      repository.seedDrink(
        id: 'drink-edit-1',
        name: 'Old Fashioned',
        category: 'Cocktails',
        price: 12.5,
        description: 'Classic bourbon cocktail',
        featured: true,
      );
      await pumpDrinksPage(tester);

      await doubleTapText(tester, 'Old Fashioned');

      expect(find.text('Edit Drink'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Delete Drink'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Old Fashioned'), findsOneWidget);
    });

    testWidgets('Save Changes updates existing drink without creating duplicate', (
      WidgetTester tester,
    ) async {
      repository.seedDrink(
        id: 'drink-edit-2',
        name: 'House Lager',
        category: 'Beer',
        price: 5.8,
      );
      await pumpDrinksPage(tester);

      expect(repository.activeDrinks.length, 1);

      await doubleTapText(tester, 'House Lager');

      await tester.enterText(find.widgetWithText(TextFormField, 'House Lager'), 'Premium Lager');
      await tester.tap(find.text('Save Changes').last);
      await tester.pumpAndSettle();

      expect(repository.activeDrinks.length, 1);
      expect(find.text('Premium Lager'), findsOneWidget);
      expect(find.text('House Lager'), findsNothing);
      expect(repository.lastUpdatedDrink?.id, 'drink-edit-2');
      expect(repository.lastUpdatedDrink?.name, 'Premium Lager');
    });

    testWidgets('Delete button opens confirmation dialog', (
      WidgetTester tester,
    ) async {
      repository.seedDrink(id: 'drink-delete-1', name: 'Smoked Negroni', category: 'Cocktails');
      await pumpDrinksPage(tester);

      await doubleTapText(tester, 'Smoked Negroni');
      await tester.tap(find.text('Delete Drink').first);
      await tester.pumpAndSettle();

      expect(find.text('Delete Drink?'), findsOneWidget);
      expect(
        find.text('Are you sure you want to delete this drink? This action cannot be undone.'),
        findsOneWidget,
      );
    });

    testWidgets('Cancel on confirmation does not delete drink', (
      WidgetTester tester,
    ) async {
      repository.seedDrink(id: 'drink-delete-2', name: 'Aperol Spritz', category: 'Cocktails');
      await pumpDrinksPage(tester);

      await doubleTapText(tester, 'Aperol Spritz');
      await tester.tap(find.text('Delete Drink').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();

      expect(repository.activeDrinks.length, 1);
      expect(repository.lastDeletedDrinkId, isNull);
    });

    testWidgets('confirm delete removes drink and updates list', (
      WidgetTester tester,
    ) async {
      repository.seedDrink(id: 'drink-delete-3', name: 'Gin Fizz', category: 'Cocktails');
      await pumpDrinksPage(tester);

      await doubleTapText(tester, 'Gin Fizz');
      await tester.tap(find.text('Delete Drink').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm_delete_drink_button')));
      await tester.pumpAndSettle();

      expect(repository.activeDrinks, isEmpty);
      expect(repository.lastDeletedDrinkId, 'drink-delete-3');
      expect(find.text('Gin Fizz'), findsNothing);
      expect(find.text('Drink deleted successfully.'), findsOneWidget);
    });

    testWidgets('checkbox appears next to each drink name', (
      WidgetTester tester,
    ) async {
      repository.seedDrink(id: 'drink-a', name: 'House Lager', category: 'Beer');
      repository.seedDrink(id: 'drink-b', name: 'Gin Fizz', category: 'Cocktails');
      await pumpDrinksPage(tester);

      expect(find.byKey(const Key('drink_select_drink-a')), findsOneWidget);
      expect(find.byKey(const Key('drink_select_drink-b')), findsOneWidget);
    });

    testWidgets('selecting one drink shows action bar', (WidgetTester tester) async {
      repository.seedDrink(id: 'drink-a', name: 'House Lager', category: 'Beer');
      await pumpDrinksPage(tester);

      expect(find.text('Selected:'), findsNothing);

      await tester.tap(find.byKey(const Key('drink_select_drink-a')));
      await tester.pumpAndSettle();

      expect(find.text('Selected: 1'), findsOneWidget);
      expect(find.text('Edit Drinks'), findsOneWidget);
      expect(find.text('Delete Drinks'), findsOneWidget);
      expect(find.text('Clear Selection'), findsOneWidget);
    });

    testWidgets('selecting multiple drinks updates Selected count', (
      WidgetTester tester,
    ) async {
      repository.seedDrink(id: 'drink-a', name: 'House Lager', category: 'Beer');
      repository.seedDrink(id: 'drink-b', name: 'Gin Fizz', category: 'Cocktails');
      await pumpDrinksPage(tester);

      await tester.tap(find.byKey(const Key('drink_select_drink-a')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('drink_select_drink-b')));
      await tester.pumpAndSettle();

      expect(find.text('Selected: 2'), findsOneWidget);
      expect(find.text('Clear Selection'), findsOneWidget);
    });

    testWidgets('Clear Selection clears all selected drinks and hides action bar', (
      WidgetTester tester,
    ) async {
      repository.seedDrink(id: 'drink-a', name: 'House Lager', category: 'Beer');
      repository.seedDrink(id: 'drink-b', name: 'Gin Fizz', category: 'Cocktails');
      await pumpDrinksPage(tester);

      await tester.tap(find.byKey(const Key('drink_select_drink-a')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('drink_select_drink-b')));
      await tester.pumpAndSettle();

      expect(find.text('Selected: 2'), findsOneWidget);
      expect(
        tester
            .widget<DrinkSelectionCheckbox>(
              find.byKey(const Key('drink_select_drink-a')),
            )
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<DrinkSelectionCheckbox>(
              find.byKey(const Key('drink_select_drink-b')),
            )
            .value,
        isTrue,
      );

      await tester.tap(find.text('Clear Selection'));
      await tester.pumpAndSettle();

      expect(find.text('Selected:'), findsNothing);
      expect(find.text('Clear Selection'), findsNothing);
      expect(
        tester
            .widget<DrinkSelectionCheckbox>(
              find.byKey(const Key('drink_select_drink-a')),
            )
            .value,
        isFalse,
      );
      expect(
        tester
            .widget<DrinkSelectionCheckbox>(
              find.byKey(const Key('drink_select_drink-b')),
            )
            .value,
        isFalse,
      );
      expect(repository.activeDrinks.length, 2);
      expect(repository.lastUpdatedDrink, isNull);
      expect(repository.lastDeletedDrinkId, isNull);
      expect(repository.lastBulkPatch, isNull);
    });

    testWidgets('checkbox click does not open edit modal', (WidgetTester tester) async {
      repository.seedDrink(id: 'drink-a', name: 'House Lager', category: 'Beer');
      await pumpDrinksPage(tester);

      await tester.tap(find.byKey(const Key('drink_select_drink-a')));
      await tester.pumpAndSettle();

      expect(find.text('Edit Drink'), findsNothing);
      expect(find.text('Selected: 1'), findsOneWidget);
    });

    testWidgets('double tap on name opens edit modal for advanced fields', (
      WidgetTester tester,
    ) async {
      repository.seedDrink(id: 'drink-a', name: 'House Lager', category: 'Beer');
      await pumpDrinksPage(tester);

      await tester.tap(find.text('House Lager'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('House Lager'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Drink'), findsOneWidget);
    });

    testWidgets('Edit Drinks opens single edit modal when one selected', (
      WidgetTester tester,
    ) async {
      repository.seedDrink(id: 'drink-a', name: 'House Lager', category: 'Beer');
      await pumpDrinksPage(tester);

      await tester.tap(find.byKey(const Key('drink_select_drink-a')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Drinks'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Drink'), findsOneWidget);
      expect(find.text('Bulk Edit Drinks'), findsNothing);
    });

    testWidgets('Edit Drinks opens bulk edit modal when multiple selected', (
      WidgetTester tester,
    ) async {
      repository.seedDrink(id: 'drink-a', name: 'House Lager', category: 'Beer');
      repository.seedDrink(id: 'drink-b', name: 'Gin Fizz', category: 'Cocktails');
      await pumpDrinksPage(tester);

      await tester.tap(find.byKey(const Key('drink_select_drink-a')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('drink_select_drink-b')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Drinks'));
      await tester.pumpAndSettle();

      expect(find.text('Bulk Edit Drinks'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Drink Name'), findsOneWidget);
      expect(find.text('Category'), findsWidgets);
      expect(find.text('Price'), findsWidgets);
      expect(find.text('Available'), findsWidgets);
      expect(find.text('Featured'), findsWidgets);
      expect(find.text('House Lager'), findsWidgets);
      expect(find.text('Gin Fizz'), findsWidgets);
    });

    testWidgets('bulk edit Save Changes updates selected drinks without duplicates', (
      WidgetTester tester,
    ) async {
      repository.seedDrink(
        id: 'drink-a',
        name: 'House Lager',
        category: 'Beer',
        price: 5.5,
      );
      repository.seedDrink(
        id: 'drink-b',
        name: 'Gin Fizz',
        category: 'Cocktails',
        price: 9.0,
      );
      await pumpDrinksPage(tester);

      expect(repository.activeDrinks.length, 2);

      await tester.tap(find.byKey(const Key('drink_select_drink-a')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('drink_select_drink-b')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Drinks'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'House Lager'),
        'Premium Lager',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Gin Fizz'),
        'Royal Gin Fizz',
      );
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(repository.activeDrinks.length, 2);
      expect(find.text('Premium Lager'), findsOneWidget);
      expect(find.text('Royal Gin Fizz'), findsOneWidget);
      expect(find.text('House Lager'), findsNothing);
      expect(find.text('Gin Fizz'), findsNothing);
    });

    testWidgets('Delete Drinks shows confirmation dialog', (WidgetTester tester) async {
      repository.seedDrink(id: 'drink-a', name: 'House Lager', category: 'Beer');
      repository.seedDrink(id: 'drink-b', name: 'Gin Fizz', category: 'Cocktails');
      await pumpDrinksPage(tester);

      await tester.tap(find.byKey(const Key('drink_select_drink-a')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('drink_select_drink-b')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Drinks').last);
      await tester.pumpAndSettle();

      expect(find.text('Delete Drinks?'), findsOneWidget);
      expect(
        find.text(
          'You are about to permanently delete 2 drink(s). This action cannot be undone.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('confirm bulk delete removes selected drinks', (WidgetTester tester) async {
      repository.seedDrink(id: 'drink-a', name: 'House Lager', category: 'Beer');
      repository.seedDrink(id: 'drink-b', name: 'Gin Fizz', category: 'Cocktails');
      await pumpDrinksPage(tester);

      await tester.tap(find.byKey(const Key('drink_select_drink-a')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('drink_select_drink-b')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Drinks').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm_bulk_delete_drinks_button')));
      await tester.pumpAndSettle();

      expect(repository.activeDrinks, isEmpty);
      expect(find.text('Selected:'), findsNothing);
      expect(find.text('2 drinks deleted successfully.'), findsOneWidget);
    });

    testWidgets('clicking Category sorts A-Z then Z-A with indicator', (
      WidgetTester tester,
    ) async {
      seedSortableDrinks(repository);
      await pumpDrinksPage(tester);

      await tester.tap(find.byKey(drinkSortColumnKey(DrinkSortColumn.category)));
      await tester.pumpAndSettle();

      expect(
        find.byKey(drinkSortIndicatorKey(DrinkSortColumn.category)),
        findsOneWidget,
      );
      expect(
        drinkNameTop(tester, 'Alpha Gin'),
        lessThan(drinkNameTop(tester, 'Zulu Ale')),
      );
      expect(
        drinkNameTop(tester, 'Zulu Ale'),
        lessThan(drinkNameTop(tester, 'Mid Lager')),
      );

      await tester.tap(find.byKey(drinkSortColumnKey(DrinkSortColumn.category)));
      await tester.pumpAndSettle();

      expect(
        drinkNameTop(tester, 'Alpha Gin'),
        lessThan(drinkNameTop(tester, 'Mid Lager')),
      );
      expect(
        drinkNameTop(tester, 'Mid Lager'),
        lessThan(drinkNameTop(tester, 'Zulu Ale')),
      );
    });

    testWidgets('clicking Price sorts low-high then high-low', (
      WidgetTester tester,
    ) async {
      seedSortableDrinks(repository);
      await pumpDrinksPage(tester);

      await tester.tap(find.byKey(drinkSortColumnKey(DrinkSortColumn.price)));
      await tester.pumpAndSettle();

      expect(
        find.byKey(drinkSortIndicatorKey(DrinkSortColumn.price)),
        findsOneWidget,
      );
      expect(
        drinkNameTop(tester, 'Alpha Gin'),
        lessThan(drinkNameTop(tester, 'Mid Lager')),
      );
      expect(
        drinkNameTop(tester, 'Mid Lager'),
        lessThan(drinkNameTop(tester, 'Zulu Ale')),
      );

      await tester.tap(find.byKey(drinkSortColumnKey(DrinkSortColumn.price)));
      await tester.pumpAndSettle();

      expect(
        drinkNameTop(tester, 'Alpha Gin'),
        lessThan(drinkNameTop(tester, 'Zulu Ale')),
      );
      expect(
        drinkNameTop(tester, 'Zulu Ale'),
        lessThan(drinkNameTop(tester, 'Mid Lager')),
      );
    });

    testWidgets('clicking Available sorts available first then unavailable first', (
      WidgetTester tester,
    ) async {
      seedSortableDrinks(repository);
      await pumpDrinksPage(tester);

      await tester.tap(find.byKey(drinkSortColumnKey(DrinkSortColumn.available)));
      await tester.pumpAndSettle();

      expect(
        drinkNameTop(tester, 'Alpha Gin'),
        lessThan(drinkNameTop(tester, 'Mid Lager')),
      );
      expect(
        drinkNameTop(tester, 'Mid Lager'),
        lessThan(drinkNameTop(tester, 'Zulu Ale')),
      );

      await tester.tap(find.byKey(drinkSortColumnKey(DrinkSortColumn.available)));
      await tester.pumpAndSettle();

      expect(
        drinkNameTop(tester, 'Alpha Gin'),
        lessThan(drinkNameTop(tester, 'Zulu Ale')),
      );
      expect(
        drinkNameTop(tester, 'Zulu Ale'),
        lessThan(drinkNameTop(tester, 'Mid Lager')),
      );
    });

    testWidgets('clicking Featured sorts featured first then not featured first', (
      WidgetTester tester,
    ) async {
      seedSortableDrinks(repository);
      await pumpDrinksPage(tester);

      await tester.tap(find.byKey(drinkSortColumnKey(DrinkSortColumn.featured)));
      await tester.pumpAndSettle();

      expect(
        drinkNameTop(tester, 'Alpha Gin'),
        lessThan(drinkNameTop(tester, 'Mid Lager')),
      );

      await tester.tap(find.byKey(drinkSortColumnKey(DrinkSortColumn.featured)));
      await tester.pumpAndSettle();

      expect(
        drinkNameTop(tester, 'Alpha Gin'),
        lessThan(drinkNameTop(tester, 'Zulu Ale')),
      );
      expect(
        drinkNameTop(tester, 'Zulu Ale'),
        lessThan(drinkNameTop(tester, 'Mid Lager')),
      );
    });

    testWidgets('search category filter and sorting work together', (
      WidgetTester tester,
    ) async {
      repository.seedDrink(
        id: 'extra',
        name: 'Alpha Wine',
        category: 'Wine',
        price: 12.0,
      );
      seedSortableDrinks(repository);
      await pumpDrinksPage(tester);

      await tester.enterText(find.byType(TextField), 'Alpha');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(drinkSortColumnKey(DrinkSortColumn.price)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(drinkSortColumnKey(DrinkSortColumn.price)));
      await tester.pumpAndSettle();

      expect(find.text('Alpha Gin'), findsOneWidget);
      expect(find.text('Alpha Wine'), findsOneWidget);
      expect(find.text('Mid Lager'), findsNothing);
      expect(
        drinkNameTop(tester, 'Alpha Gin'),
        lessThan(drinkNameTop(tester, 'Alpha Wine')),
      );
    });

    testWidgets('selected drinks remain selected after sorting', (
      WidgetTester tester,
    ) async {
      seedSortableDrinks(repository);
      await pumpDrinksPage(tester);

      await tester.tap(find.byKey(const Key('drink_select_sort-b')));
      await tester.pumpAndSettle();
      expect(find.text('Selected: 1'), findsOneWidget);

      await tester.tap(find.byKey(drinkSortColumnKey(DrinkSortColumn.price)));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<DrinkSelectionCheckbox>(
              find.byKey(const Key('drink_select_sort-b')),
            )
            .value,
        isTrue,
      );
      expect(find.text('Selected: 1'), findsOneWidget);
    });

    testWidgets('featured drinks appear above non-featured drinks', (
      WidgetTester tester,
    ) async {
      seedSortableDrinks(repository);
      await pumpDrinksPage(tester);

      expect(
        drinkNameTop(tester, 'Alpha Gin'),
        lessThan(drinkNameTop(tester, 'Mid Lager')),
      );
      expect(
        drinkNameTop(tester, 'Alpha Gin'),
        lessThan(drinkNameTop(tester, 'Zulu Ale')),
      );
    });

    testWidgets('featured styling appears only on featured drinks', (
      WidgetTester tester,
    ) async {
      seedSortableDrinks(repository);
      await pumpDrinksPage(tester);

      expect(find.byKey(drinkRowFeaturedBorderKey('sort-b')), findsOneWidget);
      expect(find.byKey(drinkRowFeaturedBorderKey('sort-a')), findsNothing);
      expect(find.byKey(drinkRowFeaturedBorderKey('sort-c')), findsNothing);
    });

    testWidgets('sorting still works within featured and non-featured groups', (
      WidgetTester tester,
    ) async {
      seedSortableDrinks(repository);
      await pumpDrinksPage(tester);

      await tester.tap(find.byKey(drinkSortColumnKey(DrinkSortColumn.name)));
      await tester.pumpAndSettle();

      expect(
        drinkNameTop(tester, 'Alpha Gin'),
        lessThan(drinkNameTop(tester, 'Zulu Ale')),
      );
      expect(
        drinkNameTop(tester, 'Zulu Ale'),
        lessThan(drinkNameTop(tester, 'Mid Lager')),
      );
    });

    testWidgets('export leaves blank price cells for drinks without valid prices', (
      WidgetTester tester,
    ) async {
      repository.seedDrink(
        id: 'no-price',
        name: 'Ask For Price',
        category: 'Cocktails',
        price: 0,
      );
      repository.seedDrink(
        id: 'with-price',
        name: 'House Lager',
        category: 'Beer',
        price: 5.5,
      );

      ({Uint8List bytes, String filename})? download;

      await pumpDrinksPage(
        tester,
        testDownloadBytes: (bytes, filename) => download = (bytes: bytes, filename: filename),
      );

      await tester.tap(find.text('Export Drinks').last);
      await tester.pumpAndSettle();

      expect(download, isNotNull);

      final parsed = DrinkSpreadsheetService.parseFile(
        bytes: download!.bytes,
        filename: download!.filename,
        existingDrinkNames: const {},
      );
      expect(parsed.fileError, isNull);

      final askForPrice = parsed.rows.firstWhere((row) => row.name == 'Ask For Price');
      final houseLager = parsed.rows.firstWhere((row) => row.name == 'House Lager');
      expect(askForPrice.priceRaw.trim(), isEmpty);
      expect(askForPrice.price, isNull);
      expect(houseLager.price, 5.5);
    });

    testWidgets('feature limit prevents adding more than five featured drinks', (
      WidgetTester tester,
    ) async {
      for (var i = 0; i < FeaturedDrinksLimit.maxFeaturedDrinks; i++) {
        repository.seedDrink(
          id: 'featured-$i',
          name: 'Featured Drink $i',
          category: 'Beer',
          featured: true,
        );
      }
      await pumpDrinksPage(tester);

      await tester.tap(find.text('Add Drink').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Sixth Featured');
      await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Category'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Beer').last);
      await tester.pumpAndSettle();

      final featuredSwitch = find.widgetWithText(SwitchListTile, 'Featured');
      await tester.tap(featuredSwitch);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Drink').last);
      await tester.pumpAndSettle();

      expect(find.text(FeaturedDrinksLimit.limitMessage), findsOneWidget);
      expect(repository.activeDrinks.length, FeaturedDrinksLimit.maxFeaturedDrinks);
    });

    testWidgets('feature limit prevents editing a drink to featured when limit reached', (
      WidgetTester tester,
    ) async {
      for (var i = 0; i < FeaturedDrinksLimit.maxFeaturedDrinks; i++) {
        repository.seedDrink(
          id: 'featured-$i',
          name: 'Featured Drink $i',
          category: 'Beer',
          featured: true,
        );
      }
      repository.seedDrink(
        id: 'regular',
        name: 'Regular Lager',
        category: 'Beer',
      );
      await pumpDrinksPage(tester);

      final featuredCell = find.descendant(
        of: find.ancestor(
          of: find.text('Regular Lager'),
          matching: find.byType(Row),
        ),
        matching: find.text('No'),
      );
      await tester.tap(featuredCell.first);
      await tester.pumpAndSettle();

      expect(find.text(FeaturedDrinksLimit.limitMessage), findsOneWidget);
      expect(
        repository.activeDrinks.singleWhere((drink) => drink.id == 'regular').featured,
        isFalse,
      );
    });

    testWidgets('feature limit prevents bulk edit from featuring too many drinks', (
      WidgetTester tester,
    ) async {
      for (var i = 0; i < 4; i++) {
        repository.seedDrink(
          id: 'featured-$i',
          name: 'Featured Drink $i',
          category: 'Beer',
          featured: true,
        );
      }
      repository.seedDrink(id: 'drink-a', name: 'Drink A', category: 'Beer');
      repository.seedDrink(id: 'drink-b', name: 'Drink B', category: 'Beer');
      await pumpDrinksPage(tester);

      await tester.tap(find.byKey(const Key('drink_select_drink-a')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('drink_select_drink-b')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Drinks'));
      await tester.pumpAndSettle();

      final featuredSwitches = find.descendant(
        of: find.byType(BulkEditDrinksTable),
        matching: find.byType(Switch),
      );
      await tester.tap(featuredSwitches.at(1));
      await tester.pumpAndSettle();
      await tester.tap(featuredSwitches.at(3));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text(FeaturedDrinksLimit.limitMessage), findsOneWidget);
      expect(repository.activeDrinks.where((drink) => drink.featured).length, 4);
    });
  });

  group('AddDrinkDialog', () {
    testWidgets('support link navigates to Support tab', (WidgetTester tester) async {
      VenueDashboardTab? selectedTab;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: VenueDashboardController(
              selectTab: (tab, {String? pendingActionKey}) => selectedTab = tab,
              contextData: const VenueDashboardContext(
                ownerName: 'Alex Morgan',
                ownerFirstName: 'Alex',
                venueName: 'Copper Lantern',
                venueId: 'venue-test',
              ),
              child: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () => showAddDrinkDialog(
                      context,
                      testCreatedBy: 'owner-test',
                    ),
                    child: const Text('Open'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Raise a support ticket.'));
      await tester.pumpAndSettle();

      expect(selectedTab, VenueDashboardTab.support);
    });
  });
}

class FakeVenueDrinksRepository extends VenueDrinksRepository {
  FakeVenueDrinksRepository({List<DrinkModel>? initial})
      : _drinks = List.of(initial ?? []),
        _controller = StreamController<List<DrinkModel>>.broadcast(),
        super(firestore: null);

  final List<DrinkModel> _drinks;
  final StreamController<List<DrinkModel>> _controller;
  DrinkModel? lastAddedDrink;
  DrinkModel? lastUpdatedDrink;
  String? lastDeletedDrinkId;
  BulkDrinkPatch? lastBulkPatch;
  List<String> lastBulkDeletedIds = const [];
  List<DrinkImportCommitRow> lastImportedDrinks = const [];

  List<DrinkModel> get activeDrinks =>
      _drinks.where((drink) => !drink.isDeleted).toList(growable: false);

  void seedDrink({
    required String name,
    required String category,
    String id = 'seed-drink',
    double price = 0,
    String description = '',
    bool available = true,
    bool featured = false,
  }) {
    _drinks.add(
      DrinkModel(
        id: id,
        venueId: 'venue-test',
        name: name,
        category: DrinkCategories.normalize(category),
        price: price,
        description: description,
        available: available,
        featured: featured,
        isDeleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'owner-test',
      ),
    );
    _controller.add(List.unmodifiable(_drinks));
  }

  void _publish() {
    _controller.add(
      List.unmodifiable(_drinks.where((drink) => !drink.isDeleted)),
    );
  }

  @override
  Stream<List<DrinkModel>> watchDrinks(String venueId) async* {
    yield activeDrinks;
    yield* _controller.stream;
  }

  @override
  Stream<List<DrinkModel>> watchManagementDrinks(String venueId) =>
      watchDrinks(venueId);

  @override
  Future<String> addDrink({
    required String venueId,
    required String venueName,
    required String name,
    required String category,
    required String description,
    required bool available,
    required bool featured,
    required String createdBy,
    double? price,
  }) async {
    if (!DrinkCategories.isAllowed(category)) {
      throw ArgumentError('Invalid drink category.');
    }

    final drink = DrinkModel(
      id: 'drink-${_drinks.length + 1}',
      venueId: venueId,
      name: name.trim(),
      category: DrinkCategories.normalize(category),
      price: price ?? 0,
      description: description.trim(),
      available: available,
      featured: featured,
      isDeleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: createdBy,
    );

    _drinks.add(drink);
    lastAddedDrink = drink;
    _publish();
    return drink.id;
  }

  @override
  Future<void> updateDrink({
    required String drinkId,
    required String venueId,
    required String venueName,
    required String name,
    required String category,
    required String description,
    required bool available,
    required bool featured,
    required String updatedBy,
    double? price,
  }) async {
    if (!DrinkCategories.isAllowed(category)) {
      throw ArgumentError('Invalid drink category.');
    }

    final index = _drinks.indexWhere((drink) => drink.id == drinkId);
    if (index == -1) {
      throw StateError('Drink not found.');
    }

    final existing = _drinks[index];
    final updated = DrinkModel(
      id: existing.id,
      venueId: existing.venueId,
      name: name.trim(),
      category: DrinkCategories.normalize(category),
      price: price ?? 0,
      description: description.trim(),
      available: available,
      featured: featured,
      isDeleted: false,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
      createdBy: existing.createdBy,
    );

    _drinks[index] = updated;
    lastUpdatedDrink = updated;
    _publish();
  }

  @override
  Future<void> deleteDrink({
    required String drinkId,
    required String deletedBy,
    String? deletedByEmail,
    String? venueId,
    String? drinkName,
  }) async {
    final index = _drinks.indexWhere((drink) => drink.id == drinkId);
    if (index == -1) {
      throw StateError('Drink not found.');
    }

    final existing = _drinks[index];
    _drinks[index] = DrinkModel(
      id: existing.id,
      venueId: existing.venueId,
      name: existing.name,
      category: existing.category,
      price: existing.price,
      description: existing.description,
      available: existing.available,
      featured: existing.featured,
      isDeleted: true,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
      createdBy: existing.createdBy,
    );
    lastDeletedDrinkId = drinkId;
    _publish();
  }

  @override
  Future<void> patchDrink({
    required String drinkId,
    required String venueId,
    required String venueName,
    required String drinkName,
    required String category,
    required BulkDrinkPatch patch,
    required String updatedBy,
  }) async {
    final index = _drinks.indexWhere((drink) => drink.id == drinkId);
    if (index == -1) throw StateError('Drink not found.');

    final existing = _drinks[index];
    final nextCategory = patch.category ?? existing.category;
    if (patch.category != null && !DrinkCategories.isAllowed(patch.category!)) {
      throw ArgumentError('Invalid drink category.');
    }

    _drinks[index] = DrinkModel(
      id: existing.id,
      venueId: existing.venueId,
      name: patch.name?.trim() ?? existing.name,
      category: patch.category == null
          ? existing.category
          : DrinkCategories.normalize(patch.category!),
      price: patch.price ?? existing.price,
      description: existing.description,
      available: patch.available ?? existing.available,
      featured: patch.featured ?? existing.featured,
      isDeleted: false,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
      createdBy: existing.createdBy,
    );
    lastUpdatedDrink = _drinks[index];
    _publish();
  }

  @override
  Future<void> bulkPatchDrinks({
    required List<DrinkModel> drinks,
    required String venueName,
    required BulkDrinkPatch patch,
    required String updatedBy,
  }) async {
    lastBulkPatch = patch;
    for (final drink in drinks) {
      await patchDrink(
        drinkId: drink.id,
        venueId: drink.venueId,
        venueName: venueName,
        drinkName: drink.name,
        category: drink.category,
        patch: patch,
        updatedBy: updatedBy,
      );
    }
  }

  @override
  Future<void> bulkDeleteDrinks({
    required List<DrinkModel> drinks,
    required String deletedBy,
    String? deletedByEmail,
  }) async {
    lastBulkDeletedIds = drinks.map((drink) => drink.id).toList();
    for (final drink in drinks) {
      await deleteDrink(
        drinkId: drink.id,
        deletedBy: deletedBy,
        deletedByEmail: deletedByEmail,
        venueId: drink.venueId,
        drinkName: drink.name,
      );
    }
  }

  @override
  Future<int> bulkImportDrinks({
    required String venueId,
    required String venueName,
    required List<DrinkImportCommitRow> drinks,
    required String createdBy,
  }) async {
    lastImportedDrinks = List.of(drinks);
    for (final drink in drinks) {
      await addDrink(
        venueId: venueId,
        venueName: venueName,
        name: drink.name,
        category: drink.category,
        description: '',
        available: drink.available,
        featured: drink.featured,
        createdBy: createdBy,
        price: drink.price,
      );
    }
    return drinks.length;
  }

  void dispose() {
    _controller.close();
  }
}
