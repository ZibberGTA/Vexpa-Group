import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/navigation/app_router.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../services/auth_service.dart';
import '../services/user_role_service.dart';
import 'register_screen.dart';

class BusinessLoginScreen extends StatefulWidget {
  const BusinessLoginScreen({super.key});

  @override
  State<BusinessLoginScreen> createState() => _BusinessLoginScreenState();
}

class _BusinessLoginScreenState extends State<BusinessLoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginBusiness() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter your business email and password.');
      return;
    }

    setState(() => isLoading = true);

    try {
      await AuthService.login(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? 'Business login failed.');
      return;
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }

    final user = AuthService.currentUser;
    if (user == null) {
      _showMessage('Signed in, but the session could not be confirmed. Please try again.');
      return;
    }

    final role = await UserRoleService.resolveRoleForUserSafely(user);

    if (!role.isBusiness) {
      await AuthService.logout();
      _showMessage(
        'This account does not have access to the venue/admin dashboard.',
      );
      return;
    }

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.authGate,
      (route) => false,
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Login')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              const SizedBox(height: 24),
              const Icon(
                Icons.storefront_rounded,
                size: 76,
                color: Color(0xFF7C3AED),
              ),
              const SizedBox(height: 20),
              const Text(
                'Manage your venue',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Log in as a venue owner to add drinks, deals, events and view your dashboard.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 32),
              AppTextField(
                controller: emailController,
                label: 'Business email',
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
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : _loginBusiness,
                  icon: const Icon(Icons.login_rounded),
                  label: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Login to Business Dashboard'),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(
                              initialRole: AppUserRole.owner,
                            ),
                          ),
                        );
                      },
                child: const Text('Create a Venue Owner Account'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: isLoading
                    ? null
                    : () {
                        Navigator.pushReplacementNamed(context, AppRoutes.login);
                      },
                child: const Text('Customer login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
