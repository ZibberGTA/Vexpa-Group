import 'package:firebase_auth/firebase_auth.dart';

import '../../auth/services/auth_service.dart';
import '../models/venue_dashboard_context.dart';

/// Resolves the welcome greeting first name for the venue dashboard.
class VenueDashboardWelcomeName {
  VenueDashboardWelcomeName._();

  static String? firstName({
    User? user,
    VenueDashboardContext? contextData,
  }) {
    final fromAuth = AuthService.getFirstName(user);
    if (fromAuth != null && fromAuth.isNotEmpty) {
      return fromAuth;
    }

    final contextFirst = contextData?.ownerFirstName?.trim();
    if (contextFirst != null && contextFirst.isNotEmpty) {
      return contextFirst;
    }

    final ownerName = contextData?.ownerName.trim();
    if (ownerName != null && ownerName.isNotEmpty && ownerName != 'Account' && ownerName != 'User') {
      final parts = ownerName.split(RegExp(r'\s+'));
      if (parts.isNotEmpty && parts.first.isNotEmpty) {
        return parts.first;
      }
    }

    return null;
  }

  static String welcomeTitle({
    User? user,
    VenueDashboardContext? contextData,
  }) {
    final first = firstName(user: user, contextData: contextData);
    if (first != null) {
      return 'Welcome back, $first';
    }
    return 'Welcome back, User';
  }
}
