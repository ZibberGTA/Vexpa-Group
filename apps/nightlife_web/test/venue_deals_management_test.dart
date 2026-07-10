import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/features/venue/data/models/deal_model.dart';
import 'package:nightlife_web/features/venue/data/venue_deals_repository.dart';
import 'package:nightlife_web/features/venue_management/models/bulk_deal_patch.dart';
import 'package:nightlife_web/features/venue_management/models/deal_status.dart';
import 'package:nightlife_web/features/venue_management/models/deal_types.dart';
import 'package:nightlife_web/features/venue_management/models/featured_deals_limit.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_context.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_tab.dart';
import 'package:nightlife_web/features/venue_management/widgets/deals/deal_table_sort.dart';
import 'package:nightlife_web/features/venue_management/widgets/deals/venue_deals_management_page.dart';
import 'package:nightlife_web/features/venue_management/widgets/venue_dashboard_controller.dart';
import 'package:nightlife_web/features/venue_management/widgets/venue_dashboard_shell.dart';

import 'venue_dashboard_test_data.dart';

class FakeVenueDealsRepository extends VenueDealsRepository {
  FakeVenueDealsRepository({List<DealModel>? initial})
      : _deals = List.of(initial ?? []),
        _controller = StreamController<List<DealModel>>.broadcast(),
        super(firestore: null);

  final List<DealModel> _deals;
  final StreamController<List<DealModel>> _controller;
  DealModel? lastAddedDeal;
  DealModel? lastUpdatedDeal;
  String? lastDeletedDealId;
  List<String> lastBulkDeletedIds = const [];

  List<DealModel> get activeDeals =>
      _deals.where((deal) => !deal.isDeleted).toList(growable: false);

  void seedDeal({
    required String title,
    String id = 'seed-deal',
    String dealType = DealTypes.twoForOne,
    String value = '2-for-1',
    DateTime? startDateTime,
    DateTime? endDateTime,
    bool isActive = true,
    bool featured = false,
    String description = '',
  }) {
    final now = DateTime.now();
    _deals.add(
      DealModel(
        id: id,
        venueId: 'venue-test',
        title: title,
        description: description,
        dealType: dealType,
        value: value,
        startTime: '17:00',
        endTime: '22:00',
        startDateTime: startDateTime ?? now.subtract(const Duration(days: 1)),
        endDateTime: endDateTime ?? now.add(const Duration(days: 30)),
        isActive: isActive,
        featured: featured,
        isDeleted: false,
        createdAt: now,
        updatedAt: now,
      ),
    );
    _publish();
  }

  void _publish() {
    _controller.add(List.unmodifiable(activeDeals));
  }

  @override
  Stream<List<DealModel>> watchManagementDeals(String venueId) async* {
    yield activeDeals;
    yield* _controller.stream;
  }

  @override
  Future<String> addDeal({
    required String venueId,
    required String venueName,
    required String title,
    required String description,
    required String dealType,
    required String value,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required List<String> availableDays,
    required String startTime,
    required String endTime,
    required bool isActive,
    required bool featured,
    required String createdBy,
  }) async {
    if (!DealTypes.isAllowed(dealType)) {
      throw ArgumentError('Invalid deal type.');
    }

    final deal = DealModel(
      id: 'deal-${_deals.length + 1}',
      venueId: venueId,
      title: title.trim(),
      description: description.trim(),
      dealType: DealTypes.normalize(dealType),
      value: value.trim(),
      startTime: startTime,
      endTime: endTime,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      availableDays: availableDays,
      isActive: isActive,
      featured: featured,
      isDeleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _deals.add(deal);
    lastAddedDeal = deal;
    _publish();
    return deal.id;
  }

  @override
  Future<String> duplicateDeal({
    required DealModel source,
    required String venueName,
    required String createdBy,
  }) {
    final trimmedTitle = source.title.trim();
    final copyTitle =
        trimmedTitle.endsWith(' Copy') ? trimmedTitle : '$trimmedTitle Copy';

    return addDeal(
      venueId: source.venueId,
      venueName: venueName,
      title: copyTitle,
      description: source.description,
      dealType: source.dealType,
      value: source.value,
      startDateTime: source.startDateTime ?? DateTime.now(),
      endDateTime: source.endDateTime ??
          (source.startDateTime ?? DateTime.now()).add(const Duration(days: 30)),
      availableDays: source.availableDays,
      startTime: source.startTime,
      endTime: source.endTime,
      isActive: false,
      featured: false,
      createdBy: createdBy,
    );
  }

  @override
  Future<void> updateDeal({
    required String dealId,
    required String venueName,
    required String title,
    required String description,
    required String dealType,
    required String value,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required List<String> availableDays,
    required String startTime,
    required String endTime,
    required bool isActive,
    required bool featured,
    required String updatedBy,
  }) async {
    final index = _deals.indexWhere((deal) => deal.id == dealId);
    if (index == -1) throw StateError('Deal not found.');

    final existing = _deals[index];
    final updated = DealModel(
      id: existing.id,
      venueId: existing.venueId,
      title: title.trim(),
      description: description.trim(),
      dealType: DealTypes.normalize(dealType),
      value: value.trim(),
      startTime: startTime,
      endTime: endTime,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      availableDays: availableDays,
      isActive: isActive,
      featured: featured,
      isDeleted: false,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );

    _deals[index] = updated;
    lastUpdatedDeal = updated;
    _publish();
  }

  @override
  Future<void> deleteDeal({
    required String dealId,
    required String deletedBy,
    String? deletedByEmail,
  }) async {
    final index = _deals.indexWhere((deal) => deal.id == dealId);
    if (index == -1) throw StateError('Deal not found.');

    final existing = _deals[index];
    _deals[index] = DealModel(
      id: existing.id,
      venueId: existing.venueId,
      title: existing.title,
      description: existing.description,
      dealType: existing.dealType,
      value: existing.value,
      startTime: existing.startTime,
      endTime: existing.endTime,
      startDateTime: existing.startDateTime,
      endDateTime: existing.endDateTime,
      availableDays: existing.availableDays,
      isActive: existing.isActive,
      featured: existing.featured,
      isDeleted: true,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
    lastDeletedDealId = dealId;
    _publish();
  }

  @override
  Future<void> bulkDeleteDeals({
    required List<String> dealIds,
    required String deletedBy,
    String? deletedByEmail,
  }) async {
    lastBulkDeletedIds = List.of(dealIds);
    for (final dealId in dealIds) {
      await deleteDeal(
        dealId: dealId,
        deletedBy: deletedBy,
        deletedByEmail: deletedByEmail,
      );
    }
  }

  @override
  Future<void> patchDeal({
    required String dealId,
    required String venueName,
    required String title,
    required String description,
    required String dealType,
    required String value,
    required BulkDealPatch patch,
    required String updatedBy,
  }) async {
    final index = _deals.indexWhere((deal) => deal.id == dealId);
    if (index == -1) throw StateError('Deal not found.');

    final existing = _deals[index];
    _deals[index] = DealModel(
      id: existing.id,
      venueId: existing.venueId,
      title: patch.title?.trim() ?? existing.title,
      description: existing.description,
      dealType: patch.dealType == null
          ? existing.dealType
          : DealTypes.normalize(patch.dealType!),
      value: patch.value ?? existing.value,
      startTime: existing.startTime,
      endTime: existing.endTime,
      startDateTime: patch.startDateTime ?? existing.startDateTime,
      endDateTime: patch.endDateTime ?? existing.endDateTime,
      availableDays: existing.availableDays,
      isActive: patch.isActive ?? existing.isActive,
      featured: patch.featured ?? existing.featured,
      isDeleted: false,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
    lastUpdatedDeal = _deals[index];
    _publish();
  }

  void dispose() {
    _controller.close();
  }
}

double dealTitleTop(WidgetTester tester, String title) {
  return tester.getRect(find.text(title).first).top;
}

Future<void> doubleTapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  group('VenueDealsManagementPage', () {
    late FakeVenueDealsRepository repository;

    setUp(() {
      repository = FakeVenueDealsRepository();
    });

    tearDown(() {
      repository.dispose();
    });

    Future<void> pumpDealsPage(
      WidgetTester tester, {
      DateTime? testStartDate,
      DateTime? testEndDate,
    }) async {
      tester.view.physicalSize = const Size(1440, 1100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: VenueDashboardController(
              selectTab: (_) {},
              contextData: const VenueDashboardContext(
                ownerName: 'Alex Morgan',
                ownerFirstName: 'Alex',
                venueName: 'Copper Lantern',
                venueId: 'venue-test',
              ),
              child: VenueDealsManagementPage(
                repository: repository,
                testCreatedBy: 'owner-test',
                testStartDate: testStartDate,
                testEndDate: testEndDate,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Deals page loads in dashboard shell', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: VenueDashboardShell(
            contextData: VenueDashboardContext.placeholder(),
            homeData: VenueDashboardTestData.sampleHomeData(),
            initialTab: VenueDashboardTab.deals,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Deals'), findsWidgets);
      expect(
        find.text('Create and manage promotional offers for your venue.'),
        findsOneWidget,
      );
      expect(find.text('Create Deal'), findsWidgets);
    });

    testWidgets('shows empty state when venue has no deals', (
      WidgetTester tester,
    ) async {
      await pumpDealsPage(tester);

      expect(find.text('No deals added yet.'), findsOneWidget);
      expect(
        find.text('Create your first deal to start promoting your venue.'),
        findsOneWidget,
      );
    });

    testWidgets('Create Deal opens modal', (WidgetTester tester) async {
      await pumpDealsPage(tester);

      await tester.tap(find.text('Create Deal').last);
      await tester.pumpAndSettle();

      expect(find.text('Add a promotional offer for your venue.'), findsOneWidget);
    });

    testWidgets('required validation works', (WidgetTester tester) async {
      await pumpDealsPage(tester);

      await tester.tap(find.text('Create Deal').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('create_deal_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Deal title is required.'), findsOneWidget);
      expect(find.text('Deal type is required.'), findsOneWidget);
    });

    testWidgets('deal saves to repository and list updates', (
      WidgetTester tester,
    ) async {
      await pumpDealsPage(
        tester,
        testStartDate: DateTime.now(),
        testEndDate: DateTime.now().add(const Duration(days: 30)),
      );

      await tester.tap(find.text('Create Deal').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, '2-for-1 Cocktails');
      await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Deal Type'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2-for-1').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('create_deal_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Deal created successfully.'), findsOneWidget);
      expect(find.text('2-for-1 Cocktails'), findsOneWidget);
      expect(repository.lastAddedDeal?.title, '2-for-1 Cocktails');
    });

    testWidgets('deals list displays active venue deals', (
      WidgetTester tester,
    ) async {
      repository.seedDeal(title: 'Happy Hour');
      repository.seedDeal(title: 'Student Night', id: 'deal-2');
      await pumpDealsPage(tester);

      expect(find.text('Happy Hour'), findsOneWidget);
      expect(find.text('Student Night'), findsOneWidget);
    });

    testWidgets('double tap on title opens Edit Deal modal', (WidgetTester tester) async {
      repository.seedDeal(title: 'Happy Hour');
      await pumpDealsPage(tester);

      await tester.tap(find.text('Happy Hour'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Happy Hour'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Deal'), findsOneWidget);
      expect(find.text('Delete Deal'), findsOneWidget);
    });

    testWidgets('checkbox selection works', (WidgetTester tester) async {
      repository.seedDeal(title: 'Happy Hour', id: 'deal-a');
      await pumpDealsPage(tester);

      await tester.tap(find.byKey(const Key('deal_select_deal-a')));
      await tester.pumpAndSettle();

      expect(find.text('Selected: 1'), findsOneWidget);
      expect(find.text('Edit Deals'), findsOneWidget);
    });

    testWidgets('Clear Selection works', (WidgetTester tester) async {
      repository.seedDeal(title: 'Happy Hour', id: 'deal-a');
      await pumpDealsPage(tester);

      await tester.tap(find.byKey(const Key('deal_select_deal-a')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear Selection'));
      await tester.pumpAndSettle();

      expect(find.text('Selected: 1'), findsNothing);
    });

    test('status badges calculate correctly', () {
      final now = DateTime(2026, 7, 1, 12);

      final active = DealModel(
        id: 'a',
        venueId: 'v',
        title: 'Active',
        description: '',
        startDateTime: now.subtract(const Duration(days: 1)),
        endDateTime: now.add(const Duration(days: 1)),
        isActive: true,
      );
      expect(computeDealStatus(active, now: now), DealStatus.active);

      final scheduled = DealModel(
        id: 's',
        venueId: 'v',
        title: 'Scheduled',
        description: '',
        startDateTime: now.add(const Duration(days: 2)),
        endDateTime: now.add(const Duration(days: 10)),
        isActive: true,
      );
      expect(computeDealStatus(scheduled, now: now), DealStatus.scheduled);

      final expired = DealModel(
        id: 'e',
        venueId: 'v',
        title: 'Expired',
        description: '',
        startDateTime: now.subtract(const Duration(days: 10)),
        endDateTime: now.subtract(const Duration(days: 1)),
        isActive: true,
      );
      expect(computeDealStatus(expired, now: now), DealStatus.expired);

      final paused = DealModel(
        id: 'p',
        venueId: 'v',
        title: 'Paused',
        description: '',
        startDateTime: now.subtract(const Duration(days: 1)),
        endDateTime: now.add(const Duration(days: 1)),
        isActive: false,
      );
      expect(computeDealStatus(paused, now: now), DealStatus.paused);
    });

    testWidgets('status filter works', (WidgetTester tester) async {
      repository.seedDeal(
        title: 'Active Deal',
        id: 'deal-active',
        isActive: true,
      );
      repository.seedDeal(
        title: 'Paused Deal',
        id: 'deal-paused',
        isActive: false,
      );
      await pumpDealsPage(tester);

      await tester.tap(find.byKey(const Key('deals_status_filter_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('deals_status_filter_Paused')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(find.text('Paused Deal'), findsOneWidget);
      expect(find.text('Active Deal'), findsNothing);
    });

    testWidgets('search works', (WidgetTester tester) async {
      repository.seedDeal(title: 'Happy Hour', id: 'deal-a');
      repository.seedDeal(title: 'Student Night', id: 'deal-b');
      await pumpDealsPage(tester);

      await tester.enterText(find.byKey(const Key('deals_search_field')), 'Student');
      await tester.pumpAndSettle();

      expect(find.text('Student Night'), findsOneWidget);
      expect(find.text('Happy Hour'), findsNothing);
    });

    testWidgets('search clear X works', (WidgetTester tester) async {
      repository.seedDeal(title: 'Happy Hour', id: 'deal-a');
      await pumpDealsPage(tester);

      await tester.enterText(find.byKey(const Key('deals_search_field')), 'Happy');
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('sorting works and preserves selection', (WidgetTester tester) async {
      repository.seedDeal(title: 'Zulu Deal', id: 'deal-z');
      repository.seedDeal(title: 'Alpha Deal', id: 'deal-a');
      await pumpDealsPage(tester);

      await tester.tap(find.byKey(const Key('deal_select_deal-z')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(dealSortColumnKey(DealSortColumn.title)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(dealSortColumnKey(DealSortColumn.title)));
      await tester.pumpAndSettle();

      expect(dealTitleTop(tester, 'Alpha Deal'), lessThan(dealTitleTop(tester, 'Zulu Deal')));
      expect(find.text('Selected: 1'), findsOneWidget);
    });

    testWidgets('Delete Deal requires confirmation', (WidgetTester tester) async {
      repository.seedDeal(title: 'Happy Hour', id: 'deal-a');
      await pumpDealsPage(tester);

      await doubleTapText(tester, 'Happy Hour');
      await tester.tap(find.text('Delete Deal'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Deal?'), findsOneWidget);
      expect(
        find.text('Are you sure you want to delete this deal? This action cannot be undone.'),
        findsOneWidget,
      );
    });

    testWidgets('featured deals appear first', (WidgetTester tester) async {
      repository.seedDeal(title: 'Regular Deal', id: 'deal-r', featured: false);
      repository.seedDeal(title: 'Featured Deal', id: 'deal-f', featured: true);
      await pumpDealsPage(tester);

      expect(
        dealTitleTop(tester, 'Featured Deal'),
        lessThan(dealTitleTop(tester, 'Regular Deal')),
      );
      expect(find.byKey(dealRowFeaturedBorderKey('deal-f')), findsOneWidget);
    });

    testWidgets('featured limit prevents more than 3', (WidgetTester tester) async {
      repository.seedDeal(title: 'Featured 1', id: 'f1', featured: true);
      repository.seedDeal(title: 'Featured 2', id: 'f2', featured: true);
      repository.seedDeal(title: 'Featured 3', id: 'f3', featured: true);
      await pumpDealsPage(
        tester,
        testStartDate: DateTime.now(),
        testEndDate: DateTime.now().add(const Duration(days: 30)),
      );

      await tester.tap(find.text('Create Deal').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Fourth Featured');
      await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Deal Type'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Other').last);
      await tester.pumpAndSettle();

      final featuredSwitch = find.widgetWithText(SwitchListTile, 'Featured');
      await tester.ensureVisible(featuredSwitch);
      await tester.tap(featuredSwitch);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('create_deal_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text(FeaturedDealsLimit.limitMessage), findsOneWidget);
    });

    testWidgets('Create Deal quick action uses action key', (WidgetTester tester) async {
      await pumpDealsPage(tester);

      expect(find.text('Add Deal'), findsWidgets);
      expect(find.text('Schedule Deal'), findsNothing);
      expect(find.text('View Public Deals'), findsNothing);
      expect(find.text('Pause Selected Deal(s)'), findsOneWidget);
      expect(find.text('View Deal Performance'), findsOneWidget);

      await tester.tap(find.text('Add Deal').first);
      await tester.pumpAndSettle();

      expect(find.text('Add a promotional offer for your venue.'), findsOneWidget);
    });

    testWidgets('Duplicate Deal requires exactly one selected deal', (
      WidgetTester tester,
    ) async {
      repository.seedDeal(title: 'Happy Hour', id: 'deal-a');
      await pumpDealsPage(tester);

      await tester.tap(find.text('Duplicate Deal').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Select a deal to duplicate.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('deal_select_deal-a')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Duplicate Deal').last);
      await tester.pumpAndSettle();

      expect(repository.activeDeals.any((deal) => deal.title == 'Happy Hour Copy'), isTrue);
      expect(find.text('Happy Hour Copy'), findsOneWidget);
    });

    test('duplicateDeal appends Copy and sets inactive', () async {
      repository.seedDeal(title: 'Happy Hour', id: 'deal-a');
      final source = repository.activeDeals.first;

      await repository.duplicateDeal(
        source: source,
        venueName: 'Copper Lantern',
        createdBy: 'owner-test',
      );

      final copy = repository.activeDeals.last;
      expect(copy.title, 'Happy Hour Copy');
      expect(copy.isActive, isFalse);
    });

    testWidgets('Pause Selected Deal(s) sets active=false', (
      WidgetTester tester,
    ) async {
      repository.seedDeal(title: 'Active Deal', id: 'deal-active', isActive: true);
      await pumpDealsPage(tester);

      await tester.tap(find.text('Pause Selected Deal(s)').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('Select one or more active or scheduled deals to pause.'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('deal_select_deal-active')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pause Selected Deal(s)').last);
      await tester.pumpAndSettle();
      expect(find.text('Pause Selected Deals?'), findsOneWidget);

      await tester.tap(find.byKey(const Key('confirm_pause_selected_deals_button')));
      await tester.pumpAndSettle();

      expect(
        repository.activeDeals.singleWhere((deal) => deal.id == 'deal-active').isActive,
        isFalse,
      );
    });
  });

  group('DealSortColumn', () {
    test('sortDeals puts featured deals first', () {
      final deals = [
        DealModel(id: '1', venueId: 'v', title: 'B', description: '', featured: false),
        DealModel(id: '2', venueId: 'v', title: 'A', description: '', featured: true),
      ];

      final sorted = sortDeals(deals, const DealTableSort());
      expect(sorted.first.featured, isTrue);
      expect(sorted.first.title, 'A');
    });
  });
}
