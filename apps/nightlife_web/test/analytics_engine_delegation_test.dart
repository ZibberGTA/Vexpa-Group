import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/features/venue_management/data/venue_analytics_service.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_date_range.dart';

void main() {
  group('VenueAnalyticsService analytics engine delegation', () {
    test('percentChange delegates to Analytics Engine', () {
      expect(VenueAnalyticsService.percentChange(150, 100), 50);
      expect(VenueAnalyticsService.percentChange(0, 0), 0);
      expect(VenueAnalyticsService.percentChange(5, 0), 100);
    });

    test('loadSnapshot returns empty data without Firebase', () async {
      final service = VenueAnalyticsService(firestore: null);
      final snapshot = await service.loadSnapshot(
        venueId: 'venue-1',
        range: VenueDashboardDateRange.last7Days,
      );

      expect(snapshot.current.total, 0);
      expect(snapshot.hasData, isFalse);
      expect(snapshot.chartPoints, isEmpty);
    });
  });
}
