import 'package:flutter/material.dart';

import '../models/venue_management_activity.dart';
import '../models/venue_management_activity_types.dart';
import '../utils/venue_management_activity_relative_time.dart';
import 'venue_management_activity_presentation.dart';

/// Maps persisted venue management activity records into dashboard UI content.
class VenueManagementActivityPresentationMapper {
  const VenueManagementActivityPresentationMapper({DateTime? now})
      : _now = now;

  final DateTime? _now;

  VenueManagementActivityPresentation map(VenueManagementActivity activity) {
    final mapping = _resolveMapping(activity);
    final timestamp = activity.occurredAt ?? _now ?? DateTime.now();

    return VenueManagementActivityPresentation(
      icon: mapping.icon,
      title: mapping.title,
      description: mapping.description,
      actorDisplayName: _cleanActorName(activity.actorDisplayName),
      timestampLabel: VenueManagementActivityRelativeTime.format(
        timestamp,
        now: _now,
      ),
    );
  }

  String? _cleanActorName(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  _ActivityMapping _resolveMapping(VenueManagementActivity activity) {
    final entityName = _cleanEntityName(activity.entityName);
    final fallbackDescription = _cleanDescription(activity.description);

    final mapped = switch (activity.sourceArea) {
      VenueManagementActivitySourceAreas.venueProfile =>
        _mapVenueProfile(activity.actionType, entityName, fallbackDescription),
      VenueManagementActivitySourceAreas.drinks =>
        _mapDrinks(activity.actionType, entityName, fallbackDescription),
      VenueManagementActivitySourceAreas.deals =>
        _mapDeals(activity.actionType, entityName, fallbackDescription),
      VenueManagementActivitySourceAreas.events =>
        _mapEvents(activity.actionType, entityName, fallbackDescription),
      VenueManagementActivitySourceAreas.gallery =>
        _mapGallery(activity.actionType, entityName, fallbackDescription),
      VenueManagementActivitySourceAreas.trails =>
        _mapTrails(activity.actionType, entityName, fallbackDescription),
      _ => _unknownMapping(fallbackDescription),
    };

    if (mapped != null) return mapped;
    return _unknownMapping(fallbackDescription);
  }

  String? _cleanEntityName(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed == 'Venue profile') return null;
    return trimmed;
  }

  String? _cleanDescription(String raw) {
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _quotedEntityDescription(String? entityName, String verb) {
    if (entityName == null) return null;
    return '"$entityName" $verb';
  }

  String? _entityActionDescription({
    required String? entityName,
    required String verb,
    required String generic,
    String? fallbackDescription,
  }) {
    final quoted = _quotedEntityDescription(entityName, verb);
    if (quoted != null) return quoted;
    if (fallbackDescription != null &&
        fallbackDescription.trim().isNotEmpty &&
        entityName != null) {
      return fallbackDescription;
    }
    return generic;
  }

  _ActivityMapping? _mapVenueProfile(
    String actionType,
    String? entityName,
    String? fallbackDescription,
  ) {
    return switch (actionType) {
      VenueManagementActivityActionTypes.updated => _ActivityMapping(
          icon: Icons.storefront_outlined,
          title: 'Venue profile updated',
          description:
              fallbackDescription ?? 'Venue information was changed',
        ),
      VenueManagementActivityActionTypes.brandingChanged => _ActivityMapping(
          icon: Icons.palette_outlined,
          title: 'Venue branding updated',
          description: fallbackDescription ??
              _quotedEntityDescription(entityName, 'was updated') ??
              'Venue branding was changed',
        ),
      VenueManagementActivityActionTypes.contactUpdated => _ActivityMapping(
          icon: Icons.contact_phone_outlined,
          title: 'Contact information updated',
          description: fallbackDescription ?? 'Contact details were changed',
        ),
      VenueManagementActivityActionTypes.openingHoursUpdated =>
        _ActivityMapping(
          icon: Icons.schedule_outlined,
          title: 'Opening hours updated',
          description: fallbackDescription ?? 'Opening hours were changed',
        ),
      _ => null,
    };
  }

  _ActivityMapping? _mapDrinks(
    String actionType,
    String? entityName,
    String? fallbackDescription,
  ) {
    return switch (actionType) {
      VenueManagementActivityActionTypes.created => _ActivityMapping(
          icon: Icons.local_bar_outlined,
          title: 'Drink added',
          description: _entityActionDescription(
            entityName: entityName,
            verb: 'was added',
            generic: 'A drink was added',
            fallbackDescription: fallbackDescription,
          ),
        ),
      VenueManagementActivityActionTypes.updated => _ActivityMapping(
          icon: Icons.local_bar_outlined,
          title: 'Drink updated',
          description: _entityActionDescription(
            entityName: entityName,
            verb: 'was updated',
            generic: 'A drink was updated',
            fallbackDescription: fallbackDescription,
          ),
        ),
      VenueManagementActivityActionTypes.availabilityChanged =>
        _ActivityMapping(
          icon: Icons.local_bar_outlined,
          title: 'Drink availability changed',
          description: _entityActionDescription(
            entityName: entityName,
            verb: 'availability changed',
            generic: 'Drink availability was changed',
            fallbackDescription: fallbackDescription,
          ),
        ),
      VenueManagementActivityActionTypes.archived => _ActivityMapping(
          icon: Icons.local_bar_outlined,
          title: 'Drink removed',
          description: _entityActionDescription(
            entityName: entityName,
            verb: 'was removed',
            generic: 'A drink was removed',
            fallbackDescription: fallbackDescription,
          ),
        ),
      _ => null,
    };
  }

  _ActivityMapping? _mapDeals(
    String actionType,
    String? entityName,
    String? fallbackDescription,
  ) {
    return switch (actionType) {
      VenueManagementActivityActionTypes.created => _ActivityMapping(
          icon: Icons.local_offer_outlined,
          title: 'Deal added',
          description: _quotedEntityDescription(entityName, 'was added') ??
              fallbackDescription ??
              'A deal was added',
        ),
      VenueManagementActivityActionTypes.updated => _ActivityMapping(
          icon: Icons.local_offer_outlined,
          title: 'Deal updated',
          description: _quotedEntityDescription(entityName, 'was updated') ??
              fallbackDescription ??
              'A deal was updated',
        ),
      VenueManagementActivityActionTypes.activated => _ActivityMapping(
          icon: Icons.local_offer_outlined,
          title: 'Deal activated',
          description: _quotedEntityDescription(entityName, 'was activated') ??
              fallbackDescription ??
              'A deal was activated',
        ),
      VenueManagementActivityActionTypes.deactivated => _ActivityMapping(
          icon: Icons.local_offer_outlined,
          title: 'Deal deactivated',
          description: _quotedEntityDescription(entityName, 'was deactivated') ??
              fallbackDescription ??
              'A deal was deactivated',
        ),
      VenueManagementActivityActionTypes.archived => _ActivityMapping(
          icon: Icons.local_offer_outlined,
          title: 'Deal removed',
          description: _quotedEntityDescription(entityName, 'was removed') ??
              fallbackDescription ??
              'A deal was removed',
        ),
      _ => null,
    };
  }

  _ActivityMapping? _mapEvents(
    String actionType,
    String? entityName,
    String? fallbackDescription,
  ) {
    return switch (actionType) {
      VenueManagementActivityActionTypes.created => _ActivityMapping(
          icon: Icons.event_outlined,
          title: 'Event added',
          description: _quotedEntityDescription(entityName, 'was added') ??
              fallbackDescription ??
              'An event was added',
        ),
      VenueManagementActivityActionTypes.updated => _ActivityMapping(
          icon: Icons.event_outlined,
          title: 'Event updated',
          description: _quotedEntityDescription(entityName, 'was updated') ??
              fallbackDescription ??
              'An event was updated',
        ),
      VenueManagementActivityActionTypes.published => _ActivityMapping(
          icon: Icons.event_outlined,
          title: 'Event published',
          description: _quotedEntityDescription(entityName, 'was published') ??
              fallbackDescription ??
              'An event was published',
        ),
      VenueManagementActivityActionTypes.unpublished => _ActivityMapping(
          icon: Icons.event_outlined,
          title: 'Event unpublished',
          description:
              _quotedEntityDescription(entityName, 'was unpublished') ??
                  fallbackDescription ??
                  'An event was unpublished',
        ),
      VenueManagementActivityActionTypes.archived => _ActivityMapping(
          icon: Icons.event_outlined,
          title: 'Event removed',
          description: _quotedEntityDescription(entityName, 'was removed') ??
              fallbackDescription ??
              'An event was removed',
        ),
      _ => null,
    };
  }

  _ActivityMapping? _mapGallery(
    String actionType,
    String? entityName,
    String? fallbackDescription,
  ) {
    return switch (actionType) {
      VenueManagementActivityActionTypes.photoUploaded => _ActivityMapping(
          icon: Icons.photo_library_outlined,
          title: 'Gallery image uploaded',
          description: _quotedEntityDescription(entityName, 'was uploaded') ??
              fallbackDescription ??
              'A gallery image was uploaded',
        ),
      VenueManagementActivityActionTypes.photoDeleted => _ActivityMapping(
          icon: Icons.photo_library_outlined,
          title: 'Gallery image removed',
          description: _quotedEntityDescription(entityName, 'was removed') ??
              fallbackDescription ??
              'A gallery image was removed',
        ),
      VenueManagementActivityActionTypes.galleryUpdated => _ActivityMapping(
          icon: Icons.photo_library_outlined,
          title: 'Gallery updated',
          description: fallbackDescription ?? 'Gallery content was changed',
        ),
      _ => null,
    };
  }

  _ActivityMapping? _mapTrails(
    String actionType,
    String? entityName,
    String? fallbackDescription,
  ) {
    return switch (actionType) {
      VenueManagementActivityActionTypes.created => _ActivityMapping(
          icon: Icons.route_outlined,
          title: 'Trail added',
          description: _quotedEntityDescription(entityName, 'was added') ??
              fallbackDescription ??
              'A trail was added',
        ),
      VenueManagementActivityActionTypes.updated => _ActivityMapping(
          icon: Icons.route_outlined,
          title: 'Trail updated',
          description: _quotedEntityDescription(entityName, 'was updated') ??
              fallbackDescription ??
              'A trail was updated',
        ),
      VenueManagementActivityActionTypes.archived => _ActivityMapping(
          icon: Icons.route_outlined,
          title: 'Trail removed',
          description: _quotedEntityDescription(entityName, 'was removed') ??
              fallbackDescription ??
              'A trail was removed',
        ),
      _ => null,
    };
  }

  _ActivityMapping _unknownMapping(String? fallbackDescription) {
    return _ActivityMapping(
      icon: Icons.history_outlined,
      title: 'Venue activity',
      description: fallbackDescription ?? 'A change was made to your venue',
    );
  }
}

class _ActivityMapping {
  const _ActivityMapping({
    required this.icon,
    required this.title,
    this.description,
  });

  final IconData icon;
  final String title;
  final String? description;
}
