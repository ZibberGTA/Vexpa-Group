import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/core/vexcore/web_vexcore.dart';
import 'package:nightlife_web/features/venue_management/data/venue_management_activity_service.dart';
import 'package:nightlife_web/features/venue_management/models/venue_management_activity.dart';

/// Configurable in-memory activity service for widget and unit tests.
class FakeVenueManagementActivityService
    implements VenueManagementActivityService {
  FakeVenueManagementActivityService({
    Map<String, List<VenueManagementActivity>> sourceAreaActivities = const {},
    List<VenueManagementActivity> venueActivities = const [],
    Map<String, List<VenueManagementActivity>> entityActivities = const {},
    Object? loadRecentError,
    Object? loadSourceAreaError,
    Object? loadEntityError,
  })  : _sourceAreaActivities = {
          for (final entry in sourceAreaActivities.entries)
            entry.key: List<VenueManagementActivity>.from(entry.value),
        },
        _venueActivities = List<VenueManagementActivity>.from(venueActivities),
        _entityActivities = {
          for (final entry in entityActivities.entries)
            entry.key: List<VenueManagementActivity>.from(entry.value),
        },
        _loadRecentError = loadRecentError,
        _loadSourceAreaError = loadSourceAreaError,
        _loadEntityError = loadEntityError;

  final Map<String, List<VenueManagementActivity>> _sourceAreaActivities;
  final List<VenueManagementActivity> _venueActivities;
  final Map<String, List<VenueManagementActivity>> _entityActivities;
  final Object? _loadRecentError;
  final Object? _loadSourceAreaError;
  final Object? _loadEntityError;

  final List<VenueManagementActivity> recordedActivities = [];
  int loadRecentCallCount = 0;
  int loadSourceAreaCallCount = 0;
  int loadEntityCallCount = 0;

  @override
  Future<void> recordActivity(VenueManagementActivity activity) async {
    recordedActivities.add(activity);
  }

  @override
  Future<List<VenueManagementActivity>> loadRecentActivity({
    required String venueId,
    int limit = 10,
  }) async {
    loadRecentCallCount++;
    final error = _loadRecentError;
    if (error != null) throw error;
    return _venueActivities.take(limit).toList(growable: false);
  }

  @override
  Future<List<VenueManagementActivity>> loadRecentActivityForSourceArea({
    required String venueId,
    required String sourceArea,
    int limit = 10,
  }) async {
    loadSourceAreaCallCount++;
    final error = _loadSourceAreaError;
    if (error != null) throw error;
    final items = _sourceAreaActivities[sourceArea] ?? const [];
    return items.take(limit).toList(growable: false);
  }

  @override
  Future<List<VenueManagementActivity>> loadRecentActivityForEntity({
    required String venueId,
    required String entityType,
    required String entityId,
    int limit = 10,
  }) async {
    loadEntityCallCount++;
    final error = _loadEntityError;
    if (error != null) throw error;
    final key = '$entityType:$entityId';
    final items = _entityActivities[key] ?? const [];
    return items.take(limit).toList(growable: false);
  }
}

/// Registers a harmless no-op activity service for management widget tests.
void registerDefaultVenueManagementActivityTestIsolation() {
  setUp(() {
    WebVexCore.venueManagementActivityServiceOverride =
        const NoOpVenueManagementActivityService();
  });

  tearDown(() {
    WebVexCore.venueManagementActivityServiceOverride = null;
  });
}
