import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:vex_core/vex_core.dart';
import 'package:vex_engines/experience/application/experience_content_orchestrator.dart';
import 'package:vex_engines/experience/application/venue_content_ordering_service.dart';
import 'package:vex_engines/experience/application/venue_featured_content_service.dart';
import 'package:vex_engines/experience/application/venue_presentation_support.dart';

import '../../../core/firebase/vexda_firebase.dart';
import '../../../core/vexcore/vex_venue_deal_mapper.dart';
import '../../../core/vexcore/web_vexcore.dart';
import '../../venue/data/models/deal_model.dart';
import '../../venue/data/public_venue_content_filters.dart';
import '../../venue_management/data/deal_write_payload.dart';
import '../../venue_management/data/venue_management_activity_action_inference.dart';
import '../../venue_management/data/venue_management_activity_recording.dart';
import '../../venue_management/data/venue_management_activity_service.dart';
import '../../venue_management/models/bulk_deal_patch.dart';
import '../../venue_management/models/deal_types.dart';
import '../../venue_management/models/venue_management_activity_types.dart';

/// Loads and writes deals for a venue.
class VenueDealsRepository {
  VenueDealsRepository({
    FirebaseFirestore? firestore,
    VenueDealDataService? venueDealDataService,
    ExperienceContentOrchestrator? contentOrchestrator,
    VenueManagementActivityService? activityService,
  }) : _firestoreOverride = firestore,
       _venueDealDataService =
           venueDealDataService ?? WebVexCore.venueDealDataService,
       _contentOrchestrator = contentOrchestrator ?? _defaultOrchestrator,
       _activityService =
           activityService ?? WebVexCore.venueManagementActivityService;

  static const _defaultOrchestrator = ExperienceContentOrchestrator();
  static const _ordering = VenueContentOrderingService();
  static const _featured = VenueFeaturedContentService();

  final FirebaseFirestore? _firestoreOverride;
  final VenueDealDataService _venueDealDataService;
  final ExperienceContentOrchestrator _contentOrchestrator;
  final VenueManagementActivityService _activityService;

  FirebaseFirestore? _resolveFirestore() {
    if (_firestoreOverride != null) return _firestoreOverride;
    if (!VexdaFirebase.isReady) return null;
    return FirebaseFirestore.instance;
  }

  Stream<List<DealModel>> watchDeals(String venueId) {
    final trimmedId = venueId.trim();
    if (trimmedId.isEmpty) {
      return Stream.value(const []);
    }

    return _venueDealDataService.watchPublicDeals(trimmedId).map((result) {
      return switch (result) {
        DataSuccess(:final value) => _visibleDeals(value),
        DataFailure(:final error) => throw error,
      };
    });
  }

  List<DealModel> _visibleDeals(List<VenueDeal> deals, {DateTime? now}) {
    final mapped = deals.map(dealModelFromVexVenueDeal).toList();
    final clock = now ?? DateTime.now();
    final visible = _contentOrchestrator.filterPublicVisibleDeals(
      mapped,
      isDeleted: (deal) => deal.isDeleted,
      isActive: (deal) => deal.isActive,
      startDateTime: (deal) => deal.startDateTime,
      endDateTime: (deal) => deal.endDateTime,
      effectiveEndDateTime: (deal) => deal.effectiveEndDateTime,
      now: clock,
    );
    return _ordering.sortPublicDeals(
      deals: visible,
      isUpcoming: (deal) => isPublicUpcomingDeal(deal, now: clock),
      startDateTime: (deal) => deal.startDateTime,
      now: clock,
    );
  }

  /// All non-deleted deals for venue management (includes paused/expired).
  Stream<List<DealModel>> watchManagementDeals(String venueId) async* {
    final firestore = _resolveFirestore();
    if (firestore == null) {
      yield const [];
      return;
    }

    yield* firestore
        .collection('deals')
        .where('venueId', isEqualTo: venueId)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          final deals =
              snapshot.docs
                  .map((doc) => DealModel.fromMap(doc.id, doc.data()))
                  .toList()
                ..sort(
                  (a, b) =>
                      a.title.toLowerCase().compareTo(b.title.toLowerCase()),
                );
          return deals;
        });
  }

  /// One-time fetch of non-deleted deals for dashboard schedule composition.
  Future<List<DealModel>> fetchScheduleDeals({
    required String venueId,
  }) async {
    final trimmedId = venueId.trim();
    if (trimmedId.isEmpty) return const [];

    final firestore = _resolveFirestore();
    if (firestore == null) return const [];

    try {
      final snapshot = await firestore
          .collection('deals')
          .where('venueId', isEqualTo: trimmedId)
          .where('isDeleted', isEqualTo: false)
          .get();

      return snapshot.docs
          .map((doc) => DealModel.fromMap(doc.id, doc.data()))
          .toList();
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[VenueDealsRepository] schedule deals (${error.code})',
        );
      }
      return const [];
    }
  }

  Future<String> addDeal({
    required String venueId,
    required String venueName,
    required String title,
    required String description,
    required String dealType,
    required String value,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required List<String> availableDays,
    required String startTime,
    required String endTime,
    required bool isActive,
    required bool featured,
    required String createdBy,
  }) async {
    if (!DealTypes.isAllowed(dealType)) {
      throw ArgumentError('Invalid deal type.');
    }

    final firestore = _resolveFirestore();
    if (firestore == null) {
      throw StateError('Firestore is not available.');
    }

    final docRef = firestore.collection('deals').doc();
    final payload = DealWritePayload.build(
      venueId: venueId,
      venueName: venueName,
      title: title,
      description: description,
      dealType: dealType,
      value: value,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      availableDays: availableDays,
      startTime: startTime,
      endTime: endTime,
      isActive: isActive,
      featured: featured,
      createdBy: createdBy,
    );

    try {
      await docRef.set(payload);
      await _recordDealActivity(
        venueId: venueId,
        dealId: docRef.id,
        dealTitle: title,
        actorUid: createdBy,
        actionType: VenueManagementActivityActionTypes.created,
        description: 'Deal created',
      );
      return docRef.id;
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint('[VenueDealsRepository] add deal failed (${error.code})');
      }
      rethrow;
    }
  }

  Future<String> duplicateDeal({
    required DealModel source,
    required String venueName,
    required String createdBy,
  }) async {
    final trimmedTitle = source.title.trim();
    final copyTitle = _featured.duplicateCopyTitle(trimmedTitle);
    final defaults = _featured.duplicateDealDefaults(
      sourceStart: source.startDateTime,
      sourceEnd: source.endDateTime,
    );

    return addDeal(
      venueId: source.venueId,
      venueName: venueName,
      title: copyTitle,
      description: source.description,
      dealType: source.dealType,
      value: source.value,
      startDateTime: defaults.startDateTime,
      endDateTime: defaults.endDateTime,
      availableDays: source.availableDays,
      startTime: source.startTime,
      endTime: source.endTime,
      isActive: defaults.isActive,
      featured: defaults.featured,
      createdBy: createdBy,
    );
  }

  Future<void> updateDeal({
    required String dealId,
    required String venueId,
    required String venueName,
    required String title,
    required String description,
    required String dealType,
    required String value,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required List<String> availableDays,
    required String startTime,
    required String endTime,
    required bool isActive,
    required bool featured,
    required String updatedBy,
  }) async {
    if (!DealTypes.isAllowed(dealType)) {
      throw ArgumentError('Invalid deal type.');
    }

    final firestore = _resolveFirestore();
    if (firestore == null) {
      throw StateError('Firestore is not available.');
    }

    final payload = DealWritePayload.buildUpdate(
      venueName: venueName,
      title: title,
      description: description,
      dealType: dealType,
      value: value,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      availableDays: availableDays,
      startTime: startTime,
      endTime: endTime,
      isActive: isActive,
      featured: featured,
      updatedBy: updatedBy,
    );

    try {
      await firestore.collection('deals').doc(dealId).update(payload);
      await _recordDealActivity(
        venueId: venueId,
        dealId: dealId,
        dealTitle: title,
        actorUid: updatedBy,
        actionType: VenueManagementActivityActionTypes.updated,
        description: 'Deal updated',
      );
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint('[VenueDealsRepository] update deal failed (${error.code})');
      }
      rethrow;
    }
  }

  Future<void> deleteDeal({
    required String dealId,
    required String deletedBy,
    String? deletedByEmail,
    String? venueId,
    String? dealTitle,
  }) async {
    final firestore = _resolveFirestore();
    if (firestore == null) {
      throw StateError('Firestore is not available.');
    }

    final payload = <String, dynamic>{
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'deletedBy': deletedBy,
      'deletedByEmail': ?deletedByEmail,
    };

    try {
      await firestore.collection('deals').doc(dealId).update(payload);
      if (venueId != null &&
          venueId.trim().isNotEmpty &&
          dealTitle != null &&
          dealTitle.trim().isNotEmpty) {
        await _recordDealActivity(
          venueId: venueId,
          dealId: dealId,
          dealTitle: dealTitle,
          actorUid: deletedBy,
          actionType: VenueManagementActivityActionTypes.archived,
          description: 'Deal archived',
        );
      }
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint('[VenueDealsRepository] delete deal failed (${error.code})');
      }
      rethrow;
    }
  }

  Future<void> bulkDeleteDeals({
    required List<DealModel> deals,
    required String deletedBy,
    String? deletedByEmail,
  }) async {
    for (final deal in deals) {
      await deleteDeal(
        dealId: deal.id,
        deletedBy: deletedBy,
        deletedByEmail: deletedByEmail,
        venueId: deal.venueId,
        dealTitle: deal.title,
      );
    }
  }

  Future<void> patchDeal({
    required String dealId,
    required String venueId,
    required String venueName,
    required String title,
    required String description,
    required String dealType,
    required String value,
    required BulkDealPatch patch,
    required String updatedBy,
  }) async {
    if (patch.isEmpty) return;

    if (patch.dealType != null && !DealTypes.isAllowed(patch.dealType!)) {
      throw ArgumentError('Invalid deal type.');
    }

    final firestore = _resolveFirestore();
    if (firestore == null) {
      throw StateError('Firestore is not available.');
    }

    final payload = DealWritePayload.buildPatch(
      venueName: venueName,
      title: title,
      description: description,
      dealType: dealType,
      value: value,
      updatedBy: updatedBy,
      titlePatch: patch.title,
      dealTypePatch: patch.dealType,
      valuePatch: patch.value,
      startDateTime: patch.startDateTime,
      endDateTime: patch.endDateTime,
      isActive: patch.isActive,
      featured: patch.featured,
    );

    try {
      await firestore.collection('deals').doc(dealId).update(payload);
      final resolvedTitle = patch.title ?? title;
      await _recordDealActivity(
        venueId: venueId,
        dealId: dealId,
        dealTitle: resolvedTitle,
        actorUid: updatedBy,
        actionType: VenueManagementActivityActionInference.dealPatchActionType(
          patch,
        ),
        description: patch.isActive != null
            ? (patch.isActive! ? 'Deal activated' : 'Deal deactivated')
            : 'Deal updated',
      );
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint('[VenueDealsRepository] patch deal failed (${error.code})');
      }
      rethrow;
    }
  }

  static const _presentation = VenuePresentationSupport();

  static String relativeTimeLabel(DateTime date) =>
      _presentation.managementRelativeTimeLabel(date);

  Future<void> _recordDealActivity({
    required String venueId,
    required String dealId,
    required String dealTitle,
    required String actorUid,
    required String actionType,
    required String description,
  }) {
    return VenueManagementActivityRecording.recordDeal(
      service: _activityService,
      venueId: venueId,
      dealId: dealId,
      dealTitle: dealTitle,
      actorUid: actorUid,
      actionType: actionType,
      description: description,
    );
  }
}
