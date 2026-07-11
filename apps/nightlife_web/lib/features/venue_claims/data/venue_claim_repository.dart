import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:vex_engines/claim/application/claim_confidence_scorer.dart';
import 'package:vex_engines/claim/application/claim_review_service.dart';
import 'package:vex_engines/claim/application/claim_search_service.dart';
import 'package:vex_engines/claim/application/claim_submission_service.dart';
import 'package:vex_engines/claim/domain/claim_evidence.dart';
import 'package:vex_engines/claim/domain/claim_result.dart';
import 'package:vex_engines/claim/domain/claim_status.dart';
import 'package:vex_engines/claim/shared/claim_search_support.dart';

import '../../../core/firebase/vexda_firebase.dart';
import '../models/venue_claim.dart';
import '../models/venue_claim_search_response.dart';

class VenueClaimSubmissionResult {
  const VenueClaimSubmissionResult({
    required this.claimId,
    required this.venueId,
    required this.status,
    required this.autoApproved,
    this.confidenceScore = 0,
    this.confidenceReasons = const [],
  });

  final String claimId;
  final String venueId;
  final VenueClaimStatus status;
  final bool autoApproved;
  final int confidenceScore;
  final List<String> confidenceReasons;
}

class VenueClaimRepository {
  VenueClaimRepository({
    FirebaseFirestore? firestore,
    ClaimSubmissionService? submissionService,
    ClaimReviewService? reviewService,
    ClaimConfidenceScorer? confidenceScorer,
    ClaimSearchService? searchService,
  }) : _firestoreOverride = firestore,
       _submissionService = submissionService ?? const ClaimSubmissionService(),
       _reviewService = reviewService ?? const ClaimReviewService(),
       _confidenceScorer = confidenceScorer ?? const ClaimConfidenceScorer(),
       _searchService = searchService ?? const ClaimSearchService();

  static const int autoApprovalThreshold = 75;

  final FirebaseFirestore? _firestoreOverride;
  final ClaimSubmissionService _submissionService;
  final ClaimReviewService _reviewService;
  final ClaimConfidenceScorer _confidenceScorer;
  final ClaimSearchService _searchService;
  FirebaseFirestore? _firestore;

  FirebaseFunctions get _functions => FirebaseFunctions.instance;

  FirebaseFirestore? _resolveFirestore() {
    if (_firestoreOverride != null) return _firestoreOverride;
    if (!VexdaFirebase.isReady) return null;
    return _firestore ??= FirebaseFirestore.instance;
  }

  Future<VenueClaimSearchResponse> searchVenues(String query) async {
    final firestore = _resolveFirestore();
    if (firestore == null) {
      return VenueClaimSearchResponse.failure(
        'Venue search is unavailable. Refresh the page and try again.',
        source: 'firebase-unavailable',
      );
    }

    final interpretation = _searchService.interpretQuery(query);
    if (interpretation is ClaimSearchTooShort) {
      return VenueClaimSearchResponse.ok(const [], source: 'query-too-short');
    }

    final searchQuery = (interpretation as ClaimSearchReady).query;
    if (kDebugMode) {
      debugPrint(
        '[VenueClaimRepository] search term="${searchQuery.normalized}" '
        'tokens=${searchQuery.tokens}',
      );
    }

    try {
      final directoryResults = await _searchClaimDirectory(
        firestore,
        searchQuery,
      );
      if (directoryResults.isNotEmpty) {
        if (kDebugMode) {
          debugPrint(
            '[VenueClaimRepository] directory results=${directoryResults.length}',
          );
        }
        return VenueClaimSearchResponse.ok(
          directoryResults,
          source: 'venue_claim_directory',
        );
      }

      final indexedResults = await _searchIndexedVenues(firestore, searchQuery);
      if (indexedResults.isNotEmpty) {
        if (kDebugMode) {
          debugPrint(
            '[VenueClaimRepository] indexed results=${indexedResults.length}',
          );
        }
        return VenueClaimSearchResponse.ok(
          indexedResults,
          source: 'venues-indexed',
        );
      }

      final fallback = await _searchVenuesFallback(firestore, searchQuery);
      if (kDebugMode) {
        debugPrint(
          '[VenueClaimRepository] fallback scanned=${fallback.scannedCount} '
          'results=${fallback.results.length}',
        );
      }
      return fallback;
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[VenueClaimRepository] search failed path=venues '
          'term="${searchQuery.normalized}" '
          'code=${error.code} message=${error.message}',
        );
      }
      return VenueClaimSearchResponse.failure(
        _searchErrorMessage(error),
        source: 'firestore-${error.code}',
      );
    }
  }

  Future<List<VenueClaimSearchResult>> _searchClaimDirectory(
    FirebaseFirestore firestore,
    ClaimSearchQuery searchQuery,
  ) async {
    try {
      final snapshot = await firestore
          .collection('venue_claim_directory')
          .limit(ClaimSearchLimits.directoryFetchLimit)
          .get();

      final results = <VenueClaimSearchResult>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (!ClaimSearchSupport.isClaimableVenue(data)) continue;

        final venueId = (data['venueId'] ?? doc.id).toString();
        final venue = VenueClaimSearchResult.fromFirestore(venueId, data);
        if (!ClaimSearchSupport.matchesQuery(
          venue,
          searchQuery.normalized,
          searchQuery.tokens,
        )) {
          continue;
        }
        results.add(venue);
        if (!_searchService.shouldCollectMore(results.length)) break;
      }
      return results;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        if (kDebugMode) {
          debugPrint(
            '[VenueClaimRepository] venue_claim_directory read denied — '
            'falling back to venues',
          );
        }
        return const [];
      }
      rethrow;
    }
  }

  Future<List<VenueClaimSearchResult>> _searchIndexedVenues(
    FirebaseFirestore firestore,
    ClaimSearchQuery searchQuery,
  ) async {
    final matches = <String, VenueClaimSearchResult>{};

    Future<void> runQuery(
      String label,
      Future<QuerySnapshot<Map<String, dynamic>>> Function() query,
    ) async {
      try {
        final snapshot = await query();
        _collectSearchMatches(
          snapshot: snapshot,
          searchQuery: searchQuery,
          matches: matches,
        );
        if (kDebugMode) {
          debugPrint(
            '[VenueClaimRepository] $label fetched=${snapshot.docs.length} '
            'matched=${matches.length}',
          );
        }
      } on FirebaseException catch (error) {
        if (kDebugMode) {
          debugPrint(
            '[VenueClaimRepository] $label query failed (${error.code})',
          );
        }
      }
    }

    final queryTokens = _searchService.indexedQueryTokens(searchQuery);

    for (final token in queryTokens) {
      await runQuery(
        'searchKeywords:$token',
        () => firestore
            .collection('venues')
            .where('searchKeywords', arrayContains: token)
            .limit(ClaimSearchLimits.indexedTokenQueryLimit)
            .get(),
      );
      if (!_searchService.shouldCollectMore(matches.length)) break;
    }

    if (_searchService.shouldCollectMore(matches.length)) {
      await runQuery(
        'nameLower-prefix',
        () => firestore
            .collection('venues')
            .where('nameLower', isGreaterThanOrEqualTo: searchQuery.normalized)
            .where('nameLower', isLessThan: '${searchQuery.normalized}\uf8ff')
            .limit(ClaimSearchLimits.indexedPrefixQueryLimit)
            .get(),
      );
    }

    if (_searchService.shouldCollectMore(matches.length)) {
      await runQuery(
        'postcodeLower-prefix',
        () => firestore
            .collection('venues')
            .where(
              'postcodeLower',
              isGreaterThanOrEqualTo: searchQuery.normalized,
            )
            .where(
              'postcodeLower',
              isLessThan: '${searchQuery.normalized}\uf8ff',
            )
            .limit(ClaimSearchLimits.indexedPrefixQueryLimit)
            .get(),
      );
    }

    if (_searchService.shouldCollectMore(matches.length)) {
      await runQuery(
        'isClaimed:false',
        () => firestore
            .collection('venues')
            .where('isClaimed', isEqualTo: false)
            .limit(ClaimSearchLimits.indexedUnclaimedLimit)
            .get(),
      );
    }

    return _searchService.finalizeResults(matches.values, searchQuery);
  }

  Future<VenueClaimSearchResponse> _searchVenuesFallback(
    FirebaseFirestore firestore,
    ClaimSearchQuery searchQuery,
  ) async {
    final matches = <String, VenueClaimSearchResult>{};
    DocumentSnapshot<Map<String, dynamic>>? lastDocument;
    var scanned = 0;

    while (_searchService.shouldContinueFallback(
      scannedDocuments: scanned,
      matchCount: matches.length,
    )) {
      Query<Map<String, dynamic>> query = firestore
          .collection('venues')
          .limit(ClaimSearchLimits.fallbackBatchSize);
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) break;

      scanned += snapshot.docs.length;
      lastDocument = snapshot.docs.last;

      _collectSearchMatches(
        snapshot: snapshot,
        searchQuery: searchQuery,
        matches: matches,
      );
    }

    return VenueClaimSearchResponse.ok(
      _searchService.finalizeResults(matches.values, searchQuery),
      source: 'venues-fallback',
      scannedCount: scanned,
    );
  }

  void _collectSearchMatches({
    required QuerySnapshot<Map<String, dynamic>> snapshot,
    required ClaimSearchQuery searchQuery,
    required Map<String, VenueClaimSearchResult> matches,
  }) {
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final venue = VenueClaimSearchResult.fromFirestore(doc.id, data);
      _searchService.tryMergeCandidate(
        matches: matches,
        candidate: venue,
        normalizedQuery: searchQuery.normalized,
        tokens: searchQuery.tokens,
      );
      if (!_searchService.shouldCollectMore(matches.length)) return;
    }
  }

  static String _searchErrorMessage(FirebaseException error) {
    return switch (error.code) {
      'permission-denied' =>
        'Venue search is blocked by permissions. Sign in as a venue owner and try again.',
      'failed-precondition' || 'unavailable' =>
        'Venue search is temporarily unavailable (Firestore index required). '
            'Please try again shortly.',
      _ =>
        'Venue search failed (${error.code}). Please try again or contact support.',
    };
  }

  Stream<List<VenueClaim>> watchMyClaims(String uid, {int limit = 10}) {
    final firestore = _resolveFirestore();
    if (firestore == null || uid.trim().isEmpty) {
      return Stream.value(const []);
    }
    return firestore
        .collection('venue_claims')
        .where('claimantUid', isEqualTo: uid)
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => VenueClaim.fromFirestore(doc.id, doc.data()))
              .toList(growable: false),
        );
  }

  Stream<List<VenueClaim>> watchClaimsForAdmin({int limit = 50}) {
    final firestore = _resolveFirestore();
    if (firestore == null) return Stream.value(const []);
    return firestore
        .collection('venue_claims')
        .orderBy('submittedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => VenueClaim.fromFirestore(doc.id, doc.data()))
              .toList(growable: false),
        );
  }

  Future<VenueClaim?> loadClaim(String claimId) async {
    final firestore = _resolveFirestore();
    if (firestore == null || claimId.trim().isEmpty) return null;
    final doc = await firestore.collection('venue_claims').doc(claimId).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return VenueClaim.fromFirestore(doc.id, data);
  }

  Future<VenueClaimSubmissionResult> submitClaim({
    required User user,
    required VenueClaimSearchResult venue,
    required VenueClaimEvidence evidence,
    Iterable<ClaimStatus> existingStatusesForVenue = const [],
  }) async {
    final preparation = _submissionService.prepareSubmission(
      venueId: venue.venueId,
      claimantUid: user.uid,
      venue: venue,
      evidence: evidence,
      claimantActive: !user.isAnonymous,
      existingStatusesForVenue: existingStatusesForVenue,
    );
    if (preparation is ClaimFailure<ClaimSubmissionPayload>) {
      throw VenueClaimBackendException(preparation.message);
    }

    final payload = (preparation as ClaimSuccess<ClaimSubmissionPayload>).value;
    final response = await _callFunction(
      'submitVenueClaim',
      payload.toFunctionPayload(),
    );
    final status = VenueClaimStatusX.fromFirestore(response['status']);
    final claimId = (response['claimId'] ?? '').toString();
    final venueId = (response['venueId'] ?? venue.venueId).toString();
    final confidenceScore = response['confidenceScore'] is num
        ? (response['confidenceScore'] as num).round()
        : 0;

    return VenueClaimSubmissionResult(
      claimId: claimId,
      venueId: venueId,
      status: status,
      autoApproved: response['autoApproved'] == true,
      confidenceScore: confidenceScore,
      confidenceReasons: _stringList(response['confidenceReasons']),
    );
  }

  Future<String> createVenueInstant({
    required User user,
    required String name,
    required String address,
    required String city,
    required String postcode,
    required String category,
    required String website,
    required String phone,
  }) async {
    final response = await _callFunction('createVenueInstant', {
      'name': name,
      'address': address,
      'city': city,
      'postcode': postcode,
      'category': category,
      'website': website,
      'phone': phone,
    });
    return (response['venueId'] ?? '').toString();
  }

  Future<void> saveDraft({
    required String claimId,
    required String claimantUid,
    required Map<String, dynamic> draftVenueData,
  }) async {
    final firestore = _requireFirestore();
    await firestore.collection('venue_claims').doc(claimId).set({
      'claimantUid': claimantUid,
      'draftVenueData': draftVenueData,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> approveClaim({
    required String claimId,
    required String reviewerUid,
    String notes = '',
    ClaimStatus currentStatus = ClaimStatus.pendingReview,
    bool reviewerCanApprove = true,
  }) async {
    final review = _reviewService.prepareReview(
      claimId: claimId,
      action: ClaimReviewAction.approve,
      currentStatus: currentStatus,
      notes: notes,
      reviewerCanApprove: reviewerCanApprove,
    );
    if (review is ClaimFailure<ClaimReviewPayload>) {
      throw VenueClaimBackendException(review.message);
    }
    final payload = (review as ClaimSuccess<ClaimReviewPayload>).value;
    await _callFunction(payload.functionName, payload.toFunctionPayload());
  }

  Future<void> rejectClaim({
    required String claimId,
    required String reviewerUid,
    required String notes,
    ClaimStatus currentStatus = ClaimStatus.pendingReview,
    bool reviewerCanApprove = true,
  }) async {
    final review = _reviewService.prepareReview(
      claimId: claimId,
      action: ClaimReviewAction.reject,
      currentStatus: currentStatus,
      notes: notes,
      reviewerCanApprove: reviewerCanApprove,
    );
    if (review is ClaimFailure<ClaimReviewPayload>) {
      throw VenueClaimBackendException(review.message);
    }
    final payload = (review as ClaimSuccess<ClaimReviewPayload>).value;
    await _callFunction(payload.functionName, payload.toFunctionPayload());
  }

  Future<void> requestMoreInformation({
    required String claimId,
    required String reviewerUid,
    required String notes,
    ClaimStatus currentStatus = ClaimStatus.pendingReview,
    bool reviewerCanApprove = true,
  }) async {
    final review = _reviewService.prepareReview(
      claimId: claimId,
      action: ClaimReviewAction.requestMoreInfo,
      currentStatus: currentStatus,
      notes: notes,
      reviewerCanApprove: reviewerCanApprove,
    );
    if (review is ClaimFailure<ClaimReviewPayload>) {
      throw VenueClaimBackendException(review.message);
    }
    final payload = (review as ClaimSuccess<ClaimReviewPayload>).value;
    await _callFunction(payload.functionName, payload.toFunctionPayload());
  }

  Future<void> withdrawClaim({
    required String claimId,
    String notes = '',
    ClaimStatus currentStatus = ClaimStatus.pendingReview,
  }) async {
    final review = _reviewService.prepareReview(
      claimId: claimId,
      action: ClaimReviewAction.withdraw,
      currentStatus: currentStatus,
      notes: notes,
      reviewerCanApprove: false,
    );
    if (review is ClaimFailure<ClaimReviewPayload>) {
      throw VenueClaimBackendException(review.message);
    }
    final payload = (review as ClaimSuccess<ClaimReviewPayload>).value;
    await _callFunction(payload.functionName, payload.toFunctionPayload());
  }

  Stream<List<VenueClaimAuditEvent>> watchClaimAudit(
    String claimId, {
    int limit = 50,
  }) {
    final firestore = _resolveFirestore();
    if (firestore == null || claimId.trim().isEmpty) {
      return Stream.value(const []);
    }
    return firestore
        .collection('venue_claims')
        .doc(claimId)
        .collection('audit')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => VenueClaimAuditEvent.fromFirestore(doc.id, doc.data()),
              )
              .toList(growable: false),
        );
  }

  VenueClaimScore scoreClaim({
    required VenueClaimSearchResult venue,
    required VenueClaimEvidence evidence,
  }) => _confidenceScorer.score(venue: venue, evidence: evidence);

  FirebaseFirestore _requireFirestore() {
    final firestore = _resolveFirestore();
    if (firestore == null) throw StateError('Firestore is not available.');
    return firestore;
  }

  Future<Map<String, dynamic>> _callFunction(
    String name,
    Map<String, dynamic> payload,
  ) async {
    try {
      final result = await _functions.httpsCallable(name).call(payload);
      final data = result.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return const {};
    } on FirebaseFunctionsException catch (error) {
      throw VenueClaimBackendException(_friendlyFunctionMessage(error));
    }
  }

  static List<String> _stringList(Object? value) {
    if (value is! Iterable) return const [];
    return value.map((item) => item.toString()).toList(growable: false);
  }

  static String _friendlyFunctionMessage(FirebaseFunctionsException error) {
    return switch (error.code) {
      'unauthenticated' => 'Sign in to continue.',
      'permission-denied' => 'You do not have permission to do that.',
      'not-found' => 'The claim or venue could not be found.',
      'already-exists' => 'You already have an active claim for this venue.',
      'failed-precondition' => 'This claim cannot move to that status yet.',
      _ =>
        'The claim service could not complete the request. Please try again.',
    };
  }
}

class VenueClaimBackendException implements Exception {
  const VenueClaimBackendException(this.message);

  final String message;

  @override
  String toString() => message;
}
