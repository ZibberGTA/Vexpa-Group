import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../admin/screens/admin_dashboard_screen.dart';
import '../../navigation/main_navigation_screen.dart';
import '../services/auth_service.dart';
import '../services/user_role_service.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _AuthLoadingScreen(message: 'Checking your account...');
        }

        if (!authSnapshot.hasData) {
          return FutureBuilder<void>(
            future: AuthService.signInAnonymouslyIfNeeded(),
            builder: (context, guestSnapshot) {
              if (guestSnapshot.connectionState != ConnectionState.done) {
                return const _AuthLoadingScreen(
                  message: 'Preparing DrinkSpot...',
                );
              }

              if (guestSnapshot.hasError) {
                return _GuestModeErrorScreen(
                  error: guestSnapshot.error.toString(),
                );
              }

              return const MainNavigationScreen();
            },
          );
        }

        return StreamBuilder<AppUserRole>(
          stream: UserRoleService.currentUserRoleStream(),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const _AuthLoadingScreen(
                message: 'Loading your dashboard...',
              );
            }

            final role = roleSnapshot.data ?? AppUserRole.user;

            if (role.isStaff) {
              return const AdminDashboardScreen();
            }

            return const MainNavigationScreen();
          },
        );
      },
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestModeErrorScreen extends StatelessWidget {
  const _GuestModeErrorScreen({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              const Text(
                'DrinkSpot could not start guest mode.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                ),
                child: const Text('Sign in instead'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
