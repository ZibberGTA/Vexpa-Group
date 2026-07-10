import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/navigation/app_router.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../services/auth_service.dart';
import '../services/user_role_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    this.initialRole = AppUserRole.user,
  });

  final AppUserRole initialRole;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  late AppUserRole selectedRole;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    selectedRole = widget.initialRole;
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage('Please complete all fields.');
      return;
    }

    if (password.length < 6) {
      _showMessage('Password must be at least 6 characters.');
      return;
    }

    setState(() => isLoading = true);

    try {
      await AuthService.register(
        name: name,
        email: email,
        password: password,
        role: UserRoleService.roleToFirestoreValue(selectedRole),
      );

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.authGate,
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? 'Registration failed.');
    } catch (_) {
      _showMessage('Something went wrong. Please try again.');
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
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              AppTextField(
                controller: nameController,
                label: 'Full Name',
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              DropdownButtonFormField<AppUserRole>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Account Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: AppUserRole.user,
                    child: Text('Customer'),
                  ),
                  DropdownMenuItem(
                    value: AppUserRole.owner,
                    child: Text('Venue Owner'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedRole = value;
                  });
                },
              ),
              const SizedBox(height: 10),
              Text(
                selectedRole == AppUserRole.owner
                    ? 'Venue Owner accounts open the business dashboard after login.'
                    : 'Customer accounts open the DrinkSpot discovery app.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _register,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Create Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
