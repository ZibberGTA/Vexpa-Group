/// Self-service signup account types (admin is never offered).
enum SignupAccountType { venueOwner, customer }

extension SignupAccountTypeX on SignupAccountType {
  String get label => switch (this) {
    SignupAccountType.venueOwner => 'Venue Owner',
    SignupAccountType.customer => 'Customer',
  };

  String get description => switch (this) {
    SignupAccountType.venueOwner =>
      'Claim or create a venue and manage it from the Vexda dashboard.',
    SignupAccountType.customer =>
      'Discover venues, drinks, deals and events on Vexda.',
  };

  /// Firestore `role` value — matches the mobile app schema (`owner` / `user`).
  String get firestoreRole => switch (this) {
    SignupAccountType.venueOwner => 'owner',
    SignupAccountType.customer => 'user',
  };

  /// Firestore `accountType` value for CRM and filters.
  String get firestoreAccountType => switch (this) {
    SignupAccountType.venueOwner => 'venue_owner',
    SignupAccountType.customer => 'customer',
  };
}
