import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vex_engines/claim/domain/claim_confidence_score.dart';
import 'package:vex_engines/claim/domain/claim_evidence.dart';
import 'package:vex_engines/claim/domain/claim_list_entry.dart';
import 'package:vex_engines/claim/domain/claim_search_candidate.dart';
import 'package:vex_engines/claim/domain/claim_status.dart';
import 'package:vex_engines/claim/shared/claim_presentation_support.dart';
import 'package:vex_engines/claim/shared/claim_record_support.dart';

export 'package:vex_engines/claim/domain/claim_confidence_score.dart';
export 'package:vex_engines/claim/domain/claim_evidence.dart';
export 'package:vex_engines/claim/domain/claim_status.dart';

typedef VenueClaimStatus = ClaimStatus;
typedef VenueClaimEvidence = ClaimEvidence;
typedef VenueClaimScoreSignal = ClaimConfidenceSignal;
typedef VenueClaimScore = ClaimConfidenceScore;

extension VenueClaimStatusX on ClaimStatus {
  static ClaimStatus fromFirestore(Object? value) =>
      ClaimStatusCodec.fromFirestore(value);
}

class VenueClaimAuditEvent {
  const VenueClaimAuditEvent({
    required this.id,
    required this.type,
    required this.actorUid,
    required this.actorRole,
    required this.message,
    required this.metadata,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String actorUid;
  final String actorRole;
  final String message;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;

  factory VenueClaimAuditEvent.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return VenueClaimAuditEvent(
      id: id,
      type: (data['type'] ?? '').toString(),
      actorUid: (data['actorUid'] ?? '').toString(),
      actorRole: (data['actorRole'] ?? '').toString(),
      message: (data['message'] ?? '').toString(),
      metadata: data['metadata'] is Map
          ? Map<String, dynamic>.from(data['metadata'] as Map)
          : const {},
      createdAt: VenueClaim._readDate(data['createdAt']),
    );
  }
}

class VenueClaimSearchResult implements ClaimSearchCandidate {
  const VenueClaimSearchResult({
    required this.venueId,
    required this.name,
    required this.address,
    required this.city,
    required this.postcode,
    required this.category,
    this.logoUrl = '',
    this.bannerUrl = '',
    this.website = '',
    this.phone = '',
    this.rawData = const {},
  });

  @override
  final String venueId;
  @override
  final String name;
  @override
  final String address;
  @override
  final String city;
  @override
  final String postcode;
  @override
  final String category;
  final String logoUrl;
  final String bannerUrl;
  @override
  final String website;
  @override
  final String phone;
  @override
  final Map<String, dynamic> rawData;

  String get displayAddress => ClaimPresentationSupport.formatDisplayAddress(
    address: address,
    city: city,
    postcode: postcode,
  );

  /// Human-readable claim status for search cards.
  String get claimStatusLabel =>
      ClaimPresentationSupport.directoryClaimStatusLabel(rawData);

  factory VenueClaimSearchResult.fromFirestore(
    String venueId,
    Map<String, dynamic> data,
  ) {
    final address = _readAddress(data);
    return VenueClaimSearchResult(
      venueId: venueId,
      name: (data['name'] ?? data['venueName'] ?? 'Unnamed venue').toString(),
      address: address.line,
      city: address.city,
      postcode: address.postcode,
      category: (data['category'] ?? data['venueType'] ?? 'Venue').toString(),
      logoUrl: (data['logoUrl'] ?? data['logoImageUrl'] ?? '').toString(),
      bannerUrl:
          (data['bannerImageUrl'] ??
                  data['bannerUrl'] ??
                  data['imageUrl'] ??
                  '')
              .toString(),
      website: (data['website'] ?? data['websiteUrl'] ?? '').toString(),
      phone: (data['phone'] ?? '').toString(),
      rawData: data,
    );
  }

  static ({String line, String city, String postcode}) _readAddress(
    Map<String, dynamic> data,
  ) {
    final raw = data['address'];
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      return (
        line: (map['line1'] ?? map['line'] ?? map['street'] ?? '').toString(),
        city: (map['city'] ?? data['city'] ?? data['town'] ?? '').toString(),
        postcode: (map['postcode'] ?? data['postcode'] ?? '').toString(),
      );
    }
    return (
      line: (raw ?? '').toString(),
      city: (data['city'] ?? data['town'] ?? '').toString(),
      postcode: (data['postcode'] ?? data['postalCode'] ?? '').toString(),
    );
  }
}

class VenueClaim {
  const VenueClaim({
    required this.id,
    required this.venueId,
    required this.claimantUid,
    required this.status,
    required this.confidenceScore,
    required this.submittedEvidence,
    required this.draftVenueData,
    required this.autoApproved,
    required this.submittedAt,
    required this.createdAt,
    required this.updatedAt,
    this.venueName = '',
    this.venueAddress = '',
    this.claimantEmail = '',
    this.reviewedAt,
    this.reviewedBy,
    this.reviewNotes = '',
    this.confidenceReasons = const [],
    this.scoreSignals = const [],
  });

  final String id;
  final String venueId;
  final String venueName;
  final String venueAddress;
  final String claimantUid;
  final String claimantEmail;
  final ClaimStatus status;
  final int confidenceScore;
  final ClaimEvidence submittedEvidence;
  final Map<String, dynamic> draftVenueData;
  final bool autoApproved;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String reviewNotes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> confidenceReasons;
  final List<ClaimConfidenceSignal> scoreSignals;

  bool get isPending => status.isPending;
  bool get isApproved => status.isApproved;

  ClaimListEntry toClaimListEntry() {
    return ClaimListEntry(
      id: id,
      venueId: venueId,
      venueName: venueName,
      claimantUid: claimantUid,
      claimantEmail: claimantEmail,
      status: status,
      autoApproved: autoApproved,
      confidenceScore: confidenceScore,
      evidence: submittedEvidence,
      submittedAt: submittedAt,
      reviewNotes: reviewNotes,
    );
  }

  factory VenueClaim.fromFirestore(String id, Map<String, dynamic> data) {
    if (ClaimRecordSupport.isMalformedClaimRecord(data)) {
      return VenueClaim(
        id: id,
        venueId: (data['venueId'] ?? '').toString(),
        claimantUid: (data['claimantUid'] ?? '').toString(),
        status: ClaimRecordSupport.parseStatusSafely(data['status']),
        confidenceScore: 0,
        submittedEvidence: const ClaimEvidence(),
        draftVenueData: const {},
        autoApproved: false,
        submittedAt: null,
        createdAt: null,
        updatedAt: null,
      );
    }

    final score = data['confidenceScore'];
    final rawSignals = data['confidenceSignals'];
    return VenueClaim(
      id: id,
      venueId: (data['venueId'] ?? '').toString(),
      venueName: (data['venueName'] ?? '').toString(),
      venueAddress: (data['venueAddress'] ?? '').toString(),
      claimantUid: (data['claimantUid'] ?? '').toString(),
      claimantEmail: (data['claimantEmail'] ?? '').toString(),
      status: ClaimStatusCodec.fromFirestore(data['status']),
      confidenceScore: score is num ? score.round() : 0,
      submittedEvidence: ClaimEvidence.fromMap(
        data['submittedEvidence'] is Map
            ? Map<String, dynamic>.from(data['submittedEvidence'] as Map)
            : null,
      ),
      draftVenueData: data['draftVenueData'] is Map
          ? Map<String, dynamic>.from(data['draftVenueData'] as Map)
          : const {},
      autoApproved: data['autoApproved'] == true,
      submittedAt: _readDate(data['submittedAt']),
      reviewedAt: _readDate(data['reviewedAt']),
      reviewedBy: data['reviewedBy']?.toString(),
      reviewNotes: (data['reviewNotes'] ?? '').toString(),
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
      confidenceReasons: data['confidenceReasons'] is Iterable
          ? (data['confidenceReasons'] as Iterable)
                .map((reason) => reason.toString())
                .toList(growable: false)
          : const [],
      scoreSignals: rawSignals is Iterable
          ? rawSignals
                .whereType<Map>()
                .map(
                  (item) => ClaimConfidenceSignal.fromMap(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(growable: false)
          : const [],
    );
  }

  static DateTime? _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
