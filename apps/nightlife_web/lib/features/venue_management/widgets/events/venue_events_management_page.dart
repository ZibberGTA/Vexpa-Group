import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../venue/data/models/event_model.dart';
import '../../../venue/data/venue_events_repository.dart';
import '../../data/venue_management_page_activity_support.dart';
import '../../models/venue_dashboard_tab.dart';
import '../../models/venue_page_quick_action.dart';
import '../drinks/drinks_search_field.dart';
import '../drinks/venue_drinks_management_page.dart';
import '../page/venue_dashboard_page_scaffold.dart';
import '../page/venue_dashboard_page_widgets.dart';
import '../venue_dashboard_controller.dart';
import 'add_event_dialog.dart';
import 'delete_events_confirmation_dialog.dart';
import 'event_row.dart';
import 'event_selection_action_bar.dart';
import 'event_table_layout.dart';

void showEventSelectionRequiredMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// Venue events management workspace with inline-editable table rows.
class VenueEventsManagementPage extends StatefulWidget {
  const VenueEventsManagementPage({
    super.key,
    this.repository,
    this.testUpdatedBy,
  });

  final VenueEventsRepository? repository;
  final String? testUpdatedBy;

  @override
  State<VenueEventsManagementPage> createState() =>
      _VenueEventsManagementPageState();
}

class _VenueEventsManagementPageState extends State<VenueEventsManagementPage> {
  late final VenueEventsRepository _repository =
      widget.repository ?? VenueEventsRepository();

  final _searchController = TextEditingController();
  final Set<String> _selectedEventIds = {};
  String _searchQuery = '';
  bool _pendingAddEventActionHandled = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String? _resolveUserId() {
    if (widget.testUpdatedBy != null) return widget.testUpdatedBy;
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  void _toggleEventSelection(String eventId, bool selected) {
    setState(() {
      if (selected) {
        _selectedEventIds.add(eventId);
      } else {
        _selectedEventIds.remove(eventId);
      }
    });
  }

  void _clearSelection() {
    if (_selectedEventIds.isEmpty) return;
    setState(_selectedEventIds.clear);
  }

  void _pruneSelection(List<EventModel> events) {
    final activeIds = events.map((event) => event.id).toSet();
    _selectedEventIds.removeWhere((id) => !activeIds.contains(id));
  }

  List<EventModel> _selectedEvents(List<EventModel> events) {
    return events.where((event) => _selectedEventIds.contains(event.id)).toList();
  }

  Future<void> _openAddEventDialog(List<EventModel> events) async {
    final added = await showAddEventDialog(
      context,
      repository: _repository,
      testCreatedBy: widget.testUpdatedBy,
      venueEvents: events,
    );
    if (!mounted || !added) return;

    await reloadVenueManagementPageActivity(context);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event created successfully.')),
    );
  }

  void _maybeOpenPendingAddEventDialog(List<EventModel> events) {
    if (_pendingAddEventActionHandled) return;

    final pendingActionKey =
        VenueDashboardController.maybeOf(context)?.takePendingTabActionKey?.call();
    if (pendingActionKey != VenuePageActionKeys.addEvent) return;

    _pendingAddEventActionHandled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_openAddEventDialog(events));
    });
  }

  void _handleEditSelected() {
    if (_selectedEventIds.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit event fields directly in the table.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleDeleteSelected(List<EventModel> allEvents) async {
    final selected = _selectedEvents(allEvents);
    if (selected.isEmpty) return;

    final confirmed = await BulkDeleteEventsConfirmationDialog.show(
      context,
      eventCount: selected.length,
    );
    if (!confirmed || !mounted) return;

    final userId = _resolveUserId();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to delete events.')),
      );
      return;
    }

    try {
      await _repository.bulkDeleteEvents(
        events: selected,
        deletedBy: userId,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete selected events.')),
      );
      return;
    }

    if (!mounted) return;

    await reloadVenueManagementPageActivity(context);
    if (!mounted) return;

    final count = selected.length;
    _clearSelection();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          count == 1
              ? 'Event deleted successfully.'
              : '$count events deleted successfully.',
        ),
      ),
    );
  }

  Future<void> _handleDuplicateSelected(List<EventModel> allEvents) async {
    final selected = _selectedEvents(allEvents);
    if (selected.isEmpty) {
      showEventSelectionRequiredMessage(
        context,
        'Select an event to duplicate.',
      );
      return;
    }

    if (selected.length > 1) {
      showEventSelectionRequiredMessage(
        context,
        'Select one event to duplicate.',
      );
      return;
    }

    final userId = _resolveUserId();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to duplicate events.')),
      );
      return;
    }

    final controller = VenueDashboardController.maybeOf(context);
    final venueName = controller?.contextData.venueName ?? '';

    try {
      await _repository.duplicateEvent(
        source: selected.first,
        venueName: venueName,
        createdBy: userId,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not duplicate event. Please try again.')),
      );
      return;
    }

    if (!mounted) return;
    _clearSelection();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event duplicated successfully.')),
    );
  }

  void _handleUploadEventBanner(List<EventModel> allEvents) {
    final selected = _selectedEvents(allEvents);
    if (selected.isEmpty) {
      showEventSelectionRequiredMessage(
        context,
        'Select an event to upload a banner.',
      );
      return;
    }
    if (selected.length > 1) {
      showEventSelectionRequiredMessage(
        context,
        'Select one event to upload a banner.',
      );
      return;
    }

    showVenueStyledComingSoonMessage(
      context,
      'Event banner upload is coming soon.',
    );
  }

  void _handleViewEventPerformance() {
    final controller = VenueDashboardController.maybeOf(context);
    if (controller != null) {
      controller.selectTab(VenueDashboardTab.analytics);
      return;
    }
    showVenueStyledComingSoonMessage(
      context,
      'Event performance analytics is coming soon.',
    );
  }

  void _handleQuickAction(VenuePageQuickAction action, List<EventModel> events) {
    if (action.actionKey == VenuePageActionKeys.addEvent) {
      _openAddEventDialog(events);
      return;
    }
    if (action.actionKey == VenuePageActionKeys.duplicateEvent) {
      _handleDuplicateSelected(events);
      return;
    }
    if (action.actionKey == VenuePageActionKeys.exportEvents) {
      showVenueStyledComingSoonMessage(context, 'Event export is coming soon.');
      return;
    }
    if (action.actionKey == VenuePageActionKeys.uploadEventBanner) {
      _handleUploadEventBanner(events);
      return;
    }
    if (action.actionKey == VenuePageActionKeys.viewEventPerformance) {
      _handleViewEventPerformance();
      return;
    }
    showVenuePagePlaceholderAction(context, action.label);
  }

  List<EventModel> _filteredEvents(List<EventModel> events) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return events;
    return events
        .where(
          (event) =>
              event.title.toLowerCase().contains(query) ||
              event.category.toLowerCase().contains(query),
        )
        .toList();
  }

  List<EventModel> _displayEvents(List<EventModel> events) {
    return sortEventsFeaturedFirst(
      _filteredEvents(events),
      (event) => event.featured,
      (a, b) => a.startDateTime.compareTo(b.startDateTime),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = VenueDashboardController.maybeOf(context);
    final venueId = controller?.contextData.venueId ?? '';

    return StreamBuilder<List<EventModel>>(
      stream: _repository.watchManagementEvents(venueId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryPink),
          );
        }

        final events = snapshot.data ?? const [];
        _pruneSelection(events);
        _maybeOpenPendingAddEventDialog(events);
        final displayed = _displayEvents(events);

        return VenueDashboardPageScaffold(
          tab: VenueDashboardTab.events,
          onPrimaryAction: () => _openAddEventDialog(events),
          onQuickAction: (action) => _handleQuickAction(action, events),
          mainContent: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VenuePageMetricRow(
                metrics: [
                  VenuePageMetricCard(
                    label: 'Total events',
                    value: '${events.length}',
                    icon: Icons.event_outlined,
                  ),
                  VenuePageMetricCard(
                    label: 'Active',
                    value: '${events.where((e) => e.isActive).length}',
                    icon: Icons.check_circle_outline_rounded,
                  ),
                  VenuePageMetricCard(
                    label: 'Featured',
                    value: '${events.where((e) => e.featured).length}',
                    icon: Icons.star_outline_rounded,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              VenuePageSection(
                title: 'Events',
                trailing: SizedBox(
                  width: 240,
                  child: DrinksSearchField(
                    key: const Key('events_search_field'),
                    controller: _searchController,
                    hintText: 'Search events…',
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_selectedEventIds.isNotEmpty) ...[
                      EventSelectionActionBar(
                        selectedCount: _selectedEventIds.length,
                        onEdit: _handleEditSelected,
                        onDelete: () => _handleDeleteSelected(events),
                        onClearSelection: _clearSelection,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (events.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                        child: Column(
                          children: [
                            Text(
                              'No events added yet.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: AppSpacing.sm),
                            Text(
                              'Create your first event to start promoting your venue.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (displayed.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                        child: Text(
                          'No events match your search.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const EventTableHeader(),
                          for (var i = 0; i < displayed.length; i++)
                            EventRow(
                              event: displayed[i],
                              repository: _repository,
                              venueEvents: events,
                              updatedBy: _resolveUserId(),
                              isSelected:
                                  _selectedEventIds.contains(displayed[i].id),
                              onSelectionChanged: (selected) =>
                                  _toggleEventSelection(displayed[i].id, selected),
                              showDivider: i < displayed.length - 1,
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
