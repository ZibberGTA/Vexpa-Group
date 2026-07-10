import 'package:vex_core/vex_core.dart';

import '../../features/venue/data/models/event_model.dart';

VenueEvent vexVenueEventFromEventModel(EventModel model) {
  return VenueEvent(
    id: model.id,
    venueId: model.venueId,
    title: model.title,
    description: model.description,
    startDateTime: model.startDateTime,
    endDateTime: model.endDateTime,
    category: model.category,
    imageUrl: model.imageUrl,
    artist: model.artist,
    isActive: model.isActive,
    featured: model.featured,
    isDeleted: model.isDeleted,
  );
}

EventModel eventModelFromVexVenueEvent(VenueEvent event) {
  return EventModel(
    id: event.id,
    venueId: event.venueId,
    title: event.title,
    description: event.description,
    startDateTime: event.startDateTime,
    endDateTime: event.endDateTime,
    createdAt: DateTime.now(),
    category: event.category,
    imageUrl: event.imageUrl,
    isDeleted: event.isDeleted,
    artist: event.artist,
    isActive: event.isActive,
    featured: event.featured,
  );
}
