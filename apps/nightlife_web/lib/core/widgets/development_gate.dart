import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../features/auth/services/auth_service.dart';
import '../config/development_gate_config.dart';
import '../../shared/layouts/vexda_app_shell.dart';
import 'development_holding_page.dart';

/// Temporary presentation-layer gate for pre-launch Vexda Web deployments.
///
/// Wrap the application router output so every route is protected consistently.
/// Remove this widget (or set [DevelopmentGateConfig.privateDevelopmentMode]
/// to `false`) when Vexda launches publicly.
class DevelopmentGate extends StatefulWidget {
  const DevelopmentGate({
    super.key,
    required this.appChild,
  });

  /// Navigator output from [MaterialApp.builder] — wrapped only when access is granted.
  final Widget appChild;

  @override
  State<DevelopmentGate> createState() => _DevelopmentGateState();
}

class _DevelopmentGateState extends State<DevelopmentGate> {
  static const String accessDeniedMessage =
      'This account does not have preview access.';

  String? _holdingMessage;
  Object? _lastHandledUnapprovedUid;

  @override
  Widget build(BuildContext context) {
    if (!DevelopmentGateConfig.privateDevelopmentMode) {
      return VexdaAppShell(child: widget.appChild);
    }

    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.expand(
            child: DevelopmentHoldingPage.loading(),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          _lastHandledUnapprovedUid = null;
          return SizedBox.expand(
            child: DevelopmentHoldingPage(accessDeniedMessage: _holdingMessage),
          );
        }

        if (!DevelopmentGateConfig.isApprovedEmail(user.email)) {
          if (_lastHandledUnapprovedUid != user.uid) {
            _lastHandledUnapprovedUid = user.uid;
            _holdingMessage = accessDeniedMessage;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              unawaited(_signOutUnapprovedUser());
            });
          }
          return SizedBox.expand(
            child: DevelopmentHoldingPage(accessDeniedMessage: _holdingMessage),
          );
        }

        _lastHandledUnapprovedUid = null;
        _holdingMessage = null;
        return VexdaAppShell(child: widget.appChild);
      },
    );
  }

  Future<void> _signOutUnapprovedUser() async {
    try {
      await AuthService.logout();
    } on Object {
      // Deny access safely even when sign-out fails.
    }
  }
}
