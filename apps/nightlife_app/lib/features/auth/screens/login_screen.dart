import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../shared/widgets/app_text_field.dart';
import '../../../core/navigation/app_router.dart';
import '../services/auth_service.dart';
import 'business_login_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter your email and password.');
      return;
    }

    setState(() => isLoading = true);

    try {
      await AuthService.login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.authGate,
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? 'Login failed.');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() => isLoading = true);

    try {
      await AuthService.signInAnonymouslyIfNeeded();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.authGate,
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? 'Could not continue as guest.');
    } catch (_) {
      _showMessage('Could not continue as guest. Please try again.');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _goBackOrGuest() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    _continueAsGuest();
  }

  Future<void> _socialLogin(Future<void> Function() action) async {
    setState(() => isLoading = true);

    try {
      await action();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.authGate,
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? e.code);
    } catch (_) {
      _showMessage('Social login failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: isLoading ? null : _goBackOrGuest,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Back'),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Login to your DrinkSpot account',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              AppTextField(
                controller: emailController,
                label: 'Email',
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: passwordController,
                label: 'Password',
                obscureText: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _login,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Login'),
                ),
              ),

              const SizedBox(height: 12),
              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or continue with'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: isLoading
                    ? null
                    : () => _socialLogin(AuthService.signInWithGoogle),
                icon: const Icon(Icons.g_mobiledata_rounded),
                label: const Text('Continue with Google'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: isLoading
                    ? null
                    : () => _socialLogin(AuthService.signInWithMicrosoft),
                icon: const Icon(Icons.window_rounded),
                label: const Text('Continue with Microsoft'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RegisterScreen(),
                    ),
                  );
                },
                child: const Text("Don't have an account? Register"),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BusinessLoginScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.storefront_rounded),
                label: const Text('Business / Venue Owner Login'),
              ),
              const SizedBox(height: 20),
              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : _continueAsGuest,
                  icon: const Icon(Icons.explore_rounded),
                  label: const Text('Continue as Guest'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}