/// Known analytics event types stored in the shared `analytics` collection.
enum AnalyticsEventType {
  venueView('venue_view'),
  favouriteTap('favourite_tap'),
  drinkView('drink_view'),
  dealView('deal_view'),
  eventView('event_view'),
  crowdUpdate('crowd_update'),
  notificationLead('notification_lead');

  const AnalyticsEventType(this.firestoreValue);

  final String firestoreValue;

  static AnalyticsEventType? parse(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    for (final type in AnalyticsEventType.values) {
      if (type.firestoreValue == normalized) return type;
    }
    return null;
  }
}

/// Standard dashboard count query order for venue metrics.
const List<AnalyticsEventType> analyticsDashboardCountTypes = [
  AnalyticsEventType.venueView,
  AnalyticsEventType.favouriteTap,
  AnalyticsEventType.drinkView,
  AnalyticsEventType.dealView,
  AnalyticsEventType.eventView,
];
