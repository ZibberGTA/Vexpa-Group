import 'package:flutter/material.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/components/drinkspot_button.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../data/models/event_model.dart';
import '../../data/public_venue_content_filters.dart';
import '../../data/venue_events_repository.dart';
import '../shared/upcoming_venue_card_style.dart';
import '../shared/venue_section_primitives.dart';

/// Current and upcoming venue events in a premium timeline layout.
class VenueEventsSection extends StatelessWidget {
  const VenueEventsSection({
    super.key,
    required this.venueId,
    this.repository,
    this.anchorKey,
    this.now,
  });

  final String venueId;
  final VenueEventsRepository? repository;
  final Key? anchorKey;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final repo = repository ?? VenueEventsRepository();
    final clock = now ?? DateTime.now();

    return VenueSectionShell(
      anchorKey: anchorKey,
      title: 'Events',
      subtitle: 'What\'s happening now and what\'s coming up.',
      child: StreamBuilder<List<EventModel>>(
        stream: repo.watchEvents(venueId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const VenueEmptyState(
              icon: Icons.event_outlined,
              title: 'Events unavailable',
              message: 'We could not load events for this venue right now.',
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const VenueSectionLoading(lines: 3);
          }

          final events = snapshot.data ?? [];
          final current = events
              .where((event) => isPublicCurrentEvent(event, now: clock))
              .toList();
          final upcoming = events
              .where((event) => isPublicUpcomingEvent(event, now: clock))
              .toList();

          if (current.isEmpty && upcoming.isEmpty) {
            return const VenueEmptyState(
              icon: Icons.event_outlined,
              title: 'No upcoming events',
              message:
                  'Published events will appear here. Expired and draft events are hidden automatically.',
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (current.isNotEmpty) ...[
                const _Subheading(label: 'Current Events'),
                const SizedBox(height: AppSpacing.sm),
                for (var i = 0; i < current.length; i++)
                  _CurrentEventCard(
                    event: current[i],
                    featured: current[i].featured,
                    isLast: i == current.length - 1 && upcoming.isEmpty,
                  ),
              ],
              if (upcoming.isNotEmpty) ...[
                SizedBox(height: current.isNotEmpty ? AppSpacing.lg : 0),
                const _Subheading(label: 'Upcoming Events'),
                const SizedBox(height: AppSpacing.sm),
                for (var i = 0; i < upcoming.length; i++)
                  _UpcomingEventCard(
                    event: upcoming[i],
                    startLabel: formatUpcomingStartLabel(
                      upcoming[i].startDateTime,
                      now: clock,
                    ),
                    isLast: i == upcoming.length - 1,
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Subheading extends StatelessWidget {
  const _Subheading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.primaryPink,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _CurrentEventCard extends StatefulWidget {
  const _CurrentEventCard({
    required this.event,
    required this.featured,
    required this.isLast,
  });

  final EventModel event;
  final bool featured;
  final bool isLast;

  @override
  State<_CurrentEventCard> createState() => _CurrentEventCardState();
}

class _CurrentEventCardState extends State<_CurrentEventCard> {
  bool _hovered = false;

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final day = event.startDateTime.day.toString().padLeft(2, '0');
    final month = _monthLabel(event.startDateTime.month);

    return Padding(
      padding: EdgeInsets.only(bottom: widget.isLast ? 0 : AppSpacing.lg),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 54,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: widget.featured ? AppColors.brandGradient : null,
                      color: widget.featured
                          ? null
                          : AppColors.surfaceElevated.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: AppColors.primaryPurple.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          day,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          month,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!widget.isLast)
                    Container(
                      width: 2,
                      height: 48,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      color: AppColors.primaryPurple.withValues(alpha: 0.25),
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: GlassContainer(
                  borderRadius: AppSpacing.radiusLg,
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (event.imageUrl.trim().isNotEmpty)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppSpacing.radiusLg),
                          ),
                          child: AspectRatio(
                            aspectRatio: 2.4,
                            child: Image.network(
                              event.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(color: AppColors.surfaceElevated),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.featured)
                              const Padding(
                                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                                child: Text(
                                  'Featured event',
                                  style: TextStyle(
                                    color: AppColors.primaryPink,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            Text(
                              event.title,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              [
                                '${_formatTime(event.startDateTime)} – ${_formatTime(event.endDateTime)}',
                                event.category,
                                if (event.artist.trim().isNotEmpty)
                                  event.artist.trim(),
                              ].join(' • '),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (event.description.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                event.description,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.md),
                            DrinkSpotButton(
                              label: 'View Details',
                              compact: true,
                              variant: DrinkSpotButtonVariant.secondary,
                              onPressed: () {
                                Navigator.of(context).pushNamed(
                                  AppRouter.eventDetails(event.id),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _monthLabel(int month) {
    const labels = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return labels[month - 1];
  }
}

class _UpcomingEventCard extends StatefulWidget {
  const _UpcomingEventCard({
    required this.event,
    required this.startLabel,
    required this.isLast,
  });

  final EventModel event;
  final String startLabel;
  final bool isLast;

  @override
  State<_UpcomingEventCard> createState() => _UpcomingEventCardState();
}

class _UpcomingEventCardState extends State<_UpcomingEventCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final day = event.startDateTime.day.toString().padLeft(2, '0');
    final month = _monthLabel(event.startDateTime.month);

    return Padding(
      padding: EdgeInsets.only(bottom: widget.isLast ? 0 : AppSpacing.lg),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
          decoration: upcomingVenueCardDecoration(hovered: _hovered),
          child: Padding(
            padding: const EdgeInsets.all(1.4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: AppColors.trailGold.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        day,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        month,
                        style: TextStyle(
                          color: AppColors.trailGold.withValues(alpha: 0.95),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: GlassContainer(
                    borderRadius: AppSpacing.radiusLg,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                event.title,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const UpcomingVenueBadge(),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          widget.startLabel,
                          style: TextStyle(
                            color: AppColors.trailGold.withValues(alpha: 0.95),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (event.description.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            event.description,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        DrinkSpotButton(
                          label: 'View Details',
                          compact: true,
                          variant: DrinkSpotButtonVariant.ghost,
                          onPressed: () {
                            Navigator.of(context).pushNamed(
                              AppRouter.eventDetails(event.id),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _monthLabel(int month) {
    const labels = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return labels[month - 1];
  }
}
