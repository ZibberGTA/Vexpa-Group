import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/vexda_firebase.dart';
import '../models/venue_claim.dart';
import '../models/venue_claim_search_response.dart';
import 'venue_claim_search_support.dart';

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
  VenueClaimRepository({FirebaseFirestore? firestore})
    : _firestoreOverride = firestore;

  static const int autoApprovalThreshold = 75;

  final FirebaseFirestore? _firestoreOverride;
  FirebaseFirestore? _firestore;

  FirebaseFunctions get _functions => FirebaseFunctions.instance;

  FirebaseFirestore? _resolveFirestore() {
    if (_firestoreOverride != null) return _firestoreOverride;
    if (!VexdaFirebase.isReady) return null;
    return _firestore ??= FirebaseFirestore.instance;
  }

  static const int _fallbackBatchSize = 150;
  static const int _fallbackMaxDocs = 900;
  static const int _maxResults = 40;

  Future<VenueClaimSearchResponse> searchVenues(String query) async {
    final firestore = _resolveFirestore();
    if (firestore == null) {
      return VenueClaimSearchResponse.failure(
        'Venue search is unavailable. Refresh the page and try again.',
        source: 'firebase-unavailable',
      );
    }

    final normalized = query.trim().toLowerCase();
    if (normalized.length < 2) {
      return VenueClaimSearchResponse.ok(const [], source: 'query-too-short');
    }

    final tokens = VenueClaimSearchSupport.tokenize(normalized);
    if (kDebugMode) {
      debugPrint(
        '[VenueClaimRepository] search term="$normalized" tokens=$tokens',
      );
    }

    try {
      final directoryResults = await _searchClaimDirectory(
        firestore,
        normalized,
        tokens,
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

      final indexedResults = await _searchIndexedVenues(
        firestore,
        normalized,
        tokens,
      );
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

      final fallback = await _searchVenuesFallback(
        firestore,
        normalized,
        tokens,
      );
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
          '[VenueClaimRepository] search failed path=venues term="$normalized" '
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
    String normalizedQuery,
    List<String> tokens,
  ) async {
    try {
      final snapshot = await firestore
          .collection('venue_claim_directory')
          .limit(400)
          .get();

      final results = <VenueClaimSearchResult>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (!VenueClaimSearchSupport.isClaimableVenue(data)) continue;

        final venueId = (data['venueId'] ?? doc.id).toString();
        final venue = VenueClaimSearchResult.fromFirestore(venueId, data);
        if (!VenueClaimSearchSupport.matchesQuery(
          venue,
          normalizedQuery,
          tokens,
        )) {
          continue;
        }
        results.add(venue);
        if (results.length >= _maxResults) break;
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
    String normalizedQuery,
    List<String> tokens,
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
          normalizedQuery: normalizedQuery,
          tokens: tokens,
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

    final queryTokens = tokens.isEmpty
        ? <String>[normalizedQuery]
        : tokens.take(3).toList(growable: false);

    for (final token in queryTokens) {
      await runQuery(
        'searchKeywords:$token',
        () => firestore
            .collection('venues')
            .where('searchKeywords', arrayContains: token)
            .limit(50)
            .get(),
      );
      if (matches.length >= _maxResults) break;
    }

    if (matches.length < _maxResults) {
      await runQuery(
        'nameLower-prefix',
        () => firestore
            .collection('venues')
            .where('nameLower', isGreaterThanOrEqualTo: normalizedQuery)
            .where('nameLower', isLessThan: '$normalizedQuery\uf8ff')
            .limit(40)
            .get(),
      );
    }

    if (matches.length < _maxResults) {
      await runQuery(
        'postcodeLower-prefix',
        () => firestore
            .collection('venues')
            .where('postcodeLower', isGreaterThanOrEqualTo: normalizedQuery)
            .where('postcodeLower', isLessThan: '$normalizedQuery\uf8ff')
            .limit(40)
            .get(),
      );
    }

    if (matches.length < _maxResults) {
      await runQuery(
        'isClaimed:false',
        () => firestore
            .collection('venues')
            .where('isClaimed', isEqualTo: false)
            .limit(120)
            .get(),
      );
    }

    return matches.values.take(_maxResults).toList(growable: false);
  }

  Future<VenueClaimSearchResponse> _searchVenuesFallback(
    FirebaseFirestore firestore,
    String normalizedQuery,
    List<String> tokens,
  ) async {
    final matches = <String, VenueClaimSearchResult>{};
    DocumentSnapshot<Map<String, dynamic>>? lastDocument;
    var scanned = 0;

    while (scanned < _fallbackMaxDocs && matches.length < _maxResults) {
      Query<Map<String, dynamic>> query = firestore
          .collection('venues')
          .limit(_fallbackBatchSize);
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) break;

      scanned += snapshot.docs.length;
      lastDocument = snapshot.docs.last;

      _collectSearchMatches(
        snapshot: snapshot,
        normalizedQuery: normalizedQuery,
        tokens: tokens,
        matches: matches,
      );
    }

    return VenueClaimSearchResponse.ok(
      matches.values.take(_maxResults).toList(growable: false),
      source: 'venues-fallback',
      scannedCount: scanned,
    );
  }

  void _collectSearchMatches({
    required QuerySnapshot<Map<String, dynamic>> snapshot,
    required String normalizedQuery,
    required List<String> tokens,
    required Map<String, VenueClaimSearchResult> matches,
  }) {
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (!VenueClaimSearchSupport.isClaimableVenue(data)) continue;

      final venue = VenueClaimSearchResult.fromFirestore(doc.id, data);
      if (!VenueClaimSearchSupport.matchesQuery(
        venue,
        normalizedQuery,
        tokens,
      )) {
        continue;
      }

      matches[venue.venueId] = venue;
      if (matches.length >= _maxResults) return;
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
  }) async {
    final response = await _callFunction('submitVenueClaim', {
      'venueId': venue.venueId,
      'submittedEvidence': evidence.toMap(),
      'draftVenueData': _initialDraftFromVenue(venue, evidence),
    });
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
  }) async {
    await _callFunction('approveVenueClaim', {
      'claimId': claimId,
      'notes': notes,
    });
  }

  Future<void> rejectClaim({
    required String claimId,
    required String reviewerUid,
    required String notes,
  }) async {
    await _callFunction('rejectVenueClaim', {
      'claimId': claimId,
      'notes': notes,
    });
  }

  Future<void> requestMoreInformation({
    required String claimId,
    required String reviewerUid,
    required String notes,
  }) async {
    await _callFunction('requestMoreClaimInfo', {
      'claimId': claimId,
      'notes': notes,
    });
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
  }) {
    final venueDomain = _domainFromUrl(venue.website);
    final evidenceEmailDomain = _domainFromEmail(evidence.businessEmail);
    final evidenceWebsiteDomain = _domainFromUrl(evidence.website);
    final phoneMatches =
        _digits(venue.phone).isNotEmpty &&
        _digits(venue.phone) == _digits(evidence.phone);

    final signals = [
      VenueClaimScoreSignal(
        key: 'business_email_domain',
        label: 'Business email matches venue domain',
        points: 35,
        matched: venueDomain.isNotEmpty && venueDomain == evidenceEmailDomain,
      ),
      VenueClaimScoreSignal(
        key: 'website_domain',
        label: 'Website matches existing venue website',
        points: 25,
        matched: venueDomain.isNotEmpty && venueDomain == evidenceWebsiteDomain,
      ),
      VenueClaimScoreSignal(
        key: 'company_registration',
        label: 'Company registration supplied',
        points: 25,
        matched: evidence.hasCompanyRegistration,
      ),
      VenueClaimScoreSignal(
        key: 'phone_match',
        label: 'Phone number matches venue listing',
        points: 15,
        matched: phoneMatches,
      ),
      VenueClaimScoreSignal(
        key: 'location_verification',
        label: 'Additional location notes supplied',
        points: 5,
        matched: evidence.notes.trim().length >= 20,
      ),
    ];

    final total = signals
        .where((signal) => signal.matched)
        .fold<int>(0, (totalPoints, signal) => totalPoints + signal.points)
        .clamp(0, 100)
        .toInt();

    return VenueClaimScore(
      score: total,
      threshold: autoApprovalThreshold,
      signals: signals,
    );
  }

  Map<String, dynamic> _initialDraftFromVenue(
    VenueClaimSearchResult venue,
    VenueClaimEvidence evidence,
  ) {
    return {
      'name': venue.name,
      'address': venue.rawData['address'] ?? venue.displayAddress,
      'city': venue.city,
      'postcode': venue.postcode,
      'category': venue.category,
      'venueType': venue.category,
      'description': (venue.rawData['description'] ?? '').toString(),
      'website': evidence.website.trim().isEmpty
          ? venue.website
          : evidence.website.trim(),
      'websiteUrl': evidence.website.trim().isEmpty
          ? venue.website
          : evidence.website.trim(),
      'phone': evidence.phone.trim().isEmpty
          ? venue.phone
          : evidence.phone.trim(),
      'openingHours': venue.rawData['openingHours'] ?? <String, dynamic>{},
      'featureTags': venue.rawData['featureTags'] ?? <String>[],
      'socialLinks': venue.rawData['socialLinks'] ?? <String, dynamic>{},
      'draftChecklist': <String, dynamic>{},
    };
  }

  FirebaseFirestore _requireFirestore() {
    final firestore = _resolveFirestore();
    if (firestore == null) throw StateError('Firestore is not available.');
    return firestore;
  }

  static String _digits(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  static String _domainFromEmail(String value) {
    final parts = value.trim().toLowerCase().split('@');
    if (parts.length != 2) return '';
    return _normaliseDomain(parts.last);
  }

  static String _domainFromUrl(String value) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty) return '';
    final parsed = Uri.tryParse(
      trimmed.startsWith('http://') || trimmed.startsWith('https://')
          ? trimmed
          : 'https://$trimmed',
    );
    return _normaliseDomain(parsed?.host ?? '');
  }

  static String _normaliseDomain(String value) {
    return value.trim().toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
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
