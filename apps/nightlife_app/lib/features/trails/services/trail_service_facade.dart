import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vex_core/data/data_result.dart';
import 'package:vex_core/trails/trails.dart';
import 'package:vex_engines/trail/trail_engine.dart' as vex;

import '../../../core/utils/distance_formatter.dart';
import '../../../core/vexcore/mobile_trail_orchestration.dart';
import '../../../core/vexcore/mobile_vexcore_trail_stack.dart';
import '../models/trail_model.dart';
import 'trail_compat_mapper.dart';
import 'trail_service_types.dart';

/// VexTrail-backed production implementation of the mobile TrailService API.
final class TrailServiceFacade {
  TrailServiceFacade._();

  static const String activeTrailId = TrailPaths.activeTrailDocumentId;

  static Future<DrinkSpotTrailModel?> getTrail(String trailId) async {
    final result = await MobileTrailOrchestration.discovery.getTrail(trailId);
    return switch (result) {
      vex.TrailApplicationSuccess(value: final trail) =>
        TrailCompatMapper.fromDomain(trail),
      _ => null,
    };
  }

  static Stream<DrinkSpotTrailModel?> watchTrail(String trailId) {
    return MobileVexCoreTrailStack.trailRepository.watch(trailId).map((result) {
      if (result case DataFailure()) return null;
      return TrailCompatMapper.fromSnapshot(
        (result as DataSuccess<TrailSnapshot?>).value,
      );
    });
  }

  static Stream<List<DrinkSpotTrailModel>> watchStaffTrails() {
    return MobileVexCoreTrailStack.trailRepository
        .watchList(
          TrailListQuery(
            limit: 500,
            includeArchived: true,
            sort: TrailListSort.generatedAtDesc,
          ),
        )
        .map((result) {
          if (result case DataFailure()) return <DrinkSpotTrailModel>[];
          return (result as DataSuccess<List<TrailSnapshot>>).value
              .map(TrailCompatMapper.fromSnapshot)
              .whereType<DrinkSpotTrailModel>()
              .toList();
        });
  }

  static Stream<List<DrinkSpotTrailModel>> watchVisibleTrails() {
    return MobileTrailOrchestration.discovery.watchVisibleTrails().map((result) {
      if (result case vex.TrailApplicationFailure()) {
        return <DrinkSpotTrailModel>[];
      }
      return (result as vex.TrailApplicationSuccess<List<vex.Trail>>).value
          .map(TrailCompatMapper.fromDomain)
          .where((trail) => trail.isVisible)
          .toList();
    });
  }

  static Stream<DrinkSpotTrailModel?> watchActiveTrail() {
    final user = MobileVexCoreTrailStack.userContext.currentUser();
    if (!user.isAuthenticated) {
      return _watchVisibleTrailFallback();
    }

    late StreamSubscription<DataResult<TrailActiveStateSnapshot?>> activeSub;
    StreamSubscription<DataResult<List<TrailSnapshot>>>? trailsSub;
    var selectedTrailId = activeTrailId;
    var latestTrails = <TrailSnapshot>[];

    final controller = StreamController<DrinkSpotTrailModel?>(
      onCancel: () async {
        await trailsSub?.cancel();
        await activeSub.cancel();
      },
    );

    void emitVisibleTrail() {
      controller.add(
        TrailCompatMapper.visibleTrailFromSnapshots(
          latestTrails,
          selectedTrailId,
        ),
      );
    }

    activeSub = MobileVexCoreTrailStack.progressRepository
        .watchActiveState(userId: user.userId!)
        .listen((result) {
          selectedTrailId = switch (result) {
            DataSuccess(value: final state?) => state.activeTrailId,
            _ => activeTrailId,
          };
          emitVisibleTrail();
        }, onError: controller.addError);

    trailsSub = MobileVexCoreTrailStack.trailRepository
        .watchList(
          TrailListQuery(limit: 500, includeArchived: true),
        )
        .listen((result) {
          if (result case DataSuccess(value: final trails)) {
            latestTrails = trails;
            emitVisibleTrail();
          }
        }, onError: controller.addError);

    return controller.stream;
  }

  static Stream<DrinkSpotTrailModel?> _watchVisibleTrailFallback() {
    return MobileVexCoreTrailStack.trailRepository
        .watchList(TrailListQuery(limit: 500, includeArchived: true))
        .map((result) {
          if (result case DataFailure()) return null;
          return TrailCompatMapper.visibleTrailFromSnapshots(
            (result as DataSuccess<List<TrailSnapshot>>).value,
            activeTrailId,
          );
        });
  }

  static Stream<DrinkSpotTrailModel?> watchStaffTrail({
    String trailId = activeTrailId,
  }) {
    return watchTrail(trailId);
  }

  static Future<String> createTrail({
    required String name,
    required String description,
    required String bannerImageUrl,
    required String area,
    required DateTime availabilityStart,
    required DateTime availabilityEnd,
    required TrailType trailType,
  }) async {
    final result = await MobileTrailOrchestration.management.createDraft(
      name: name,
      description: description,
      bannerImageUrl: bannerImageUrl,
      area: area,
      availabilityStart: availabilityStart,
      availabilityEnd: availabilityEnd,
      trailType: _domainType(trailType),
    );
    return switch (result) {
      vex.TrailApplicationSuccess(value: final trail) => trail.id,
      _ => '',
    };
  }

  static Future<void> updateTrailMetadata({
    required String trailId,
    required String name,
    required String description,
    required String bannerImageUrl,
    required String area,
    required DateTime availabilityStart,
    required DateTime availabilityEnd,
    required TrailType trailType,
  }) async {
    await MobileTrailOrchestration.management.updateMetadata(
      trailId: trailId,
      name: name,
      description: description,
      bannerImageUrl: bannerImageUrl,
      area: area,
      availabilityStart: availabilityStart,
      availabilityEnd: availabilityEnd,
      trailType: _domainType(trailType),
    );
  }

  static Future<String> duplicateTrail(String trailId) async {
    final result = await MobileTrailOrchestration.management.duplicate(trailId);
    return switch (result) {
      vex.TrailApplicationSuccess(value: final trail) => trail.id,
      _ => '',
    };
  }

  static Future<void> unpublishTrail(String trailId) async {
    await MobileTrailOrchestration.management.unpublish(trailId);
  }

  static Future<void> archiveTrail(String trailId) async {
    await MobileTrailOrchestration.management.archive(trailId);
  }

  static Future<void> deleteTrail(String trailId) async {
    await MobileTrailOrchestration.management.delete(trailId);
  }

  static Future<void> generateDraftTrail({
    String trailId = activeTrailId,
  }) async {
    final venuesSnap = await FirebaseFirestore.instance
        .collection('venues')
        .where('isDeleted', isEqualTo: false)
        .limit(100)
        .get();

    final candidates = venuesSnap.docs
        .map(
          (doc) => TrailCompatMapper.generationCandidateFromVenue(
            venueId: doc.id,
            data: doc.data(),
          ),
        )
        .toList();

    await MobileTrailOrchestration.generation.generateAndPersistDraft(
      candidates: candidates,
      trailId: trailId,
    );
  }

  static Future<void> saveTrailStops(
    List<TrailStopModel> stops, {
    String trailId = activeTrailId,
  }) async {
    await MobileTrailOrchestration.management.updateStops(
      trailId: trailId,
      stops: stops.map(TrailCompatMapper.toDomainStop).toList(),
    );
  }

  static Future<List<TrailVenueOption>> fetchVenueOptions() async {
    final snap = await FirebaseFirestore.instance
        .collection('venues')
        .where('isDeleted', isEqualTo: false)
        .limit(150)
        .get();

    final venues = snap.docs.map((doc) {
      final data = doc.data();
      return TrailVenueOption(
        id: doc.id,
        name: (data['name'] ?? 'Venue').toString(),
        address: (data['address'] ?? '').toString(),
        bannerImageUrl: (data['bannerImageUrl'] ?? data['imageUrl'] ?? '')
            .toString(),
        logoUrl: (data['logoUrl'] ?? '').toString(),
      );
    }).toList();

    venues.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return venues;
  }

  static Future<void> publishTrail({String trailId = activeTrailId}) async {
    await MobileTrailOrchestration.management.publishLegacyCompatible(trailId);
  }

  static Future<void> disableTrail({String trailId = activeTrailId}) async {
    await archiveTrail(trailId);
  }

  static Stream<TrailProgressModel?> watchMyTrailProgress({
    required String trailId,
  }) {
    final user = MobileVexCoreTrailStack.userContext.currentUser();
    if (!user.isAuthenticated) {
      return Stream<TrailProgressModel?>.value(null);
    }

    return MobileTrailOrchestration.progress.watchProgress(trailId).map((result) {
      return switch (result) {
        vex.TrailApplicationSuccess(value: final progress?) =>
          TrailCompatMapper.fromDomainProgress(progress),
        _ => null,
      };
    });
  }

  static Future<void> startTrail(DrinkSpotTrailModel trail) async {
    await joinTrail(trail.id, trail: trail);
  }

  static Future<void> joinTrail(
    String trailId, {
    DrinkSpotTrailModel? trail,
  }) async {
    if (MobileVexCoreTrailStack.userContext.currentUser().userId == null) {
      return;
    }

    final domainTrail = trail == null
        ? switch (await MobileTrailOrchestration.discovery.getTrail(trailId)) {
            vex.TrailApplicationSuccess(value: final loaded) => loaded,
            _ => null,
          }
        : TrailCompatMapper.toDomain(trail);
    if (domainTrail == null) return;

    await MobileTrailOrchestration.progress.join(
      trailId: trailId,
      trail: domainTrail,
    );
  }

  static Future<TrailCheckInValidation> validateStopCheckIn({
    required TrailStopModel stop,
  }) async {
    try {
      final presence = await MobileVexCoreTrailStack.venueLookup.lookup(
        stop.venueId,
      );
      if (presence == null ||
          presence.latitude == null ||
          presence.longitude == null) {
        return const TrailCheckInValidation.allowed();
      }

      final radiusMeters = presence.presenceRadiusMeters ?? 75.0;
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const TrailCheckInValidation.blocked(
          message: 'Location services are off. Turn location on to check in.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const TrailCheckInValidation.blocked(
          message: 'Location permission is needed to check in to a trail stop.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final distanceMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        presence.latitude!,
        presence.longitude!,
      );

      if (distanceMeters <= radiusMeters) {
        return TrailCheckInValidation.allowed(distanceMeters: distanceMeters);
      }

      return TrailCheckInValidation.blocked(
        distanceMeters: distanceMeters,
        message:
            'You need to be within ${DistanceFormatter.formatMeters(radiusMeters)} of ${stop.venueName} to check in. You are about ${DistanceFormatter.formatMeters(distanceMeters)} away.',
      );
    } catch (_) {
      return const TrailCheckInValidation.blocked(
        message: 'Could not verify your location. Try again in a moment.',
      );
    }
  }

  static Future<void> checkInAtStop({
    required DrinkSpotTrailModel trail,
    required TrailStopModel stop,
    required int stopIndex,
  }) async {
    if (MobileVexCoreTrailStack.userContext.currentUser().userId == null) {
      return;
    }

    final domainTrail = TrailCompatMapper.toDomain(trail);
    final domainStop = TrailCompatMapper.toDomainStop(stop);
    final progress = await _loadDomainProgress(trail.id, domainTrail);

    await MobileTrailOrchestration.progress.checkIn(
      trail: domainTrail,
      stop: domainStop,
      stopIndex: stopIndex,
      progress: progress,
    );
  }

  static Future<int?> continueTrail({
    required DrinkSpotTrailModel trail,
    required TrailStopModel stop,
    required int stopIndex,
  }) async {
    if (MobileVexCoreTrailStack.userContext.currentUser().userId == null) {
      return null;
    }

    final domainTrail = TrailCompatMapper.toDomain(trail);
    final domainStop = TrailCompatMapper.toDomainStop(stop);
    final progress = await _loadDomainProgress(trail.id, domainTrail);

    final result = await MobileTrailOrchestration.progress.continueStop(
      trail: domainTrail,
      stop: domainStop,
      stopIndex: stopIndex,
      progress: progress,
    );

    return switch (result) {
      vex.TrailApplicationSuccess(value: final updated) =>
        TrailCompatMapper.nextUpcomingStopIndex(
          trail: trail,
          afterIndex: stopIndex,
          progress: updated,
        ),
      _ => null,
    };
  }

  static Future<int?> skipStop({
    required DrinkSpotTrailModel trail,
    required TrailStopModel stop,
    required int stopIndex,
  }) async {
    if (MobileVexCoreTrailStack.userContext.currentUser().userId == null) {
      return null;
    }

    final domainTrail = TrailCompatMapper.toDomain(trail);
    final domainStop = TrailCompatMapper.toDomainStop(stop);
    final progress = await _loadDomainProgress(trail.id, domainTrail);

    final result = await MobileTrailOrchestration.progress.skipStop(
      trail: domainTrail,
      stop: domainStop,
      stopIndex: stopIndex,
      progress: progress,
    );

    return switch (result) {
      vex.TrailApplicationSuccess(value: final updated) =>
        TrailCompatMapper.nextUpcomingStopIndex(
          trail: trail,
          afterIndex: stopIndex,
          progress: updated,
        ),
      _ => null,
    };
  }

  static Future<void> logTrailDirectionsRequested({
    required String trailId,
    required TrailStopModel stop,
  }) async {
    await MobileTrailOrchestration.activity.logDirectionsRequested(
      trailId: trailId,
      venueId: stop.venueId,
      stopOrder: stop.order,
    );
  }

  static Future<void> logTrailAction({
    required String trailId,
    required String action,
    String? venueId,
    int? stopOrder,
  }) async {
    await MobileTrailOrchestration.activity.logAction(
      trailId: trailId,
      action: action,
      venueId: venueId,
      stopOrder: stopOrder,
    );
  }

  static Future<vex.TrailProgress> _loadDomainProgress(
    String trailId,
    vex.Trail domainTrail,
  ) async {
    final result = await MobileTrailOrchestration.progress.getProgress(trailId);
    return switch (result) {
      vex.TrailApplicationSuccess(value: final progress) => progress,
      _ => TrailCompatMapper.initialDomainProgress(domainTrail),
    };
  }

  static vex.TrailType _domainType(TrailType type) {
    return switch (type) {
      TrailType.curated => vex.TrailType.curated,
      TrailType.generated => vex.TrailType.generated,
    };
  }
}
