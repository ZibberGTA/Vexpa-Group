import 'package:test/test.dart';
import 'package:vex_engines/experience/application/experience_deal_status.dart';
import 'package:vex_engines/experience/application/experience_event_status.dart';
import 'package:vex_engines/experience/application/experience_event_validator.dart';
import 'package:vex_engines/experience/application/venue_availability_service.dart';
import 'package:vex_engines/experience/application/venue_content_ordering_service.dart';
import 'package:vex_engines/experience/application/venue_content_summary_service.dart';
import 'package:vex_engines/experience/application/venue_content_validation_service.dart';
import 'package:vex_engines/experience/application/venue_featured_content_service.dart';
import 'package:vex_engines/experience/application/venue_presentation_support.dart';
import 'package:vex_engines/experience/application/venue_public_presentation_service.dart';
import 'package:vex_engines/experience/domain/experience_gallery_content.dart';
import 'package:vex_engines/experience/shared/experience_gallery_categories.dart';

void main() {
  const ordering = VenueContentOrderingService();
  const availability = VenueAvailabilityService();
  const validation = VenueContentValidationService();
  const featured = VenueFeaturedContentService();
  const summary = VenueContentSummaryService();
  const presentation = VenuePresentationSupport();

  group('VenueContentValidationService', () {
    test('validates drink price and malformed values', () {
      expect(validation.validateDrinkPrice('12.50'), isNull);
      expect(validation.validateDrinkPrice('£-1'), isNotNull);
      expect(validation.parseNormalizedPrice('£1,234.50'), 1234.5);
      expect(validation.parseNormalizedPrice('abc'), isNull);
    });

    test('validates deal and event date ranges', () {
      final start = DateTime(2026, 7, 10);
      final end = DateTime(2026, 7, 9);
      expect(validation.validateDealDateRange(startDate: start, endDate: end),
          isNotNull);
      expect(
        validation.validateEventDateTimeRange(
          startDate: start,
          startTime: '20:00',
          endDate: DateTime(2026, 7, 10),
          endTime: '23:00',
        ),
        isNull,
      );
      expect(
        validation.validateEventDateTimeRange(
          startDate: start,
          startTime: '20:00',
          endDate: DateTime(2026, 7, 10),
          endTime: '19:00',
        ),
        isNotNull,
      );
    });

    test('ExperienceEventValidator rejects malformed times', () {
      expect(ExperienceEventValidator.validateStartTime('25:00'), isNotNull);
      expect(ExperienceEventValidator.validateStartTime('20:00'), isNull);
      expect(ExperienceEventValidator.validateTitle(''), isNotNull);
    });
  });

  group('VenueContentOrderingService', () {
    test('sorts public deals current before upcoming', () {
      final now = DateTime(2026, 7, 10, 12);
      final current = _DealStub(
        id: 'c',
        start: now.subtract(const Duration(hours: 1)),
        upcoming: false,
      );
      final upcoming = _DealStub(
        id: 'u',
        start: now.add(const Duration(days: 2)),
        upcoming: true,
      );

      final sorted = ordering.sortPublicDeals(
        deals: [upcoming, current],
        isUpcoming: (deal) => deal.upcoming,
        startDateTime: (deal) => deal.start,
        now: now,
      );

      expect(sorted.map((d) => d.id), ['c', 'u']);
    });

    test('sorts gallery media deterministically', () {
      expect(
        ordering.compareGalleryMedia(
          aFeatured: true,
          bFeatured: false,
          aSortOrder: 5,
          bSortOrder: 0,
          aUploadedAt: DateTime(2026, 1, 1),
          bUploadedAt: DateTime(2026, 2, 1),
        ),
        lessThan(0),
      );
      expect(
        ordering.compareGalleryMedia(
          aFeatured: false,
          bFeatured: false,
          aSortOrder: 1,
          bSortOrder: 2,
          aUploadedAt: DateTime(2026, 1, 1),
          bUploadedAt: DateTime(2026, 2, 1),
        ),
        lessThan(0),
      );
    });

    test('featured-first deal table ordering is stable', () {
      final deals = [
        _DealRow(id: 'b', title: 'Beta', featured: false),
        _DealRow(id: 'a', title: 'Alpha', featured: true),
      ];
      final sorted = ordering.sortDealsForTable(
        deals: deals,
        sort: const ExperienceDealTableSort(),
        isFeatured: (deal) => deal.featured,
        title: (deal) => deal.title,
        dealTypeLabel: (_) => 'Other',
        startDateTime: (_) => null,
        endDateTime: (_) => null,
        status: (_) => ExperienceDealManagementStatus.active,
      );
      expect(sorted.first.id, 'a');
    });
  });

  group('VenueFeaturedContentService', () {
    test('duplicate copy title and defaults preserve rules', () {
      expect(featured.duplicateCopyTitle('Happy Hour'), 'Happy Hour Copy');
      expect(featured.duplicateCopyTitle('Happy Hour Copy'), 'Happy Hour Copy');

      final defaults = featured.duplicateDealDefaults(
        sourceStart: DateTime(2026, 7, 1),
        sourceEnd: null,
        now: DateTime(2026, 7, 1),
      );
      expect(defaults.isActive, isFalse);
      expect(defaults.featured, isFalse);
      expect(defaults.endDateTime, DateTime(2026, 7, 31));
    });

    test('cover selection marks only chosen gallery item', () {
      final items = [
        _Media(id: '1', featured: true),
        _Media(id: '2', featured: false),
      ];
      final updated = featured.applyCoverSelection(
        items: items,
        coverItemId: '2',
        id: (item) => item.id,
        copyWithFeatured: (item, {required bool featured}) =>
            _Media(id: item.id, featured: featured),
      );
      expect(updated.map((i) => i.featured), [false, true]);
    });
  });

  group('VenueAvailabilityService', () {
    test('pause eligibility matches management statuses', () {
      expect(
        availability.isDealPausable(ExperienceDealManagementStatus.active),
        isTrue,
      );
      expect(
        availability.isDealPausable(ExperienceDealManagementStatus.expired),
        isFalse,
      );
    });

    test('media active filter respects status and visibility', () {
      final active = availability.filterActiveMedia(
        items: [
          _MediaRow(status: 'active', visible: true),
          _MediaRow(status: 'archived', visible: true),
        ],
        status: (row) => row.status,
        visible: (row) => row.visible,
      );
      expect(active.length, 1);
    });
  });

  group('VenuePresentationSupport', () {
    test('formats prices and upcoming labels', () {
      expect(presentation.formatPrice(5), '£5.00');
      expect(presentation.formatPrice(0), '—');
      expect(
        presentation.formatUpcomingStartLabel(
          DateTime(2026, 7, 13, 20, 30),
          now: DateTime(2026, 7, 10, 12),
        ),
        contains('Starts'),
      );
    });

    test('legacy gallery mapping preserves cover-first behaviour', () {
      final images = presentation.legacyGalleryFromUrls([
        'https://example.com/a.jpg',
        'https://example.com/b.jpg',
      ]);
      expect(images.first.isCover, isTrue);
      expect(images.first.category, 'cover');
    });

    test('gallery category labels are stable', () {
      expect(ExperienceGalleryCategories.label('interior'), 'Interior');
      expect(ExperienceGalleryCategories.normalize('FOOD'), 'food');
    });

    test('management relative time preserves long-form owner labels', () {
      final now = DateTime(2026, 7, 10, 12);
      expect(
        presentation.managementRelativeTimeLabel(
          now.subtract(const Duration(minutes: 5)),
          now: now,
        ),
        '5 minutes ago',
      );
      expect(
        presentation.managementRelativeTimeLabel(
          now.subtract(const Duration(days: 1)),
          now: now,
        ),
        'Yesterday',
      );
    });

    test('formats venue tag labels and plain prices', () {
      expect(presentation.formatVenueTagLabel('liveMusic'), 'Live Music');
      expect(presentation.formatPricePlainFromRaw(4.5), '4.50');
      expect(presentation.formatPricePlainFromRaw(null), '');
    });
  });

  group('VenuePublicPresentationService', () {
    const publicPresentation = VenuePublicPresentationService();

    test('resolves public tags and highlights', () {
      expect(
        publicPresentation.resolvePublicTags(
          featureTags: const ['Cocktails', 'Live Music'],
          venueType: 'Bar',
          category: 'Bar',
        ),
        ['Cocktails', 'Live Music'],
      );

      expect(
        publicPresentation.resolvePublicHighlights(
          featureTags: const ['Cocktails'],
          features: const ['Rooftop'],
          venueType: 'Bar',
          category: 'Bar',
        ),
        ['Cocktails', 'Rooftop'],
      );
    });

    test('parses feature tags from venueFeatures map', () {
      final tags = publicPresentation.parseFeatureTags(
        featureTags: const ['DJ'],
        venueFeatures: const {'liveMusic': true, 'age18': true},
      );
      expect(tags, contains('DJ'));
      expect(tags, contains('Live Music'));
      expect(tags, contains('18+'));
    });

    test('preview tags fall back when feature tags empty', () {
      final tags = publicPresentation.venuePreviewTags(
        featureTags: const [],
        formatTagLabel: presentation.formatVenueTagLabel,
      );
      expect(tags, ['Live Music', '18+']);
    });
  });

  group('VenueContentSummaryService', () {
    test('aggregates drink and deal metrics', () {
      final drinks = [
        _Drink(name: 'Lager', category: 'Beer', available: true, featured: true),
        _Drink(name: 'Stout', category: 'Beer', available: false, featured: false),
      ];
      final drinkMetrics = summary.drinkMetrics(
        drinks: drinks,
        categoryLabel: (d) => d.category,
        available: (d) => d.available,
        featured: (d) => d.featured,
      );
      expect(drinkMetrics.total, 2);
      expect(drinkMetrics.categories, 1);
      expect(drinkMetrics.featured, 1);

      final now = DateTime(2026, 7, 10, 12);
      final deals = [
        _DealMetric(
          title: 'Live',
          featured: true,
          status: ExperienceDealManagementStatus.active,
          createdAt: now,
          updatedAt: now,
        ),
      ];
      final dealMetrics = summary.dealMetrics(
        deals: deals,
        featured: (d) => d.featured,
        status: (d) => d.status,
      );
      expect(dealMetrics.active, 1);
    });

    test('recent activity uses creation window heuristic', () {
      final now = DateTime(2026, 7, 10, 12);
      final created = now.subtract(const Duration(minutes: 1));
      final activities = summary.recentDrinkActivity(
        drinks: [
          _DrinkActivity(
            name: 'Gin',
            createdAt: created,
            updatedAt: now,
          ),
        ],
        name: (d) => d.name,
        createdAt: (d) => d.createdAt,
        updatedAt: (d) => d.updatedAt,
        formatTimestamp: (ts) => ts.toIso8601String(),
        now: now,
      );
      expect(activities.first.title, 'Drink added: Gin');
    });

    test('gallery metrics detect cover presence', () {
      final metrics = summary.galleryMetrics(
        items: const [
          ExperienceMediaSortKey(id: '1', featured: true),
          ExperienceMediaSortKey(id: '2'),
        ],
        isFeatured: (item) => item.featured,
      );
      expect(metrics.hasGalleryCover, isTrue);
      expect(metrics.galleryImages, 2);
    });
  });
}

final class _DealStub {
  const _DealStub({
    required this.id,
    required this.start,
    required this.upcoming,
  });

  final String id;
  final DateTime start;
  final bool upcoming;
}

final class _DealRow {
  const _DealRow({
    required this.id,
    required this.title,
    required this.featured,
  });

  final String id;
  final String title;
  final bool featured;
}

final class _Media {
  const _Media({required this.id, this.featured = false});

  final String id;
  final bool featured;
}

final class _MediaRow {
  const _MediaRow({required this.status, required this.visible});

  final String status;
  final bool visible;
}

final class _Drink {
  const _Drink({
    required this.name,
    required this.category,
    required this.available,
    required this.featured,
  });

  final String name;
  final String category;
  final bool available;
  final bool featured;
}

final class _DealMetric {
  const _DealMetric({
    required this.title,
    required this.featured,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String title;
  final bool featured;
  final ExperienceDealManagementStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
}

final class _DrinkActivity {
  const _DrinkActivity({
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
}
