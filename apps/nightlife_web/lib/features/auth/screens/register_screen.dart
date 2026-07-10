import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/components/drinkspot_button.dart';
import '../../../shared/layouts/public_page_shell.dart';
import '../../../shared/widgets/glass_container.dart';
import '../models/signup_account_type.dart';
import '../services/auth_service.dart';
import '../services/user_role_service.dart';

/// Venue owner / customer self-service registration.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    this.initialAccountType = SignupAccountType.venueOwner,
  });

  final SignupAccountType initialAccountType;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late SignupAccountType _accountType = widget.initialAccountType;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await AuthService.register(
        displayName: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        accountType: _accountType,
      );

      final navigation = await UserRoleService.resolvePostLoginNavigation(user);
      if (!mounted) return;

      setState(() => _isLoading = false);
      Navigator.pushNamedAndRemoveUntil(
        context,
        navigation.route,
        (_) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AuthService.messageForAuthException(error);
        _isLoading = false;
      });
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Account created but profile setup failed (${error.code}). Please contact support.';
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Registration failed. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PublicPageShell(
      navActiveRoute: AppRouter.register,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            child: GlassContainer(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppStrings.registerTitle,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      AppStrings.registerSubtitle,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14.5,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Full name'),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Enter your full name.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'you@example.com',
                      ),
                      validator: (value) {
                        final email = (value ?? '').trim();
                        if (email.isEmpty) return 'Enter your email address.';
                        if (!email.contains('@')) {
                          return 'Enter a valid email address.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if ((value ?? '').length < 6) {
                          return 'Password must be at least 6 characters.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Confirm password',
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Passwords do not match.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    DropdownButtonFormField<SignupAccountType>(
                      value: _accountType,
                      decoration: const InputDecoration(
                        labelText: 'Account type',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: SignupAccountType.venueOwner,
                          child: Text('Venue Owner'),
                        ),
                        DropdownMenuItem(
                          value: SignupAccountType.customer,
                          child: Text('Customer'),
                        ),
                      ],
                      onChanged: _isLoading
                          ? null
                          : (value) {
                              if (value == null) return;
                              setState(() => _accountType = value);
                            },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _accountType.description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPink.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          border: Border.all(
                            color: AppColors.primaryPink.withValues(
                              alpha: 0.35,
                            ),
                          ),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 13.5,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    DrinkSpotButton(
                      label: _isLoading
                          ? 'Creating account…'
                          : 'Create Account',
                      icon: _isLoading ? null : Icons.person_add_alt_1_rounded,
                      onPressed: _isLoading ? null : _submit,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DrinkSpotButton(
                      label: 'Already have an account? Sign in',
                      variant: DrinkSpotButtonVariant.ghost,
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pushReplacementNamed(
                              context,
                              AppRouter.login,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
