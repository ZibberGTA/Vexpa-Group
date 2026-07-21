import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/features/admin/models/admin_dashboard_models.dart';
import 'package:nightlife_web/features/admin/models/admin_venue_crm.dart';

void main() {
  group('mergeAdminVenueCrmRows', () {
    test('includes claimed and unclaimed venues together', () {
      final merged = mergeAdminVenueCrmRows(
        venueRows: [
          _venueRow(
            id: 'claimed-1',
            data: {
              'ownerId': 'owner-1',
              'claimStatus': 'claimed',
              'name': 'Claimed Pub',
            },
          ),
          _venueRow(id: 'legacy-unclaimed', data: {'name': 'Legacy Pub'}),
        ],
        directoryRows: [
          _directoryRow(
            id: 'directory-only',
            data: {'name': 'Directory Pub', 'city': 'Leeds'},
          ),
        ],
      );

      expect(
        merged.map((row) => row.id),
        containsAll(['claimed-1', 'legacy-unclaimed', 'directory-only']),
      );
    });

    test('does not duplicate rows when venue exists in both sources', () {
      final merged = mergeAdminVenueCrmRows(
        venueRows: [
          _venueRow(
            id: 'shared-1',
            data: {
              'name': 'Canonical Name',
              'ownerId': 'owner-1',
              'claimStatus': 'claimed',
            },
          ),
        ],
        directoryRows: [
          _directoryRow(
            id: 'shared-1',
            data: {'name': 'Directory Name', 'claimStatus': 'unclaimed'},
          ),
        ],
      );

      expect(merged, hasLength(1));
      expect(merged.single.id, 'shared-1');
      expect(merged.single.data['name'], 'Canonical Name');
      expect(AdminVenueCrmView(row: merged.single).isClaimed, isTrue);
    });

    test('maps directory-only venues to unclaimed rows with venues path', () {
      final merged = mergeAdminVenueCrmRows(
        venueRows: const [],
        directoryRows: [
          _directoryRow(
            id: 'unclaimed-1',
            data: {
              'name': 'Unclaimed Pub',
              'city': 'Manchester',
              'category': 'Bar',
            },
          ),
        ],
      );

      final venue = AdminVenueCrmView(row: merged.single);
      expect(merged.single.path, 'venues/unclaimed-1');
      expect(venue.claimedLabel, 'Unclaimed');
      expect(venue.ownerDisplayLabel, isEmpty);
      expect(venue.subscriptionPlanPillLabel, 'Unknown');
    });
  });

  group('filterAndSortVenues claim status', () {
    test('filters claimed and unclaimed venues', () {
      final rows = [
        _venueRow(
          id: 'claimed-1',
          data: {
            'ownerId': 'owner-1',
            'claimStatus': 'claimed',
            'name': 'Claimed',
          },
        ),
        _venueRow(
          id: 'unclaimed-1',
          data: {'claimStatus': 'unclaimed', 'name': 'Unclaimed'},
        ),
      ];

      final claimed = filterAndSortVenues(
        rows: rows,
        search: '',
        claimFilter: 'Claimed',
        categoryFilter: 'All',
        cityFilter: 'All',
        subscriptionFilter: 'All',
        sortColumn: AdminVenueTableSortColumn.defaultColumn,
        sortAscending: AdminVenueTableSortColumn.defaultAscending,
      );
      final unclaimed = filterAndSortVenues(
        rows: rows,
        search: '',
        claimFilter: 'Unclaimed',
        categoryFilter: 'All',
        cityFilter: 'All',
        subscriptionFilter: 'All',
        sortColumn: AdminVenueTableSortColumn.defaultColumn,
        sortAscending: AdminVenueTableSortColumn.defaultAscending,
      );

      expect(claimed.map((venue) => venue.venueId), ['claimed-1']);
      expect(unclaimed.map((venue) => venue.venueId), ['unclaimed-1']);
    });

    test('excludes deleted venues from filtered results', () {
      final rows = [
        _venueRow(
          id: 'live-1',
          data: {'name': 'Live Pub', 'claimStatus': 'unclaimed'},
        ),
        _venueRow(
          id: 'deleted-1',
          data: {
            'name': 'Deleted Pub',
            'isDeleted': true,
            'claimStatus': 'unclaimed',
          },
        ),
      ];

      final visible = filterAndSortVenues(
        rows: rows,
        search: '',
        claimFilter: 'All',
        categoryFilter: 'All',
        cityFilter: 'All',
        subscriptionFilter: 'All',
        sortColumn: AdminVenueTableSortColumn.defaultColumn,
        sortAscending: AdminVenueTableSortColumn.defaultAscending,
      );

      expect(visible.map((venue) => venue.venueId), ['live-1']);
    });
  });

  group('deriveAdminVenueIsClaimed', () {
    test('claimed venue with owner remains claimed', () {
      expect(
        deriveAdminVenueIsClaimed({
          'ownerId': 'owner-1',
          'claimStatus': 'claimed',
        }),
        isTrue,
      );
    });

    test('legacy unclaimed venue without owner remains unclaimed', () {
      expect(deriveAdminVenueIsClaimed({'name': 'Legacy Pub'}), isFalse);
    });
  });
}

AdminDocumentRow _venueRow({
  required String id,
  required Map<String, dynamic> data,
}) {
  return AdminDocumentRow(id: id, path: 'venues/$id', data: data);
}

AdminDocumentRow _directoryRow({
  required String id,
  required Map<String, dynamic> data,
}) {
  return AdminDocumentRow(
    id: id,
    path: 'venue_claim_directory/$id',
    data: data,
  );
}
