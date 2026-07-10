import 'package:flutter/material.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/components/drinkspot_button.dart';
import '../../../shared/components/public_empty_state.dart';
import '../../../shared/components/public_loading_state.dart';
import '../../../shared/components/section_header.dart';
import '../../../shared/layouts/content_container.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/nightlife_background.dart';
import '../../home/widgets/home_nav_bar.dart';
import '../data/event_details_repository.dart';

/// Event details page architecture — hero, venue, info, related events.
class EventDetailsPage extends StatefulWidget {
  const EventDetailsPage({
    super.key,
    required this.eventId,
    this.repository,
  });

  final String eventId;
  final EventDetailsRepository? repository;

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  late final EventDetailsRepository _repository;
  late final Future<EventDetailsView?> _eventFuture;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? EventDetailsRepository();
    _eventFuture = _repository.loadEvent(widget.eventId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          const HomeNavBar(),
          Expanded(
            child: FutureBuilder<EventDetailsView?>(
              future: _eventFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const PublicLoadingState(message: 'Loading event…');
                }

                final event = snapshot.data;
                if (event == null) {
                  return PublicEmptyState(
                    icon: Icons.event_busy_outlined,
                    title: 'Event not found',
                    message: 'This event may have ended or is no longer available.',
                    actionLabel: 'Back to search',
                    onAction: () => Navigator.pushNamed(context, AppRouter.search),
                  );
                }

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _EventHero(event: event),
                      ContentContainer(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >= 900;
                              return Flex(
                                direction: isWide ? Axis.horizontal : Axis.vertical,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SectionHeader(
                                          title: 'About this event',
                                          subtitle: event.description.isNotEmpty
                                              ? event.description
                                              : 'Details will appear here when available.',
                                        ),
                                        if (event.artist.isNotEmpty) ...[
                                          const SizedBox(height: AppSpacing.lg),
                                          GlassContainer(
                                            padding: const EdgeInsets.all(AppSpacing.lg),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.mic_external_on_outlined,
                                                    color: AppColors.primaryPink),
                                                const SizedBox(width: AppSpacing.md),
                                                Text(
                                                  event.artist,
                                                  style: const TextStyle(
                                                    color: AppColors.white,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: isWide ? AppSpacing.xl : 0,
                                    height: isWide ? 0 : AppSpacing.xl,
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        GlassContainer(
                                          padding: const EdgeInsets.all(AppSpacing.lg),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Host venue',
                                                style: TextStyle(
                                                  color: AppColors.textSecondary,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: AppSpacing.sm),
                                              Text(
                                                event.venueName,
                                                style: const TextStyle(
                                                  color: AppColors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              if (event.venueAddress.isNotEmpty) ...[
                                                const SizedBox(height: AppSpacing.xs),
                                                Text(
                                                  event.venueAddress,
                                                  style: const TextStyle(
                                                    color: AppColors.textSecondary,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(height: AppSpacing.lg),
                                              DrinkSpotButton(
                                                label: 'View venue',
                                                onPressed: event.venueId.isNotEmpty
                                                    ? () => Navigator.pushNamed(
                                                          context,
                                                          AppRouter.venueDetails(event.venueId),
                                                        )
                                                    : null,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.lg),
                                        GlassContainer(
                                          padding: const EdgeInsets.all(AppSpacing.lg),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Map',
                                                style: TextStyle(
                                                  color: AppColors.white,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: AppSpacing.sm),
                                              const Text(
                                                'Interactive map integration coming soon.',
                                                style: TextStyle(
                                                  color: AppColors.textSecondary,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: AppSpacing.lg),
                                              Container(
                                                height: 160,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(
                                                    AppSpacing.radiusMd,
                                                  ),
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      AppColors.deepPurple.withValues(alpha: 0.8),
                                                      AppColors.surface,
                                                    ],
                                                  ),
                                                  border: Border.all(
                                                    color: AppColors.glassBorder,
                                                  ),
                                                ),
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.map_outlined,
                                                    color: AppColors.textSecondary,
                                                    size: 40,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      _RelatedEventsSection(
                        eventId: event.id,
                        venueId: event.venueId,
                        repository: _repository,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EventHero extends StatelessWidget {
  const _EventHero({required this.event});

  final EventDetailsView event;

  @override
  Widget build(BuildContext context) {
    final hasImage = event.imageUrl.trim().isNotEmpty;

    return SizedBox(
      height: 360,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            Image.network(
              event.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const AtmosphericPageBackground(),
            )
          else
            const AtmosphericPageBackground(),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.15),
                  AppColors.background.withValues(alpha: 0.92),
                ],
              ),
            ),
          ),
          ContentContainer(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.category.toUpperCase(),
                      style: TextStyle(
                        color: AppColors.primaryPink.withValues(alpha: 0.95),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      event.title,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${event.formattedDate} · ${event.venueName}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RelatedEventsSection extends StatelessWidget {
  const _RelatedEventsSection({
    required this.eventId,
    required this.venueId,
    required this.repository,
  });

  final String eventId;
  final String venueId;
  final EventDetailsRepository repository;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<EventDetailsView>>(
      future: repository.loadRelatedEvents(eventId, venueId),
      builder: (context, snapshot) {
        final events = snapshot.data ?? const [];
        if (events.isEmpty) return const SizedBox.shrink();

        return ContentContainer(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Related events',
                  subtitle: 'More happening at this venue.',
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: events
                      .map(
                        (event) => GestureDetector(
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRouter.eventDetails(event.id),
                          ),
                          child: GlassContainer(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: SizedBox(
                              width: 260,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.title,
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    event.formattedDate,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
