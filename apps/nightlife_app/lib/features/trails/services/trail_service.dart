import 'package:flutter/foundation.dart';

import '../models/trail_model.dart';
import 'trail_service_config.dart';
import 'trail_service_facade.dart';
import 'trail_service_legacy.dart';
import 'trail_service_types.dart';

export 'trail_service_types.dart';

/// Mobile Trail API — delegates to the VexTrail facade by default.
class TrailService {
  TrailService._();

  static const String activeTrailId = TrailServiceFacade.activeTrailId;

  static bool _useFacade() => TrailServiceMigrationConfig.enabled;

  static Future<DrinkSpotTrailModel?> getTrail(String trailId) =>
      _useFacade()
      ? TrailServiceFacade.getTrail(trailId)
      : TrailServiceLegacy.getTrail(trailId);

  static Stream<DrinkSpotTrailModel?> watchTrail(String trailId) =>
      _useFacade()
      ? TrailServiceFacade.watchTrail(trailId)
      : TrailServiceLegacy.watchTrail(trailId);

  static Stream<List<DrinkSpotTrailModel>> watchStaffTrails() =>
      _useFacade()
      ? TrailServiceFacade.watchStaffTrails()
      : TrailServiceLegacy.watchStaffTrails();

  static Stream<List<DrinkSpotTrailModel>> watchVisibleTrails() =>
      _useFacade()
      ? TrailServiceFacade.watchVisibleTrails()
      : TrailServiceLegacy.watchVisibleTrails();

  static Stream<DrinkSpotTrailModel?> watchActiveTrail() =>
      _useFacade()
      ? TrailServiceFacade.watchActiveTrail()
      : TrailServiceLegacy.watchActiveTrail();

  static Stream<DrinkSpotTrailModel?> watchStaffTrail({
    String trailId = activeTrailId,
  }) =>
      _useFacade()
      ? TrailServiceFacade.watchStaffTrail(trailId: trailId)
      : TrailServiceLegacy.watchStaffTrail(trailId: trailId);

  static Future<String> createTrail({
    required String name,
    required String description,
    required String bannerImageUrl,
    required String area,
    required DateTime availabilityStart,
    required DateTime availabilityEnd,
    required TrailType trailType,
  }) =>
      _useFacade()
      ? TrailServiceFacade.createTrail(
          name: name,
          description: description,
          bannerImageUrl: bannerImageUrl,
          area: area,
          availabilityStart: availabilityStart,
          availabilityEnd: availabilityEnd,
          trailType: trailType,
        )
      : TrailServiceLegacy.createTrail(
          name: name,
          description: description,
          bannerImageUrl: bannerImageUrl,
          area: area,
          availabilityStart: availabilityStart,
          availabilityEnd: availabilityEnd,
          trailType: trailType,
        );

  static Future<void> updateTrailMetadata({
    required String trailId,
    required String name,
    required String description,
    required String bannerImageUrl,
    required String area,
    required DateTime availabilityStart,
    required DateTime availabilityEnd,
    required TrailType trailType,
  }) =>
      _useFacade()
      ? TrailServiceFacade.updateTrailMetadata(
          trailId: trailId,
          name: name,
          description: description,
          bannerImageUrl: bannerImageUrl,
          area: area,
          availabilityStart: availabilityStart,
          availabilityEnd: availabilityEnd,
          trailType: trailType,
        )
      : TrailServiceLegacy.updateTrailMetadata(
          trailId: trailId,
          name: name,
          description: description,
          bannerImageUrl: bannerImageUrl,
          area: area,
          availabilityStart: availabilityStart,
          availabilityEnd: availabilityEnd,
          trailType: trailType,
        );

  static Future<String> duplicateTrail(String trailId) =>
      _useFacade()
      ? TrailServiceFacade.duplicateTrail(trailId)
      : TrailServiceLegacy.duplicateTrail(trailId);

  static Future<void> unpublishTrail(String trailId) =>
      _useFacade()
      ? TrailServiceFacade.unpublishTrail(trailId)
      : TrailServiceLegacy.unpublishTrail(trailId);

  static Future<void> archiveTrail(String trailId) =>
      _useFacade()
      ? TrailServiceFacade.archiveTrail(trailId)
      : TrailServiceLegacy.archiveTrail(trailId);

  static Future<void> deleteTrail(String trailId) =>
      _useFacade()
      ? TrailServiceFacade.deleteTrail(trailId)
      : TrailServiceLegacy.deleteTrail(trailId);

  static Future<void> generateDraftTrail({String trailId = activeTrailId}) =>
      _useFacade()
      ? TrailServiceFacade.generateDraftTrail(trailId: trailId)
      : TrailServiceLegacy.generateDraftTrail(trailId: trailId);

  static Future<void> saveTrailStops(
    List<TrailStopModel> stops, {
    String trailId = activeTrailId,
  }) =>
      _useFacade()
      ? TrailServiceFacade.saveTrailStops(stops, trailId: trailId)
      : TrailServiceLegacy.saveTrailStops(stops, trailId: trailId);

  static Future<List<TrailVenueOption>> fetchVenueOptions() =>
      _useFacade()
      ? TrailServiceFacade.fetchVenueOptions()
      : TrailServiceLegacy.fetchVenueOptions();

  static Future<void> publishTrail({String trailId = activeTrailId}) =>
      _useFacade()
      ? TrailServiceFacade.publishTrail(trailId: trailId)
      : TrailServiceLegacy.publishTrail(trailId: trailId);

  static Future<void> disableTrail({String trailId = activeTrailId}) =>
      _useFacade()
      ? TrailServiceFacade.disableTrail(trailId: trailId)
      : TrailServiceLegacy.disableTrail(trailId: trailId);

  static Stream<TrailProgressModel?> watchMyTrailProgress({
    required String trailId,
  }) =>
      _useFacade()
      ? TrailServiceFacade.watchMyTrailProgress(trailId: trailId)
      : TrailServiceLegacy.watchMyTrailProgress(trailId: trailId);

  static Future<void> startTrail(DrinkSpotTrailModel trail) =>
      _useFacade()
      ? TrailServiceFacade.startTrail(trail)
      : TrailServiceLegacy.startTrail(trail);

  static Future<void> joinTrail(
    String trailId, {
    DrinkSpotTrailModel? trail,
  }) =>
      _useFacade()
      ? TrailServiceFacade.joinTrail(trailId, trail: trail)
      : TrailServiceLegacy.joinTrail(trailId, trail: trail);

  static Future<TrailCheckInValidation> validateStopCheckIn({
    required TrailStopModel stop,
  }) =>
      _useFacade()
      ? TrailServiceFacade.validateStopCheckIn(stop: stop)
      : TrailServiceLegacy.validateStopCheckIn(stop: stop);

  static Future<void> checkInAtStop({
    required DrinkSpotTrailModel trail,
    required TrailStopModel stop,
    required int stopIndex,
  }) =>
      _useFacade()
      ? TrailServiceFacade.checkInAtStop(
          trail: trail,
          stop: stop,
          stopIndex: stopIndex,
        )
      : TrailServiceLegacy.checkInAtStop(
          trail: trail,
          stop: stop,
          stopIndex: stopIndex,
        );

  static Future<int?> continueTrail({
    required DrinkSpotTrailModel trail,
    required TrailStopModel stop,
    required int stopIndex,
  }) =>
      _useFacade()
      ? TrailServiceFacade.continueTrail(
          trail: trail,
          stop: stop,
          stopIndex: stopIndex,
        )
      : TrailServiceLegacy.continueTrail(
          trail: trail,
          stop: stop,
          stopIndex: stopIndex,
        );

  static Future<int?> skipStop({
    required DrinkSpotTrailModel trail,
    required TrailStopModel stop,
    required int stopIndex,
  }) =>
      _useFacade()
      ? TrailServiceFacade.skipStop(
          trail: trail,
          stop: stop,
          stopIndex: stopIndex,
        )
      : TrailServiceLegacy.skipStop(
          trail: trail,
          stop: stop,
          stopIndex: stopIndex,
        );

  static Future<void> logTrailDirectionsRequested({
    required String trailId,
    required TrailStopModel stop,
  }) =>
      _useFacade()
      ? TrailServiceFacade.logTrailDirectionsRequested(
          trailId: trailId,
          stop: stop,
        )
      : TrailServiceLegacy.logTrailDirectionsRequested(
          trailId: trailId,
          stop: stop,
        );

  static Future<void> logTrailAction({
    required String trailId,
    required String action,
    String? venueId,
    int? stopOrder,
  }) =>
      _useFacade()
      ? TrailServiceFacade.logTrailAction(
          trailId: trailId,
          action: action,
          venueId: venueId,
          stopOrder: stopOrder,
        )
      : TrailServiceLegacy.logTrailAction(
          trailId: trailId,
          action: action,
          venueId: venueId,
          stopOrder: stopOrder,
        );

  @visibleForTesting
  static void overrideUseVexTrailFacade(bool? enabled) {
    TrailServiceMigrationConfig.overrideForTests = enabled;
  }

  @visibleForTesting
  static void resetMigrationTestOverrides() {
    TrailServiceMigrationConfig.resetTestOverrides();
  }
}
