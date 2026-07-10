import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/components/section_header.dart';
import '../models/venue_details_view.dart';
import 'sections/venue_deals_section.dart';
import 'sections/venue_drinks_section.dart';
import 'sections/venue_events_section.dart';
import 'sections/venue_gallery_section.dart';
import 'sections/venue_information_section.dart';
import 'sections/venue_overview_section.dart';
import 'sections/venue_related_section.dart';
import 'sections/venue_section_nav.dart';
import 'venue_conversion_strip.dart';

/// Main scrollable venue content sections for the details page.
class VenueDetailsMainContent extends StatefulWidget {
  const VenueDetailsMainContent({super.key, required this.venue});

  final VenueDetailsView venue;

  @override
  State<VenueDetailsMainContent> createState() => _VenueDetailsMainContentState();
}

class _VenueDetailsMainContentState extends State<VenueDetailsMainContent> {
  static const _sections = <VenueSectionNavItem>[
    VenueSectionNavItem(id: 'overview', label: 'Overview'),
    VenueSectionNavItem(id: 'gallery', label: 'Gallery'),
    VenueSectionNavItem(id: 'drinks', label: 'Drinks'),
    VenueSectionNavItem(id: 'deals', label: 'Deals'),
    VenueSectionNavItem(id: 'events', label: 'Events'),
    VenueSectionNavItem(id: 'information', label: 'Information'),
    VenueSectionNavItem(id: 'related', label: 'Related'),
  ];

  final _overviewKey = GlobalKey();
  final _galleryKey = GlobalKey();
  final _drinksKey = GlobalKey();
  final _dealsKey = GlobalKey();
  final _eventsKey = GlobalKey();
  final _informationKey = GlobalKey();
  final _relatedKey = GlobalKey();

  String _activeSection = 'overview';

  GlobalKey _keyForSection(String id) {
    return switch (id) {
      'gallery' => _galleryKey,
      'drinks' => _drinksKey,
      'deals' => _dealsKey,
      'events' => _eventsKey,
      'information' => _informationKey,
      'related' => _relatedKey,
      _ => _overviewKey,
    };
  }

  void _scrollToSection(String id) {
    final context = _keyForSection(id).currentContext;
    if (context == null) return;
    setState(() => _activeSection = id);
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VenueSectionNav(
          sections: _sections,
          activeSection: _activeSection,
          onSectionSelected: _scrollToSection,
        ),
        const SizedBox(height: AppSpacing.xl),
        VenueOverviewSection(venue: widget.venue, anchorKey: _overviewKey),
        const SectionDivider(),
        VenueGallerySection(venue: widget.venue, anchorKey: _galleryKey),
        const SectionDivider(),
        VenueDrinksSection(venueId: widget.venue.id, anchorKey: _drinksKey),
        const SectionDivider(),
        VenueDealsSection(venueId: widget.venue.id, anchorKey: _dealsKey),
        const SectionDivider(),
        VenueEventsSection(venueId: widget.venue.id, anchorKey: _eventsKey),
        const SectionDivider(),
        VenueInformationSection(venue: widget.venue, anchorKey: _informationKey),
        const SectionDivider(),
        VenueConversionStrip(venue: widget.venue),
        const SizedBox(height: AppSpacing.xl),
        VenueRelatedSection(venue: widget.venue, anchorKey: _relatedKey),
      ],
    );
  }
}
