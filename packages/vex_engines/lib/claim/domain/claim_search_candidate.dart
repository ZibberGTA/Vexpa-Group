/// Search candidate contract for claim venue lookup matching.
abstract interface class ClaimSearchCandidate {
  String get venueId;
  String get name;
  String get address;
  String get city;
  String get postcode;
  String get category;
  String get website;
  String get phone;
  Map<String, dynamic> get rawData;
}
