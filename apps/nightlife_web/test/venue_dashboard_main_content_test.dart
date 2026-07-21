import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_context.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_date_range.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_home_data.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_stat.dart';
import 'package:nightlife_web/features/venue_management/models/venue_profile_completion.dart';
import 'package:nightlife_web/features/venue_management/models/venue_profile_views_chart_data.dart';
import 'package:nightlife_web/features/venue_management/services/venue_profile_completion_calculator.dart';
import 'package:nightlife_web/features/venue_management/utils/venue_dashboard_welcome_name.dart';
import 'package:nightlife_web/features/venue_management/widgets/venue_dashboard_controller.dart';
import 'package:nightlife_web/features/venue_management/widgets/venue_dashboard_main_content.dart';
import 'package:nightlife_web/features/venues/models/venue_model.dart';

void main() {
  group('VenueDashboardWelcomeName', () {
    test('uses first name from owner context', () {
      expect(
        VenueDashboardWelcomeName.welcomeTitle(
          contextData: const VenueDashboardContext(
            ownerName: 'Alex Morgan',
            ownerFirstName: 'Alex',
            venueName: 'Test Venue',
            venueId: 'test',
          ),
        ),
        'Welcome back, Alex',
      );
    });

    test('falls back to User when no name', () {
      expect(
        VenueDashboardWelcomeName.welcomeTitle(),
        'Welcome back, User',
      );
    });
  });

  group('VenueDashboardStat subtitles', () {
    test('shows no data yet when analytics are zero', () {
      const stat = VenueDashboardStat(
        label: 'Profile Views',
        value: 0,
        icon: Icons.visibility_outlined,
      );

      expect(
        stat.subtitleLabel(VenueDashboardDateRange.last7Days),
        'No data yet',
      );
    });

    test('uses comparison text when available', () {
      const stat = VenueDashboardStat(
        label: 'Profile Views',
        value: 100,
        changePercent: 12,
        icon: Icons.visibility_outlined,
      );

      expect(
        stat.subtitleLabel(VenueDashboardDateRange.last7Days),
        '+12% vs previous 7 days',
      );
    });
  });

  group('VenueDashboardStatsData', () {
    test('empty stats return zero values without fake percentages', () {
      final stats = VenueDashboardStatsData.empty();
      expect(stats.length, 5);
      expect(stats.every((stat) => stat.value == 0), isTrue);
      expect(stats.every((stat) => !stat.hasComparison), isTrue);
    });
  });

  group('VenueProfileCompletionCalculator', () {
    test('calculates completion from venue fields and drink count', () {
      final completion = VenueProfileCompletionCalculator.calculate(
        venue: VenueModel(
          id: 'venue-1',
          name: 'Copper Lantern',
          address: '12 High Street',
          area: 'City Centre',
          city: 'London',
          category: 'Bar',
          venueType: 'Bar',
          crowdLevel: 'moderate',
          logoUrl: 'https://example.com/logo.png',
          bannerImageUrl: 'https://example.com/banner.png',
          phone: '02070000000',
          website: 'https://example.com',
          featureTags: const ['liveMusic'],
          openingHours: const {
            'monday': {'open': '17:00', 'close': '23:00'},
          },
        ),
        drinkCount: 2,
      );

      expect(completion.completedSteps, 10);
      expect(completion.percentage, 100);
    });

    test('returns zero completion for empty venue', () {
      final completion = VenueProfileCompletionCalculator.calculate(
        venue: VenueModel(
          id: 'venue-1',
          name: '',
          address: '',
          area: '',
          city: '',
          category: '',
          venueType: '',
          crowdLevel: 'quiet',
        ),
        drinkCount: 0,
      );

      expect(completion.completedSteps, 0);
      expect(completion.percentage, 0);
    });
  });

  group('VenueDashboardHomeData', () {
    test('empty home data does not include fake analytics', () {
      final home = VenueDashboardHomeData.empty();
      expect(home.stats.every((stat) => stat.value == 0), isTrue);
      expect(home.chartPoints, isEmpty);
      expect(home.analyticsAvailable, isFalse);
    });
  });

  testWidgets('summary date filter updates stats without changing chart data', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const initialChartPoints = [
      VenueProfileViewsDataPoint(label: 'Mon', value: 10),
      VenueProfileViewsDataPoint(label: 'Tue', value: 20),
    ];
    const updatedChartPoints = [
      VenueProfileViewsDataPoint(label: 'Week 1', value: 100),
      VenueProfileViewsDataPoint(label: 'Week 2', value: 200),
    ];

    VenueDashboardHomeData homeData = VenueDashboardHomeData(
      dateRange: VenueDashboardDateRange.last7Days,
      stats: VenueDashboardStatsData.mockFor(VenueDashboardDateRange.last7Days),
      chartPoints: initialChartPoints,
      profileCompletion: VenueProfileCompletion.empty,
      highlights: const [],
      whatsNext: const [],
      nextSevenDaysSchedule: VenueDashboardHomeData.empty().nextSevenDaysSchedule,
      analyticsAvailable: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: _MainContentTestHarness(
          loadHomeData: (range) async {
            return VenueDashboardHomeData(
              dateRange: range,
              stats: VenueDashboardStatsData.mockFor(range),
              chartPoints: updatedChartPoints,
              profileCompletion: VenueProfileCompletion.empty,
              highlights: const [],
              whatsNext: const [],
              nextSevenDaysSchedule: VenueDashboardHomeData.empty().nextSevenDaysSchedule,
              analyticsAvailable: true,
            );
          },
          loadChartData: (_) async => initialChartPoints,
          initialHomeData: homeData,
          child: const VenueDashboardMainContent(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1,248'), findsOneWidget);
    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Tue'), findsOneWidget);
    expect(find.text('Week 1'), findsNothing);

    await tester.tap(find.text(VenueDashboardDateRange.last7Days.label).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(VenueDashboardDateRange.lastMonth.label).last);
    await tester.pumpAndSettle();

    expect(find.text('4,820'), findsOneWidget);
    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Tue'), findsOneWidget);
    expect(find.text('Week 1'), findsNothing);
  });

  testWidgets('chart date filter updates graph without changing summary stats', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const initialChartPoints = [
      VenueProfileViewsDataPoint(label: 'Mon', value: 10),
      VenueProfileViewsDataPoint(label: 'Tue', value: 20),
    ];
    const updatedChartPoints = [
      VenueProfileViewsDataPoint(label: 'W1', value: 100),
      VenueProfileViewsDataPoint(label: 'W2', value: 200),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: _MainContentTestHarness(
          loadHomeData: (range) async {
            return VenueDashboardHomeData(
              dateRange: range,
              stats: VenueDashboardStatsData.mockFor(range),
              chartPoints: initialChartPoints,
              profileCompletion: VenueProfileCompletion.empty,
              highlights: const [],
              whatsNext: const [],
              nextSevenDaysSchedule: VenueDashboardHomeData.empty().nextSevenDaysSchedule,
              analyticsAvailable: true,
            );
          },
          loadChartData: (range) async {
            expect(range, VenueDashboardDateRange.lastMonth);
            return updatedChartPoints;
          },
          initialHomeData: VenueDashboardHomeData(
            dateRange: VenueDashboardDateRange.last7Days,
            stats: VenueDashboardStatsData.mockFor(
              VenueDashboardDateRange.last7Days,
            ),
            chartPoints: initialChartPoints,
            profileCompletion: VenueProfileCompletion.empty,
            highlights: const [],
            whatsNext: const [],
            nextSevenDaysSchedule: VenueDashboardHomeData.empty().nextSevenDaysSchedule,
            analyticsAvailable: true,
          ),
          child: const VenueDashboardMainContent(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1,248'), findsOneWidget);
    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Tue'), findsOneWidget);
    expect(find.text('W1'), findsNothing);

    await tester.tap(find.text(VenueDashboardDateRange.last7Days.label).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(VenueDashboardDateRange.lastMonth.label).last);
    await tester.pumpAndSettle();

    expect(find.text('1,248'), findsOneWidget);
    expect(find.text('4,820'), findsNothing);
    expect(find.text('Mon'), findsNothing);
    expect(find.text('W1'), findsOneWidget);
    expect(find.text('W2'), findsOneWidget);
  });
}

class _MainContentTestHarness extends StatefulWidget {
  const _MainContentTestHarness({
    required this.initialHomeData,
    required this.loadHomeData,
    required this.loadChartData,
    required this.child,
  });

  final VenueDashboardHomeData initialHomeData;
  final Future<VenueDashboardHomeData> Function(VenueDashboardDateRange range)
      loadHomeData;
  final Future<List<VenueProfileViewsDataPoint>> Function(
    VenueDashboardDateRange range,
  ) loadChartData;
  final Widget child;

  @override
  State<_MainContentTestHarness> createState() => _MainContentTestHarnessState();
}

class _MainContentTestHarnessState extends State<_MainContentTestHarness> {
  late VenueDashboardHomeData _homeData = widget.initialHomeData;
  var _loadingHomeData = false;

  Future<void> _handleDateRangeChanged(VenueDashboardDateRange range) async {
    setState(() => _loadingHomeData = true);
    final updated = await widget.loadHomeData(range);
    if (!mounted) return;
    setState(() {
      _homeData = updated;
      _loadingHomeData = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return VenueDashboardController(
      selectTab: (_, {pendingActionKey}) {},
      contextData: const VenueDashboardContext(
        ownerName: 'Alex Morgan',
        ownerFirstName: 'Alex',
        venueName: 'Copper Lantern',
        venueId: 'venue-copper-lantern',
      ),
      homeData: _homeData,
      isLoadingHomeData: _loadingHomeData,
      onDateRangeChanged: _handleDateRangeChanged,
      onChartDateRangeChanged: widget.loadChartData,
      child: Scaffold(body: widget.child),
    );
  }
}
