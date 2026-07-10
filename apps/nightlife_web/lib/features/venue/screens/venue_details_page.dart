import 'package:flutter/material.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/seo/venue_page_seo.dart';
import '../../../core/theme/app_colors.dart';
import '../../home/widgets/home_nav_bar.dart';
import '../data/venue_details_repository.dart';
import '../models/venue_details_view.dart';
import '../widgets/venue_details_content_shell.dart';
import '../widgets/venue_details_fallback.dart';
import '../widgets/venue_details_loading.dart';

/// Production venue details page for the Vexda web platform.
class VenueDetailsPage extends StatefulWidget {
  const VenueDetailsPage({
    super.key,
    required this.venueId,
    this.repository,
  });

  final String venueId;
  final VenueDetailsRepository? repository;

  @override
  State<VenueDetailsPage> createState() => _VenueDetailsPageState();
}

class _VenueDetailsPageState extends State<VenueDetailsPage> {
  late final VenueDetailsRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? VenueDetailsRepository();
  }

  @override
  void dispose() {
    VenuePageSeo.reset();
    super.dispose();
  }

  void _applySeo(VenueDetailsView venue) {
    VenuePageSeo.apply(
      venueName: venue.name,
      description: venue.overviewDescription,
      canonicalPath: AppRouter.venueDetails(venue.id),
      imageUrl: venue.bannerImageUrl ?? venue.logoUrl,
      address: venue.displayAddress,
      phone: venue.phone,
      website: venue.website,
      rating: venue.rating,
      latitude: venue.latitude,
      longitude: venue.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          const HomeNavBar(),
          Expanded(
            child: StreamBuilder<VenueDetailsView?>(
              stream: _repository.watchVenue(widget.venueId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const VenueDetailsLoading();
                }

                if (snapshot.hasError) {
                  return const VenueDetailsFallback(
                    message: 'We could not load this venue from Firestore.',
                  );
                }

                final venue = snapshot.data;
                if (venue == null) {
                  return const VenueDetailsFallback(
                    message:
                        'This venue could not be found or is no longer available.',
                  );
                }

                _applySeo(venue);
                return VenueDetailsContentShell(venue: venue);
              },
            ),
          ),
        ],
      ),
    );
  }
}
