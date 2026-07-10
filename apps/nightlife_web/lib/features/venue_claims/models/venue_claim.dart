import 'package:cloud_firestore/cloud_firestore.dart';

enum VenueClaimStatus {
  draft,
  pendingReview,
  needsMoreInfo,
  autoApproved,
  approved,
  rejected,
  completed,
  error,
}

extension VenueClaimStatusX on VenueClaimStatus {
  String get firestoreValue {
    return switch (this) {
      VenueClaimStatus.draft => 'draft',
      VenueClaimStatus.pendingReview => 'pending_review',
      VenueClaimStatus.needsMoreInfo => 'needs_more_info',
      VenueClaimStatus.autoApproved => 'auto_approved',
      VenueClaimStatus.approved => 'approved',
      VenueClaimStatus.rejected => 'rejected',
      VenueClaimStatus.completed => 'completed',
      VenueClaimStatus.error => 'error',
    };
  }

  String get label {
    return switch (this) {
      VenueClaimStatus.draft => 'Draft',
      VenueClaimStatus.pendingReview => 'Pending Review',
      VenueClaimStatus.needsMoreInfo => 'Needs More Info',
      VenueClaimStatus.autoApproved => 'Auto Approved',
      VenueClaimStatus.approved => 'Approved',
      VenueClaimStatus.rejected => 'Rejected',
      VenueClaimStatus.completed => 'Completed',
      VenueClaimStatus.error => 'Error',
    };
  }

  static VenueClaimStatus fromFirestore(Object? value) {
    final raw = value?.toString().trim().toLowerCase();
    return switch (raw) {
      'draft' => VenueClaimStatus.draft,
      'needs_more_info' ||
      'more_info_requested' => VenueClaimStatus.needsMoreInfo,
      'auto_approved' => VenueClaimStatus.autoApproved,
      'approved' => VenueClaimStatus.approved,
      'rejected' => VenueClaimStatus.rejected,
      'completed' => VenueClaimStatus.completed,
      'error' => VenueClaimStatus.error,
      _ => VenueClaimStatus.pendingReview,
    };
  }
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

class VenueClaimEvidence {
  const VenueClaimEvidence({
    this.businessEmail = '',
    this.website = '',
    this.phone = '',
    this.companyRegistration = '',
    this.notes = '',
    this.documentUrls = const [],
  });

  final String businessEmail;
  final String website;
  final String phone;
  final String companyRegistration;
  final String notes;
  final List<String> documentUrls;

  bool get hasBusinessEmail => businessEmail.trim().isNotEmpty;
  bool get hasWebsite => website.trim().isNotEmpty;
  bool get hasPhone => phone.trim().isNotEmpty;
  bool get hasCompanyRegistration => companyRegistration.trim().isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'businessEmail': businessEmail.trim(),
      'website': website.trim(),
      'phone': phone.trim(),
      'companyRegistration': companyRegistration.trim(),
      'notes': notes.trim(),
      'documentUrls': documentUrls,
    };
  }

  factory VenueClaimEvidence.fromMap(Map<String, dynamic>? map) {
    final rawUrls = map?['documentUrls'];
    return VenueClaimEvidence(
      businessEmail: (map?['businessEmail'] ?? '').toString(),
      website: (map?['website'] ?? '').toString(),
      phone: (map?['phone'] ?? '').toString(),
      companyRegistration: (map?['companyRegistration'] ?? '').toString(),
      notes: (map?['notes'] ?? '').toString(),
      documentUrls: rawUrls is Iterable
          ? rawUrls.map((url) => url.toString()).toList(growable: false)
          : const [],
    );
  }
}

class VenueClaimScoreSignal {
  const VenueClaimScoreSignal({
    required this.key,
    required this.label,
    required this.points,
    required this.matched,
  });

  final String key;
  final String label;
  final int points;
  final bool matched;

  Map<String, dynamic> toMap() {
    return {'key': key, 'label': label, 'points': points, 'matched': matched};
  }

  factory VenueClaimScoreSignal.fromMap(Map<String, dynamic> map) {
    return VenueClaimScoreSignal(
      key: (map['key'] ?? '').toString(),
      label: (map['label'] ?? '').toString(),
      points: map['points'] is num ? (map['points'] as num).round() : 0,
      matched: map['matched'] == true,
    );
  }
}

class VenueClaimScore {
  const VenueClaimScore({
    required this.score,
    required this.threshold,
    required this.signals,
  });

  final int score;
  final int threshold;
  final List<VenueClaimScoreSignal> signals;

  bool get autoApproved => score >= threshold;

  Map<String, dynamic> toMap() {
    return {
      'score': score,
      'threshold': threshold,
      'autoApproved': autoApproved,
      'signals': signals.map((signal) => signal.toMap()).toList(),
    };
  }
}

class VenueClaimSearchResult {
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

  final String venueId;
  final String name;
  final String address;
  final String city;
  final String postcode;
  final String category;
  final String logoUrl;
  final String bannerUrl;
  final String website;
  final String phone;
  final Map<String, dynamic> rawData;

  String get displayAddress {
    final parts = [
      address,
      city,
      postcode,
    ].map((part) => part.trim()).where((part) => part.isNotEmpty).toList();
    return parts.isEmpty ? 'Address not listed' : parts.join(', ');
  }

  /// Human-readable claim status for search cards.
  String get claimStatusLabel {
    final status = (rawData['claimStatus'] ?? rawData['claimedStatus'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    if (status.isEmpty || status == 'unclaimed' || status == 'available') {
      return 'Unclaimed';
    }
    if (status == 'pending' || status == 'pending_review') {
      return 'Pending review';
    }
    return status[0].toUpperCase() + status.substring(1);
  }

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
  final VenueClaimStatus status;
  final int confidenceScore;
  final VenueClaimEvidence submittedEvidence;
  final Map<String, dynamic> draftVenueData;
  final bool autoApproved;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String reviewNotes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> confidenceReasons;
  final List<VenueClaimScoreSignal> scoreSignals;

  bool get isPending => status == VenueClaimStatus.pendingReview;
  bool get isApproved =>
      status == VenueClaimStatus.approved ||
      status == VenueClaimStatus.autoApproved ||
      status == VenueClaimStatus.completed;

  factory VenueClaim.fromFirestore(String id, Map<String, dynamic> data) {
    final score = data['confidenceScore'];
    final rawSignals = data['confidenceSignals'];
    return VenueClaim(
      id: id,
      venueId: (data['venueId'] ?? '').toString(),
      venueName: (data['venueName'] ?? '').toString(),
      venueAddress: (data['venueAddress'] ?? '').toString(),
      claimantUid: (data['claimantUid'] ?? '').toString(),
      claimantEmail: (data['claimantEmail'] ?? '').toString(),
      status: VenueClaimStatusX.fromFirestore(data['status']),
      confidenceScore: score is num ? score.round() : 0,
      submittedEvidence: VenueClaimEvidence.fromMap(
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
                  (item) => VenueClaimScoreSignal.fromMap(
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
