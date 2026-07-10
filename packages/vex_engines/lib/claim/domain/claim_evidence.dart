/// Evidence supplied by a claimant to verify venue ownership.
final class ClaimEvidence {
  const ClaimEvidence({
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

  bool get hasAnyContactEvidence =>
      hasBusinessEmail ||
      hasWebsite ||
      hasPhone ||
      hasCompanyRegistration;

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

  factory ClaimEvidence.fromMap(Map<String, dynamic>? map) {
    final rawUrls = map?['documentUrls'];
    return ClaimEvidence(
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
