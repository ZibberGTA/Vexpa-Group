import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/utils/distance_formatter.dart';
import '../models/trail_model.dart';

class TrailService {
  TrailService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String activeTrailId = 'activeTrail';

  static DocumentReference<Map<String, dynamic>> _trailRef(String trailId) =>
      _db.collection('trails').doc(trailId);

  static DocumentReference<Map<String, dynamic>>? get _myActiveTrailRef {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _db
        .collection('users')
        .doc(uid)
        .collection('trail_state')
        .doc('active');
  }

  static DocumentReference<Map<String, dynamic>>? _myTrailProgressRef(
    String trailId,
  ) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _db
        .collection('users')
        .doc(uid)
        .collection('trails')
        .doc(trailId)
        .collection('progress')
        .doc('current');
  }

  static DocumentReference<Map<String, dynamic>>?
  get _legacyMyTrailProgressRef {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _db.collection('trail_progress').doc(uid);
  }

  static Future<DrinkSpotTrailModel?> getTrail(String trailId) async {
    final doc = await _trailRef(trailId).get();
    if (!doc.exists) return null;
    return DrinkSpotTrailModel.fromDoc(doc);
  }

  static Stream<DrinkSpotTrailModel?> watchTrail(String trailId) {
    return _trailRef(trailId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return DrinkSpotTrailModel.fromDoc(doc);
    });
  }

  static Stream<List<DrinkSpotTrailModel>> watchStaffTrails() {
    return _db.collection('trails').snapshots().map((snapshot) {
      final trails = snapshot.docs.map(DrinkSpotTrailModel.fromDoc).toList()
        ..sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
      return trails;
    });
  }

  static Stream<List<DrinkSpotTrailModel>> watchVisibleTrails() {
    return _db.collection('trails').snapshots().map((snapshot) {
      final trails = snapshot.docs
          .map(DrinkSpotTrailModel.fromDoc)
          .where((trail) => trail.isVisible)
          .toList();
      trails.sort((a, b) {
        final typeComparison = a.trailType.index.compareTo(b.trailType.index);
        if (typeComparison != 0) return typeComparison;
        return b.averageRating.compareTo(a.averageRating);
      });
      return trails;
    });
  }

  static Stream<DrinkSpotTrailModel?> watchActiveTrail() {
    final activeRef = _myActiveTrailRef;
    if (activeRef == null) {
      return _watchVisibleTrailFallback();
    }

    late StreamSubscription<DocumentSnapshot<Map<String, dynamic>>> activeSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? trailsSub;
    var selectedTrailId = activeTrailId;
    List<QueryDocumentSnapshot<Map<String, dynamic>>> latestTrailDocs =
        const <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    final controller = StreamController<DrinkSpotTrailModel?>(
      onCancel: () async {
        await trailsSub?.cancel();
        await activeSub.cancel();
      },
    );

    void emitVisibleTrail() {
      controller.add(_visibleTrailFromDocs(latestTrailDocs, selectedTrailId));
    }

    activeSub = activeRef.snapshots().listen((doc) async {
      selectedTrailId =
          doc.data()?['activeTrailId']?.toString() ?? activeTrailId;
      emitVisibleTrail();
    }, onError: controller.addError);

    trailsSub = _db.collection('trails').snapshots().listen((snapshot) {
      latestTrailDocs = snapshot.docs;
      emitVisibleTrail();
    }, onError: controller.addError);

    return controller.stream;
  }

  static Stream<DrinkSpotTrailModel?> _watchVisibleTrailFallback() {
    return _db.collection('trails').snapshots().map((snapshot) {
      return _visibleTrailFromDocs(snapshot.docs, activeTrailId);
    });
  }

  static DrinkSpotTrailModel? _visibleTrailFromDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String preferredTrailId,
  ) {
    DrinkSpotTrailModel? firstVisibleTrail;

    for (final doc in docs) {
      final trail = DrinkSpotTrailModel.fromDoc(doc);
      if (!trail.isVisible) continue;
      firstVisibleTrail ??= trail;
      if (trail.id == preferredTrailId) return trail;
    }

    return firstVisibleTrail;
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
    final now = DateTime.now();
    final ref = _db.collection('trails').doc();
    final trail = DrinkSpotTrailModel(
      id: ref.id,
      name: name.trim().isEmpty ? 'Untitled Trail' : name.trim(),
      description: description.trim(),
      bannerImageUrl: bannerImageUrl.trim(),
      area: area.trim(),
      status: TrailStatus.draft,
      published: false,
      generatedAt: now,
      availabilityStart: availabilityStart,
      availabilityEnd: availabilityEnd,
      estimatedDuration: availabilityEnd.difference(availabilityStart),
      estimatedWalkingDistance: 0,
      venueCount: 0,
      trailType: trailType,
      stops: const <TrailStopModel>[],
    );

    await ref.set({
      ...trail.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
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
    await _trailRef(trailId).set({
      'name': name.trim().isEmpty ? 'Untitled Trail' : name.trim(),
      'title': name.trim().isEmpty ? 'Untitled Trail' : name.trim(),
      'description': description.trim(),
      'subtitle': description.trim(),
      'bannerImageUrl': bannerImageUrl.trim(),
      'area': area.trim(),
      'availabilityStart': Timestamp.fromDate(availabilityStart),
      'availabilityEnd': Timestamp.fromDate(availabilityEnd),
      'startTime': Timestamp.fromDate(availabilityStart),
      'endTime': Timestamp.fromDate(availabilityEnd),
      'estimatedDurationMinutes': availabilityEnd
          .difference(availabilityStart)
          .inMinutes,
      'trailType': trailType.key,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<String> duplicateTrail(String trailId) async {
    final source = await getTrail(trailId);
    if (source == null) return '';

    final ref = _db.collection('trails').doc();
    final data = source.toMap();
    data['name'] = '${source.name} Copy';
    data['title'] = '${source.name} Copy';
    data['status'] = TrailStatus.draft.key;
    data['published'] = false;
    data['generatedAt'] = Timestamp.fromDate(DateTime.now());
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    data.remove('publishedAt');
    data.remove('disabledAt');
    data.remove('archivedAt');

    await ref.set(data);
    return ref.id;
  }

  static Future<void> unpublishTrail(String trailId) async {
    await _trailRef(trailId).set({
      'status': TrailStatus.draft.key,
      'published': false,
      'unpublishedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> archiveTrail(String trailId) async {
    await _trailRef(trailId).set({
      'status': TrailStatus.archived.key,
      'published': false,
      'archivedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> deleteTrail(String trailId) async {
    await _trailRef(trailId).delete();
  }

  static Future<void> generateDraftTrail({
    String trailId = activeTrailId,
  }) async {
    final venuesSnap = await _db
        .collection('venues')
        .where('isDeleted', isEqualTo: false)
        .limit(100)
        .get();

    final scored = venuesSnap.docs.map((doc) {
      final data = doc.data();
      final level = (data['crowdLevel'] ?? '').toString().toLowerCase();
      final category = (data['category'] ?? '').toString().toLowerCase();
      var score = 0;

      switch (level) {
        case 'packed':
          score += 45;
          break;
        case 'busy':
          score += 35;
          break;
        case 'medium':
        case 'steady':
          score += 22;
          break;
        case 'quiet':
          score += 8;
          break;
        default:
          score += 10;
      }

      if (data['hasDeals'] == true) score += 10;
      if (category.contains('cocktail')) score += 8;
      if (category.contains('bar')) score += 6;
      if (category.contains('club')) score += 6;
      if ((data['bannerImageUrl'] ?? '').toString().isNotEmpty) score += 4;
      if ((data['featureTags'] is List) &&
          (data['featureTags'] as List).isNotEmpty) {
        score += 4;
      }

      return _ScoredVenue(id: doc.id, data: data, score: score);
    }).toList()..sort((a, b) => b.score.compareTo(a.score));

    final selected = scored.take(4).toList();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 19);
    final trailStart = now.isAfter(start)
        ? now.add(const Duration(minutes: 30))
        : start;

    final stops = <TrailStopModel>[];
    for (var i = 0; i < selected.length; i++) {
      final venue = selected[i];
      final arriveAt = trailStart.add(Duration(minutes: i * 85));
      final leaveAt = arriveAt.add(const Duration(minutes: 75));
      stops.add(
        TrailStopModel(
          venueId: venue.id,
          venueName: (venue.data['name'] ?? 'Venue').toString(),
          address: (venue.data['address'] ?? '').toString(),
          bannerImageUrl:
              (venue.data['bannerImageUrl'] ?? venue.data['imageUrl'] ?? '')
                  .toString(),
          logoUrl: (venue.data['logoUrl'] ?? '').toString(),
          order: i + 1,
          score: venue.score,
          arriveAt: arriveAt,
          leaveAt: leaveAt,
        ),
      );
    }

    final end = stops.isEmpty
        ? trailStart.add(const Duration(hours: 5))
        : stops.last.leaveAt;
    final trail = DrinkSpotTrailModel(
      id: trailId,
      name: "Tonight's Trail",
      description: 'Auto-generated from lively and buzzing venues',
      status: TrailStatus.draft,
      published: false,
      generatedAt: now,
      availabilityStart: trailStart,
      availabilityEnd: end,
      estimatedDuration: end.difference(trailStart),
      venueCount: stops.length,
      trailType: TrailType.curated,
      stops: stops,
    );

    await _trailRef(trailId).set(trail.toMap(), SetOptions(merge: false));
  }

  static Future<void> saveTrailStops(
    List<TrailStopModel> stops, {
    String trailId = activeTrailId,
  }) async {
    final orderedStops = <TrailStopModel>[];
    for (var i = 0; i < stops.length; i++) {
      orderedStops.add(stops[i].copyWith(order: i + 1));
    }

    final startTime = orderedStops.isEmpty
        ? DateTime.now()
        : orderedStops.first.arriveAt;
    final endTime = orderedStops.isEmpty
        ? DateTime.now()
        : orderedStops.last.leaveAt;

    await _trailRef(trailId).set({
      'stops': orderedStops.map((stop) => stop.toMap()).toList(),
      'venueCount': orderedStops.length,
      'availabilityStart': Timestamp.fromDate(startTime),
      'availabilityEnd': Timestamp.fromDate(endTime),
      'estimatedDurationMinutes': endTime.difference(startTime).inMinutes,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'status': TrailStatus.draft.key,
      'published': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<List<TrailVenueOption>> fetchVenueOptions() async {
    final snap = await _db
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
    await _trailRef(trailId).update({
      'status': TrailStatus.published.key,
      'published': true,
      'publishedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> disableTrail({String trailId = activeTrailId}) async {
    await archiveTrail(trailId);
  }

  static Stream<TrailProgressModel?> watchMyTrailProgress({
    required String trailId,
  }) {
    final ref = _myTrailProgressRef(trailId);
    if (ref == null) return Stream<TrailProgressModel?>.value(null);

    return ref.snapshots().asyncMap((doc) async {
      if (!doc.exists) {
        if (trailId != activeTrailId) return null;
        final legacyDoc = await _legacyMyTrailProgressRef?.get();
        if (legacyDoc == null || !legacyDoc.exists) return null;
        return TrailProgressModel.fromDoc(legacyDoc);
      }
      return TrailProgressModel.fromDoc(doc);
    });
  }

  static Future<void> startTrail(DrinkSpotTrailModel trail) async {
    await joinTrail(trail.id, trail: trail);
  }

  static Future<void> joinTrail(
    String trailId, {
    DrinkSpotTrailModel? trail,
  }) async {
    final selectedTrail = trail ?? await getTrail(trailId);
    if (selectedTrail == null) return;

    final ref = _myTrailProgressRef(trailId);
    if (ref == null) return;

    await _myActiveTrailRef?.set({
      'activeTrailId': trailId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final data = {
      'trailId': trailId,
      'trailGeneratedAt': Timestamp.fromDate(selectedTrail.generatedAt),
      'started': true,
      'completed': false,
      'currentStop': 0,
      'checkedInStops': <int>[],
      'stopStates': _initialStopStates(selectedTrail),
      'startedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await ref.set(data, SetOptions(merge: false));
    if (trailId == activeTrailId) {
      await _legacyMyTrailProgressRef?.set(data, SetOptions(merge: true));
    }

    await logTrailAction(trailId: trailId, action: 'started');
  }

  static Future<TrailCheckInValidation> validateStopCheckIn({
    required TrailStopModel stop,
  }) async {
    try {
      final venueDoc = await _db.collection('venues').doc(stop.venueId).get();
      final data = venueDoc.data();
      if (data == null) {
        return const TrailCheckInValidation.allowed();
      }

      final location = data['location'];
      if (location is! GeoPoint) {
        return const TrailCheckInValidation.allowed();
      }

      final radiusRaw = data['presenceRadiusMeters'];
      final radiusMeters = (radiusRaw as num?)?.toDouble() ?? 75.0;

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
        location.latitude,
        location.longitude,
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
    final ref = _myTrailProgressRef(trail.id);
    if (ref == null) return;
    await _myActiveTrailRef?.set({
      'activeTrailId': trail.id,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final currentProgress = await _readTrailProgress(ref);
    final currentStop = currentProgress?.currentStop ?? 0;
    if (currentProgress?.started == true && stopIndex < currentStop) {
      return;
    }

    final stopStates = _statesForCheckIn(
      trail: trail,
      stopIndex: stopIndex,
      existing: currentProgress?.stopStates,
    );
    final completed = _trailComplete(trail, stopStates);

    final data = {
      'trailId': trail.id,
      'trailGeneratedAt': Timestamp.fromDate(trail.generatedAt),
      'started': true,
      'completed': completed,
      'currentStop': stopIndex,
      'checkedInStops': FieldValue.arrayUnion([stop.order]),
      'stopStates': _stopStatesToFirestore(stopStates),
      'lastCheckedInVenueId': stop.venueId,
      'lastCheckedInStopOrder': stop.order,
      if (completed) 'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await ref.set(data, SetOptions(merge: true));
    if (trail.id == activeTrailId) {
      await _legacyMyTrailProgressRef?.set(data, SetOptions(merge: true));
    }

    await logTrailAction(
      trailId: trail.id,
      action: 'arrived',
      venueId: stop.venueId,
      stopOrder: stop.order,
    );
  }

  static Future<int?> continueTrail({
    required DrinkSpotTrailModel trail,
    required TrailStopModel stop,
    required int stopIndex,
  }) async {
    final ref = _myTrailProgressRef(trail.id);
    if (ref == null) return null;

    final currentProgress = await _readTrailProgress(ref);
    final stopStates = Map<int, TrailStopProgressState>.from(
      currentProgress?.stopStates ?? const <int, TrailStopProgressState>{},
    );
    if (stopStates[stop.order] == TrailStopProgressState.checkedIn) {
      stopStates[stop.order] = TrailStopProgressState.completed;
    }
    final nextStopIndex = _nextUpcomingStopIndex(
      trail: trail,
      afterIndex: stopIndex,
      states: stopStates,
    );
    if (nextStopIndex != null) {
      stopStates[trail.stops[nextStopIndex].order] =
          TrailStopProgressState.current;
    }
    final completed =
        nextStopIndex == null || _trailComplete(trail, stopStates);
    final data = {
      'trailId': trail.id,
      'trailGeneratedAt': Timestamp.fromDate(trail.generatedAt),
      'started': true,
      'completed': completed,
      'currentStop': nextStopIndex ?? stopIndex,
      'stopStates': _stopStatesToFirestore(stopStates),
      if (completed) 'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await ref.set(data, SetOptions(merge: true));
    if (trail.id == activeTrailId) {
      await _legacyMyTrailProgressRef?.set(data, SetOptions(merge: true));
    }

    await logTrailAction(
      trailId: trail.id,
      action: completed ? 'completed' : 'continue_next',
      venueId: stop.venueId,
      stopOrder: stop.order,
    );
    return nextStopIndex;
  }

  static Future<int?> skipStop({
    required DrinkSpotTrailModel trail,
    required TrailStopModel stop,
    required int stopIndex,
  }) async {
    final ref = _myTrailProgressRef(trail.id);
    if (ref == null) return null;

    final currentProgress = await _readTrailProgress(ref);
    final stopStates = Map<int, TrailStopProgressState>.from(
      currentProgress?.stopStates ?? const <int, TrailStopProgressState>{},
    );
    stopStates[stop.order] = TrailStopProgressState.skipped;

    final nextStopIndex = _nextUpcomingStopIndex(
      trail: trail,
      afterIndex: stopIndex,
      states: stopStates,
    );
    if (nextStopIndex != null) {
      stopStates[trail.stops[nextStopIndex].order] =
          TrailStopProgressState.current;
    }
    final completed =
        nextStopIndex == null || _trailComplete(trail, stopStates);
    final data = {
      'trailId': trail.id,
      'trailGeneratedAt': Timestamp.fromDate(trail.generatedAt),
      'started': true,
      'completed': completed,
      'currentStop': nextStopIndex ?? stopIndex,
      'stopStates': _stopStatesToFirestore(stopStates),
      if (completed) 'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await ref.set(data, SetOptions(merge: true));
    if (trail.id == activeTrailId) {
      await _legacyMyTrailProgressRef?.set(data, SetOptions(merge: true));
    }

    await logTrailAction(
      trailId: trail.id,
      action: completed ? 'completed_after_skip' : 'skipped_stop',
      venueId: stop.venueId,
      stopOrder: stop.order,
    );
    return nextStopIndex;
  }

  static Future<TrailProgressModel?> _readTrailProgress(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    final doc = await ref.get();
    if (!doc.exists) return null;
    return TrailProgressModel.fromDoc(doc);
  }

  static Map<String, String> _initialStopStates(DrinkSpotTrailModel trail) {
    return {
      for (final entry in trail.stops.asMap().entries)
        entry.value.order.toString(): entry.key == 0
            ? TrailStopProgressState.current.key
            : TrailStopProgressState.upcoming.key,
    };
  }

  static Map<int, TrailStopProgressState> _statesForCheckIn({
    required DrinkSpotTrailModel trail,
    required int stopIndex,
    Map<int, TrailStopProgressState>? existing,
  }) {
    final states = Map<int, TrailStopProgressState>.from(
      existing ?? const <int, TrailStopProgressState>{},
    );
    for (final entry in trail.stops.asMap().entries) {
      final index = entry.key;
      final order = entry.value.order;
      final current = states[order];
      if (current == TrailStopProgressState.skipped ||
          current == TrailStopProgressState.completed) {
        continue;
      }
      if (index < stopIndex) {
        states[order] = current == TrailStopProgressState.checkedIn
            ? TrailStopProgressState.completed
            : TrailStopProgressState.missed;
      } else if (index == stopIndex) {
        states[order] = TrailStopProgressState.checkedIn;
      } else {
        states.putIfAbsent(order, () => TrailStopProgressState.upcoming);
      }
    }
    return states;
  }

  static int? _nextUpcomingStopIndex({
    required DrinkSpotTrailModel trail,
    required int afterIndex,
    required Map<int, TrailStopProgressState> states,
  }) {
    for (var index = afterIndex + 1; index < trail.stops.length; index++) {
      final state = states[trail.stops[index].order];
      if (state == null ||
          state == TrailStopProgressState.upcoming ||
          state == TrailStopProgressState.current) {
        return index;
      }
    }
    return null;
  }

  static bool _trailComplete(
    DrinkSpotTrailModel trail,
    Map<int, TrailStopProgressState> states,
  ) {
    if (trail.stops.isEmpty) return true;
    return trail.stops.every((stop) => states[stop.order]?.isTerminal == true);
  }

  static Map<String, String> _stopStatesToFirestore(
    Map<int, TrailStopProgressState> states,
  ) {
    return {
      for (final entry in states.entries) entry.key.toString(): entry.value.key,
    };
  }

  static Future<void> logTrailDirectionsRequested({
    required String trailId,
    required TrailStopModel stop,
  }) async {
    await logTrailAction(
      trailId: trailId,
      action: 'directions_requested',
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
    final user = _auth.currentUser;
    await _db.collection('trail_activity').add({
      'trailId': trailId,
      'userId': user?.uid,
      'isAnonymous': user?.isAnonymous,
      'action': action,
      'venueId': venueId,
      'stopOrder': stopOrder,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

class TrailCheckInValidation {
  final bool allowed;
  final double? distanceMeters;
  final String? message;

  const TrailCheckInValidation._({
    required this.allowed,
    this.distanceMeters,
    this.message,
  });

  const TrailCheckInValidation.allowed({double? distanceMeters})
    : this._(allowed: true, distanceMeters: distanceMeters);

  const TrailCheckInValidation.blocked({
    required String message,
    double? distanceMeters,
  }) : this._(allowed: false, distanceMeters: distanceMeters, message: message);
}

class _ScoredVenue {
  final String id;
  final Map<String, dynamic> data;
  final int score;

  const _ScoredVenue({
    required this.id,
    required this.data,
    required this.score,
  });
}

class TrailVenueOption {
  final String id;
  final String name;
  final String address;
  final String bannerImageUrl;
  final String logoUrl;

  const TrailVenueOption({
    required this.id,
    required this.name,
    required this.address,
    required this.bannerImageUrl,
    required this.logoUrl,
  });
}
